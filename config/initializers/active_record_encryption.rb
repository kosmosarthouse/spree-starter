# frozen_string_literal: true

# Active Record Encryption requires three secrets to encrypt/decrypt sensitive
# database columns.
#
# Required env vars:
#   AR_ENCRYPTION_PRIMARY_KEY
#   AR_ENCRYPTION_DETERMINISTIC_KEY
#   AR_ENCRYPTION_KEY_DERIVATION_SALT

primary_key = ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY")
deterministic_key = ENV.fetch("AR_ENCRYPTION_DETERMINISTIC_KEY")
key_derivation_salt = ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT")

Rails.application.configure do
  config.active_record.encryption.primary_key = primary_key
  config.active_record.encryption.deterministic_key = deterministic_key
  config.active_record.encryption.key_derivation_salt = key_derivation_salt
end

ActiveRecord::Encryption.config.primary_key = primary_key
ActiveRecord::Encryption.config.deterministic_key = deterministic_key
ActiveRecord::Encryption.config.key_derivation_salt = key_derivation_salt
