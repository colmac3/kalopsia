# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true

# See everything in the log (default is :info)
config.log_level = :debug

$sage_host =   "www.sagepayments.net"
$sage_sale_endpoint = "/cgi-bin/eftBankcard.dll?retail_transaction"
$use_ssl = true



# FOR PRE-PROD TESTING
$use_stub_ssl = false
$sage_stub_host = "test.sage-stub.berylapp.com"
$sage_stub_sale_endpoint = "/transaction/sale"


require 'syslog_logger'
config.logger = SyslogLogger.new('kalopsia')

