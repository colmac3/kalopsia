require 'spec_helper'

describe Sage::Gateway do
  it_should_behave_like "a gateway"
  
  defaults do |txn|
    txn[:merchant_id]  = '869440795604'
    txn[:merchant_key] = 'Y7Q7Q7C7G7A7'
  end
end
