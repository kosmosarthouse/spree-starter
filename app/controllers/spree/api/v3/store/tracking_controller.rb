module Spree
  module Api
    module V3
      module Store
        # Public, read-only endpoint the Next.js "Track my order" page calls
        # with an order number to find out whether it's shipped and, if so,
        # what AWB to ask Velocity Shipping's live tracking API about.
        #
        # Deliberately no extra verification (email/phone match) beyond the
        # order number itself — same decision already made for this feature:
        # if someone has the order number or AWB (both sent by email), they
        # can look up status. This mirrors PostsController's "public by
        # design" pattern in this same namespace.
        class TrackingController < Spree::Api::V3::Store::BaseController
          def show
            order = Spree::Order.complete
                                 .where(store: current_store)
                                 .find_by(number: params[:id])

            return render json: { error: { code: 'not_found', message: 'Order not found' } }, status: :not_found if order.nil?

            shipment = order.shipments.order(:created_at).first

            render json: {
              data: {
                order_number: order.number,
                order_state: order.state,
                shipped: shipment&.shipped? || false,
                awb_code: shipment&.tracking,
                tracking_url: shipment&.tracking_url,
                shipped_at: shipment&.shipped_at
              }
            }
          end
        end
      end
    end
  end
end
