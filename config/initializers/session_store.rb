# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_IngenicoPaymentPortal_session',
  :secret      => '8d085ed7f8ffe313f5bfe03860e7d557db5c10641f066d4cd4e8ed4906d72398f3a95bae9dd21c1540e9264b7de31881083386a09c7bb8c3ea2e952498777fac'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
