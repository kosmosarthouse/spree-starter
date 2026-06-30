require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Storage
  if ENV["AWS_ACCESS_KEY_ID"].present? && ENV["AWS_SECRET_ACCESS_KEY"].present?
    config.active_storage.service = :amazon
  elsif ENV["CLOUDFLARE_ACCESS_KEY_ID"].present? && ENV["CLOUDFLARE_SECRET_ACCESS_KEY"].present? && ENV["CLOUDFLARE_ENDPOINT"].present?
    config.active_storage.service = :cloudflare
  else
    config.active_storage.service = :local
  end

  # ✅ Fix 404 on report download links in emails
  config.active_storage.default_url_options = {
    host:     "spree.nozfragrances.com",
    protocol: "https"
  }

  config.assume_ssl = ENV["RAILS_ASSUME_SSL"] != "false"
  config.force_ssl  = ENV["RAILS_FORCE_SSL"] != "false"

  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  config.lograge.enabled = true
  config.lograge.formatter = ->(data) {
    duration = data[:duration].to_i
    "#{data[:method]} #{data[:path]} #{data[:status]} #{duration}ms"
  }

  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false

  redis_cache_url = ENV["REDIS_CACHE_URL"] || ENV["REDIS_URL"]
  if redis_cache_url.present?
    config.cache_store = :redis_cache_store, { url: redis_cache_url }
  else
    config.cache_store = :memory_store
  end

  # --- Mailer / SMTP (Mailtrap) ---
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              "live.smtp.mailtrap.io",
    port:                 587,
    domain:               "nozfragrances.com",
    user_name:            "api",
    password:             ENV["MAILTRAP_API_TOKEN"],
    authentication:       :plain,
    enable_starttls_auto: true
  }
  config.action_mailer.default_url_options = {
    host:     "spree.nozfragrances.com",
    protocol: "https"
  }
  config.action_mailer.asset_host = "https://spree.nozfragrances.com"

  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]
end

# Global default URL options (critical for Spree Admin)
Rails.application.routes.default_url_options = {
  host:     "spree.nozfragrances.com",
  protocol: "https"
}
