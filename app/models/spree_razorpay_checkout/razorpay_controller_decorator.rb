module SpreeRazorpayCheckout
  module RazorpayControllerDecorator
    def razor_response
      Spree::Current.store ||= Spree::Store.default
      super
    end
  end
end

::Spree::RazorpayController.prepend(
  SpreeRazorpayCheckout::RazorpayControllerDecorator
) if defined?(::Spree::RazorpayController)