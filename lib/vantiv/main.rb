require 'rubygems'
require 'bundler'
Bundler.setup # this will pull in gem dependencies

require 'require_relative' if RUBY_VERSION < "1.9"
require_relative 'application_and_merchant_setup.rb'
require_relative 'txn_processing.rb'
#require_relative 'txn_management.rb'
