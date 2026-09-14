# Receives inbound webhooks from Velocity Shipping (dashboard.velocity.in).
#
# This is the *reverse* direction of the existing Spree → Next.js webhook
# (see spree_razorpay_checkout for the same "external service calls us"
# pattern already used in this app). Velocity calls THIS endpoint whenever
# something changes on a shipment we handed to them via the bulk CSV upload
# — most importantly the "Tracking Addition" event, which is the ONLY way
# we learn the AWB number Velocity assigned to one of our orders (their API
# has no "look up AWB by order_id" endpoint).
#
# Setup in Velocity's dashboard (Settings → Webhooks):
#   Endpoint:              https://<your-domain>/velocity/webhooks
#   Authentication Method: API Key
#   Event Subscription:    Tracking Addition (required)
#                          Status Change (optional — logged but not acted on yet)
#
# Setup on our side (Coolify → environment variables):
#   VELOCITY_WEBHOOK_API_KEY=<same value entered in Velocity's dashboard>
#
# IMPORTANT — payload shape is unconfirmed:
# Velocity's API docs (Velocity_Shipping_Custom_API_Documentation) cover
# their REST endpoints in detail but do NOT document the webhook payload
# shape for "Tracking Addition" / "Status Change". The field names below
# (order_id / awb / awb_code / tracking_url) are best-effort guesses based
# on the naming used elsewhere in their API (e.g. forward-order-orchestration
# returns "awb_code"). The FIRST real webhook delivery should be checked in
# the Rails logs (we log the raw payload below) or Sidekiq's job args, and
# `Velocity::TrackingAdditionJob` adjusted if the actual field names differ.
# This is a one-time, low-risk fix — nothing else depends on getting the
# names exactly right on day one.
module Velocity
  class WebhooksController < ActionController::Base
    # This is a server-to-server webhook, not a browser request — there is
    # no session/cookie to protect, and enforcing CSRF here would just
    # reject every legitimate delivery from Velocity.
    skip_before_action :verify_authenticity_token, raise: false

    before_action :authenticate_webhook!

    def create
      payload = JSON.parse(request.raw_post)
      event_name = request.headers['X-Velocity-Event'] || params[:event] || payload['event']

      Rails.logger.info("[velocity-webhook] Received event=#{event_name.inspect} payload=#{payload.inspect}")

      case event_name.to_s
      when 'tracking_addition', 'tracking.addition', 'TRACKING_ADDITION'
        Velocity::TrackingAdditionJob.perform_later(payload)
      when 'status_change', 'status.change', 'STATUS_CHANGE'
        Velocity::StatusChangeJob.perform_later(payload)
      else
        Rails.logger.info("[velocity-webhook] Ignoring unhandled event: #{event_name.inspect}")
      end

      # Respond quickly with 200 OK — Velocity's docs say a non-200 triggers
      # up to 3 retries within a 10s timeout, so we do the real work in a
      # background job and never make Velocity wait on it.
      render json: { received: true }, status: :ok
    rescue JSON::ParserError
      render json: { error: 'invalid_json' }, status: :bad_request
    end

    private

    # "API Key" is the only real authentication option Velocity's webhook
    # settings screen offers (the other is "None", which must never be used
    # on a live endpoint). Velocity's docs don't specify which header they
    # send the key in, so we accept the common conventions and just require
    # the value to match — adjust the header name here if Velocity's actual
    # delivery uses something different (visible in the raw request once
    # the first real webhook arrives).
    def authenticate_webhook!
      expected_key = ENV['VELOCITY_WEBHOOK_API_KEY']

      if expected_key.blank?
        Rails.logger.error('[velocity-webhook] VELOCITY_WEBHOOK_API_KEY is not set — rejecting all webhook deliveries')
        return render json: { error: 'webhook_not_configured' }, status: :service_unavailable
      end

      provided_key =
        request.headers['X-API-Key'] ||
        request.headers['Authorization']&.sub(/\ABearer\s+/i, '') ||
        params[:api_key]

      unless provided_key.present? && ActiveSupport::SecurityUtils.secure_compare(provided_key.to_s, expected_key)
        Rails.logger.warn('[velocity-webhook] Rejected webhook with missing/invalid API key')
        render json: { error: 'unauthorized' }, status: :unauthorized
      end
    end
  end
end
