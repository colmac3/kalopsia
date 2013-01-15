require 'spec_helper'

describe TransFirst::Gateway do
  it_should_behave_like "a gateway"
  
  defaults do |txn|
    txn[:merchant_key] = 'J8Q53WQ5GHAL467T'
    txn[:merchant_id]  = '7777777740'
    # txn[:verbose] = true
  end
end
