# Handles Velocity's "Tracking Addition" webhook event — the moment an AWB
# gets assigned to one of our orders on Velocity's side. Writes the AWB onto
# the matching Spree::Shipment's built-in `tracking` field, which the
# Next.js storefront (and Spree's own order-confirmation emails) already
# know how to display — no frontend changes needed once this runs.
#
# NOTE ON FIELD NAMES: see the comment at the top of
# Velocity::WebhooksController — these key names are a best guess pending
# the first real webhook delivery. If Velocity's actual payload uses
# different keys, update PAYLOAD_ORDER_ID_KEYS / PAYLOAD_AWB_KEYS /
# PAYLOAD_TRACKING_URL_KEYS below; nothing else needs to change.
module Velocity
  class TrackingAdditionJob < ApplicationJob
    queue_as :default

    PAYLOAD_ORDER_ID_KEYS = %w[order_id orderId order_number].freeze
    PAYLOAD_AWB_KEYS = %w[awb_code awb awb_number awbCode].freeze
    PAYLOAD_TRACKING_URL_KEYS = %w[tracking_url trackingUrl track_url].freeze
    PAYLOAD_COURIER_NAME_KEYS = %w[courier_name courierName carrier_name].freeze

    def perform(payload)
      payload = payload.deep_stringify_keys
      order_number = extract(payload, PAYLOAD_ORDER_ID_KEYS)
      awb_code = extract(payload, PAYLOAD_AWB_KEYS)

      if order_number.blank? || awb_code.blank?
        Rails.logger.error(
          "[velocity-webhook] tracking_addition payload missing order id or awb — " \
          "payload=#{payload.inspect}. Check PAYLOAD_ORDER_ID_KEYS/PAYLOAD_AWB_KEYS " \
          "in Velocity::TrackingAdditionJob against the real field names."
        )
        return
      end

      order = Spree::Order.complete.find_by(number: order_number)
      if order.nil?
        Rails.logger.error("[velocity-webhook] No completed Spree order found with number=#{order_number.inspect}")
        return
      end

      shipment = order.shipments.order(:created_at).first
      if shipment.nil?
        Rails.logger.error("[velocity-webhook] Order #{order_number} has no shipments to attach tracking to")
        return
      end

      # Idempotent — repeated/duplicate webhook deliveries (Velocity retries
      # up to 3 times on non-200 responses) are safe to re-run.
      if shipment.tracking == awb_code
        Rails.logger.info("[velocity-webhook] Order #{order_number} already has tracking=#{awb_code}, skipping")
        return
      end

      tracking_url = extract(payload, PAYLOAD_TRACKING_URL_KEYS)
      courier_name = extract(payload, PAYLOAD_COURIER_NAME_KEYS)

      update_attrs = { tracking: awb_code }
      # `tracking_url` is a real DB column on some Spree versions and a
      # computed/read-only method on others (derived from the shipping
      # method's carrier integration) — only attempt to write it if it's
      # actually settable, so an unexpected schema never turns a routine
      # AWB update into a hard failure.
      update_attrs[:tracking_url] = tracking_url if tracking_url.present? && shipment.respond_to?(:tracking_url=)

      shipment.update!(update_attrs)

      Rails.logger.info(
        "[velocity-webhook] Order #{order_number}: set tracking=#{awb_code}" \
        "#{courier_name.present? ? " via #{courier_name}" : ''}"
      )
    end

    private

    def extract(payload, keys)
      keys.each do |key|
        value = payload[key]
        return value if value.present?
      end
      nil
    end
  end
end
