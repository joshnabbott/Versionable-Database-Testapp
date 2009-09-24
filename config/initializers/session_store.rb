# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_versionable_session',
  :secret      => '385c089b0d3d3e057e803da916bb1fdc29d6e93b674875bbd3093012a25eefa764dc948f79a246cfc62f05b38d957465e538671fc679a9890272a7563c66084b'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
