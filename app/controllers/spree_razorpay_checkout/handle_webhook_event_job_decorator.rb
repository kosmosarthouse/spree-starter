module SpreeRazorpayCheckout
  module HandleWebhookEventJobDecorator
    def perform(event)
      payload = event['payload']
      payment_entity = payload.dig('payment', 'entity') || payload.dig('order', 'entity')
      razorpay_order_id = payment_entity['order_id'] || payload.dig('order', 'entity', 'id')

      checkout_record = Spree::RazorpayCheckout.find_by(razorpay_order_id: razorpay_order_id)
      if checkout_record
        ::Spree::Current.store = checkout_record.order.store
      end

      super
    end
  end
end

::SpreeRazorpayCheckout::HandleWebhookEventJob.prepend(
  SpreeRazorpayCheckout::HandleWebhookEventJobDecorator
) if defined?(::SpreeRazorpayCheckout::HandleWebhookEventJob)