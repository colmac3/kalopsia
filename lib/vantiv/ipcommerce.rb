
#!/usr/bin/ruby -w 
# coding: utf-8
#
# First ruby coding 8/2/11
#
# 
#
#
require 'net/http'
require 'net/https'

#require 'rubygems'
require 'active_support'
require 'active_support/core_ext'

require 'json'

require 'nokogiri'
require 'base64'
require 'date'
require 'cgi'

require 'vantiv/require_relative'
require_relative 'ipcommerce/api'
require_relative 'ipcommerce/web_service'
require_relative 'ipcommerce/authentication'
module Ipcommerce

	class IpcommerceError < StandardError; end

	extend Configuration
	class << self
		# Alias for Ipcommerce::Web_service.new
		#
		# @return [Ipcommerce::Web_service]
		def new(options={})
			Ipcommerce::Web_service.new(options)
		end

		# Delegate to Ipcommerce::Web_Service
		def method_missing(method, *args, &block)
			return super unless new.respond_to?(method)
			new.send(method, *args, &block)
		end

		def respond_to?(method, include_private = false)
			new.respond_to?(method, include_private) || super(method, include_private)
			
		end
	end
end