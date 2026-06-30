# frozen_string_literal: true

Spree.config do |config|
  # config.track_inventory_levels = false
end

Spree.dependencies do |dependencies|
  # dependencies.cart_add_item_service = 'MyNewAwesomeService'
end

Rails.application.config.after_initialize do
  # Fix Spree engine report download URLs
  Spree::Core::Engine.routes.default_url_options = {
    host:     "spree.nozfragrances.com",
    protocol: "https"
  }

  Rails.application.routes.default_url_options = {
    host:     "spree.nozfragrances.com",
    protocol: "https"
  }

  # Role-based permissions
  Spree.permissions.assign(:default, [Spree::PermissionSets::DefaultCustomer])
  Spree.permissions.assign(:admin, [Spree::PermissionSets::SuperUser])
end

Spree.user_class = 'Spree::User'
Spree.admin_user_class = 'Spree::AdminUser'

# Background job queue configuration
Spree.queues.default = :default
Spree.queues.events = :spree_events
Spree.queues.exports = :spree_exports
Spree.queues.images = :spree_images
Spree.queues.imports = :spree_imports
Spree.queues.products = :spree_products
Spree.queues.reports = :spree_reports
Spree.queues.variants = :spree_variants
Spree.queues.taxons = :spree_taxons
Spree.queues.stock_location_stock_items = :spree_stock_location_stock_items
Spree.queues.coupon_codes = :spree_coupon_codes
Spree.queues.addresses = :spree_addresses
Spree.queues.gift_cards = :spree_gift_cards
Spree.queues.webhooks = :spree_webhooks
Spree.queues.payment_webhooks = :spree_payment_webhooks
Spree.queues.api_keys = :spree_api_keys
Spree.queues.search = :spree_search

if ENV['MEILISEARCH_URL'].present?
  Spree.search_provider = 'Spree::SearchProvider::Meilisearch'
end

Rails.application.config.to_prepare do
  require_dependency 'spree/authentication_helpers'
end

Devise.parent_controller = 'Spree::BaseController' if defined?(Devise) && Devise.respond_to?(:parent_controller)
