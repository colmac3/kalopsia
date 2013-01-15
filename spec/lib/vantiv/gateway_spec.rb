require 'spec_helper'

describe Vantiv::Gateway do
  it_should_behave_like "a gateway"
  
  defaults do |txn|
    txn[:card_pan] = '5454545454545454'
    txn[:card_iso2_track] = "5454545454545454=2709"
    # txn[:verbose] = true
  end
end
