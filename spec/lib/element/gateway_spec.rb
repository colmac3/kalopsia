require 'spec_helper'

describe Element::Gateway do
  it_should_behave_like "a gateway"


 defaults do |txn|
    txn[:amount] = 123
    txn[:itid] =  "01"
    txn[:card_pan] = '1234567890123456'
    txn[:card_iso2_track] = "1234567890123456=12129876543210"
    # txn[:verbose] = true
  end



end
