# Handles Velocity's "Status Change" webhook event (in transit, out for
# delivery, delivered, RTO, etc).
#
# We deliberately do NOT try to map these granular statuses onto Spree's own
# shipment state machine (pending/ready/shipped/etc.) — the two don't line
# up cleanly, and Spree's states already drive other logic (emails,
# inventory) that we don't want to disturb. For now this just logs the
# event; the "Track my order" page gets live status by calling Velocity's
# own order-tracking API directly with the AWB, so nothing here blocks that
# feature from working.
#
# If/when granular status needs to be visible inside Spree admin too, the
# simplest safe addition is a Spree::Shipment metadata/note field rather
# than touching `state` — revisit then.
module Velocity
  class StatusChangeJob < ApplicationJob
    queue_as :default

    def perform(payload)
      Rails.logger.info("[velocity-webhook] status_change event received: #{payload.inspect}")
    end
  end
end
