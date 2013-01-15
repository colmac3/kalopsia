#!/usr/bin/env ruby

api = ARGV[0]

raise "Specify an API name (matching directory name)" unless api

# pull in Rails environment
require 'thread'
require './config/environment'

3.times { puts }
puts "Loading API"
3.times { puts }

# Try to load the named API
require File.join(api, "gateway")

puts "Running txn"
3.times { puts }

@txn = {
  :action => 'sale' ,
  :card_pan => '4111111111111111',
  :card_iso2_track => "4111111111111111=2709",
  :reference_code => '',
  :card_expiry_date => 1.year.from_now,
  :ton => Time.new.usec.to_s,
  :card_mode => 'credit',
  :customer_number => "",
  :amount => 100
}
Vantiv::Gateway.new({}).process(@txn, nil, nil)#, $mid, $mkey)


puts "All files loaded successfully."


