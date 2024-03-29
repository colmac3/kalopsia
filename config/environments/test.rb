# Settings specified here will take precedence over those in config/environment.rb

# The test_rename environment is used exclusively to run your application's
# test_rename suite.  You never need to work with it otherwise.  Remember that
# your test_rename database is "scratch space" for the test_rename suite and is wiped
# and recreated between test_rename runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false
config.action_view.cache_template_loading            = true

# Disable request forgery protection in test_rename environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test_rename delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# Use SQL instead of Active Record's schema dumper when creating the test_rename database.
# This is necessary if your schema can't be completely dumped by the schema dumper,
# like if you have constraints or database-specific column types
# config.active_record.schema_format = :sql

#config.gem 'rspec-rails', :version => '~> 1.3.2', :lib => false unless File.directory?(File.join(Rails.root, 'vendor/plugins/rspec-rails'))
