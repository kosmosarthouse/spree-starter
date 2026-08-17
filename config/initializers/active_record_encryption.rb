# frozen_string_literal: true

# Active Record Encryption requires three secrets to encrypt/decrypt sensitive
# database columns. Rails does not read these from plain environment variables
# by default, so we wire them up explicitly here.
#
# Required env vars (set in your deployment platform, e.g. Coolify):
#   AR_ENCRYPTION_PRIMARY_KEY
#   AR_ENCRYPTION_DETERMINISTIC_KEY
#   AR_ENCRYPTION_KEY_DERIVATION_SALT
#
# Generate values with:
#   ruby -rsecurerandom -e 'puts SecureRandom.alphanumeric(32)'
#
# IMPORTANT: once any data has been encrypted with these keys, changing them
# will make that data permanently unreadable. Keep them safe and stable.

Rails.application.configure do
  config.active_record.encryption.primary_key = ENV.fetch('AR_ENCRYPTION_PRIMARY_KEY', nil)
  config.active_record.encryption.deterministic_key = ENV.fetch('AR_ENCRYPTION_DETERMINISTIC_KEY', nil)
  config.active_record.encryption.key_derivation_salt = ENV.fetch('AR_ENCRYPTION_KEY_DERIVATION_SALT', nil)
end
