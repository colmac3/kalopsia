require 'spec_helper'

describe Tsys::Gateway do
  it_should_behave_like "a gateway"
  
  defaults do |txn|
    txn[:card_pan] = '4111111111111111'
    txn[:card_iso2_track] = "4111111111111111=2709"
    # txn[:verbose] = true
  end
end
