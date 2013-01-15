require 'test_helper'
#test_rename merchant_id = 869440795604
#test_rename merchant_key = 'Y7Q7Q7C7G7A7'

class PaymentGatewayControllerTest < ActionController::TestCase


  test "sage credit sale from fixture" do
    post "authorize", :merchant_id => 869440795604, :merchant_key => 'Y7Q7Q7C7G7A7', :processor => "sage", :txn => rtml_transactions(:credit_sale_100).attributes
  end

  test "sage credit sale via web service" do
    # this test_rename emulates the "authorize(txn)" method as implemented by a client application
    # (the kind that would normally inherit Beryl)

    txn = rtml_transactions(:credit_sale_100)
    
    # Now "txn" is identical to the txn argument that Beryl passes into #authorize for a credit sale.
    # Following is exactly how a credit sale might be run against kalopsia.

    data = { :txn => txn.attributes_with_associations }
    Net::HTTP.new('localhost', 3000).start do |http|
      path = "/payment_gateway/authorize/sage.yaml?merchant_id=869440795604&merchant_key=Y7Q7Q7C7G7A7"
      response = http.post(path, data.to_query)

      yaml = response.body
      txn.from(YAML::load(yaml))
    end

    assert_not_nil txn.message, "Transaction has no message"
    assert_equal :approved, txn.state, "Transaction was not approved"
    assert_not_nil txn.auth_code, "Transaction has no auth code"
  end

  # Replace this with your real tests.
  test "the Debit Sale transaction with sage" do
   #app.url_for(:processor => "sage", :controller => "payment_gateway", :action => "debit", :txn => {"action" => "sale",
    # "approval_code"=>nil, "post_id"=>1775, "date"=>DateTime.parse("Mon, 01 Feb 2010"), "card"=>{"parser"=>{"verdict"=>"online",
    # "cvm"=>nil, "reject_reason"=>nil, "type"=>"mag", "cvr"=>"failed"}, "cvv"=>{"reason_skipped"=>nil, "value"=>nil},
    # "emv"=>{"iac_online"=>nil, "iad"=>nil, "cvmr"=>nil, "aac"=>nil, "auc"=>0, "iac_default"=>nil, "signature"=>0,
    # "tc"=>nil, "atc"=>0,
    #"iso_track2"=>nil, "tvr"=>nil, "aid"=>nil, "arqc"=>nil, "aip"=>0, "last_attempt"=>0, "app_pan_seq"=>nil, "iac_denial"=>nil,
    # "unumber"=>0}, "pin.smid"=>nil, "input_type"=>1, "pin.array"=>0, "expiry_date"=>DateTime.parse("Wed Sep 01 00:00:00 UTC 2027"),
    # "cardholder_name"=>"MACKENZIE COLIN4          ", "pan"=>"4111111111111111", "scheme"=>"VISA", "avs"=>{"zip"=>nil},
    # "effective_date"=>nil, "issue_number"=>0, "mag"=>{"iso1_track"=>"B4111111111111111^MACKENZIE/COLIN4^2709",
    # "iso2_track"=>"4111111111111111=05121010000", "service_code"=>"NA", "iso3_track"=>nil}, "pin.length"=>0, "issuer_name"=>"NA",
    # "pin"=>nil}, "manual_entry"=>0, "transaction_type"=>"Credit", "payment"=>{"amount"=>1234, "trans_type"=>"debit",
    # "amount_other"=>0}, "itid"=>"200", "oebr"=>{"submit_mode"=>"online", "time_zone"=>0}, "reference_num"=>"1234",
    # "xmlns"=>"http://www.ingenico.co.uk/tml"})
    post "authorize", :processor => "sage",
         :merchant_id => 869440795604,
         :merchant_key => 'Y7Q7Q7C7G7A7',
         :txn => {"action" => "sale", "approval_code"=>nil, "post_id"=>1775, "date"=>DateTime.parse("Mon, 01 Feb 2010"),
                                                 "card"=>{
                                                         "mode" => "debit",
                                                         "parser"=>{"verdict"=>"online", "cvm"=>nil, "reject_reason"=>nil, "type"=>"mag", "cvr"=>"failed"},
                                                         "cvv"=>{"reason_skipped"=>nil, "value"=>nil},
                                                         "emv"=>{"iac_online"=>nil, "iad"=>nil, "cvmr"=>nil, "aac"=>nil, "auc"=>0, "iac_default"=>nil, "signature"=>0, "tc"=>nil, "atc"=>0, "iso_track2"=>nil, "tvr"=>nil, "aid"=>nil, "arqc"=>nil, "aip"=>0, "last_attempt"=>0, "app_pan_seq"=>nil, "iac_denial"=>nil, "unumber"=>0},
                                                         "pin.smid"=>"00000E0001C0005B",
                                                         "pin"=>"1B9C1845EB993A7A4A00000000000000", "input_type"=>1, "pin.array"=>0, "expiry_date"=>DateTime.parse("Wed Sep 01 00:00:00 UTC 2027"), "cardholder_name"=>"MACKENZIE COLIN4          ", "pan"=>"4111111111111111", "scheme"=>"VISA",
                                                         "avs"=>{"zip"=>nil}, "effective_date"=>nil, "issue_number"=>0,
                                                         "mag"=>{"iso1_track"=>"B4111111111111111^MACKENZIE/COLIN4^2709", "iso2_track"=>"4111111111111111=05121010000", "service_code"=>"NA", "iso3_track"=>nil},
                                                         "pin.length"=>0,
                                                         "issuer_name"=>"SAGE"
                                                 },
                                                 "manual_entry"=>0,
                                                 "payment"=>{"amount"=>1234, "trans_type"=>"debit", "amount_other"=>0}, "itid"=>"200",
                                                 "oebr"=>{"submit_mode"=>"online", "time_zone"=>0}, "reference_num"=>"1234", "xmlns"=>"http://www.ingenico.co.uk/tml"}


    



    assert_response :success
    #assert true
  end


    test "the Credit Sale transaction with sage" do
   #app.url_for(:processor => "sage", :controller => "payment_gateway", :action => "debit", :txn => {"action" => "sale", "approval_code"=>nil, "post_id"=>1775, "date"=>DateTime.parse("Mon, 01 Feb 2010"), "card"=>{"parser"=>{"verdict"=>"online", "cvm"=>nil, "reject_reason"=>nil, "type"=>"mag", "cvr"=>"failed"}, "cvv"=>{"reason_skipped"=>nil, "value"=>nil}, "emv"=>{"iac_online"=>nil, "iad"=>nil, "cvmr"=>nil, "aac"=>nil, "auc"=>0, "iac_default"=>nil, "signature"=>0, "tc"=>nil, "atc"=>0, "iso_track2"=>nil, "tvr"=>nil, "aid"=>nil, "arqc"=>nil, "aip"=>0, "last_attempt"=>0, "app_pan_seq"=>nil, "iac_denial"=>nil, "unumber"=>0}, "pin.smid"=>nil, "input_type"=>1, "pin.array"=>0, "expiry_date"=>DateTime.parse("Wed Sep 01 00:00:00 UTC 2027"), "cardholder_name"=>"MACKENZIE COLIN4          ", "pan"=>"4111111111111111", "scheme"=>"VISA", "avs"=>{"zip"=>nil}, "effective_date"=>nil, "issue_number"=>0, "mag"=>{"iso1_track"=>"B4111111111111111^MACKENZIE/COLIN4^2709", "iso2_track"=>"4111111111111111=2709", "service_code"=>"NA", "iso3_track"=>nil}, "pin.length"=>0, "issuer_name"=>"NA", "pin"=>nil}, "manual_entry"=>0, "transaction_type"=>"Credit", "payment"=>{"amount"=>1234, "trans_type"=>"debit", "amount_other"=>0}, "itid"=>"200", "oebr"=>{"submit_mode"=>"online", "time_zone"=>0}, "reference_num"=>"1234", "xmlns"=>"http://www.ingenico.co.uk/tml"})
    post "authorize", :processor => "sage",
         :merchant_id => 869440795604,
         :merchant_key => 'Y7Q7Q7C7G7A7',
         :txn => {"action" => "sale", "approval_code"=>nil, "post_id"=>1775, "date"=>DateTime.parse("Mon, 01 Feb 2010"),
                                                 "card"=>{
                                                         "mode" => "credit",
                                                         "parser"=>{"verdict"=>"online", "cvm"=>nil, "reject_reason"=>nil, "type"=>"mag", "cvr"=>"failed"},
                                                         "cvv"=>{"reason_skipped"=>nil, "value"=>nil},
                                                         "emv"=>{"iac_online"=>nil, "iad"=>nil, "cvmr"=>nil, "aac"=>nil, "auc"=>0, "iac_default"=>nil, "signature"=>0, "tc"=>nil, "atc"=>0, "iso_track2"=>nil, "tvr"=>nil, "aid"=>nil, "arqc"=>nil, "aip"=>0, "last_attempt"=>0, "app_pan_seq"=>nil, "iac_denial"=>nil, "unumber"=>0},
                                                         "pin.smid"=>nil, "input_type"=>1, "pin.array"=>0, "expiry_date"=>DateTime.parse("Wed Sep 01 00:00:00 UTC 2027"), "cardholder_name"=>"MACKENZIE COLIN4          ", "pan"=>"4111111111111111", "scheme"=>"VISA",
                                                         "avs"=>{"zip"=>nil}, "effective_date"=>nil, "issue_number"=>0,
                                                         "mag"=>{"iso1_track"=>"B4111111111111111^MACKENZIE/COLIN4^2709", "iso2_track"=>"4111111111111111=2709", "service_code"=>"NA", "iso3_track"=>nil}, "pin.length"=>0,
                                                         "issuer_name"=>"SAGE", "pin"=>nil
                                                 },
                                                 "manual_entry"=>0,
                                                 "payment"=>{"amount"=>1234, "trans_type"=>"debit", "amount_other"=>0}, "itid"=>"200",
                                                 "oebr"=>{"submit_mode"=>"online", "time_zone"=>0}, "reference_num"=>"1234", "xmlns"=>"http://www.ingenico.co.uk/tml"}
    assert_response :success
    #assert true
  end

  test "Batch Inquiry with sage" do
 #app.url_for(:processor => "sage", :controller => "payment_gateway", :action => "debit", :txn => {"action" => "sale", "approval_code"=>nil, "post_id"=>1775, "date"=>DateTime.parse("Mon, 01 Feb 2010"), "card"=>{"parser"=>{"verdict"=>"online", "cvm"=>nil, "reject_reason"=>nil, "type"=>"mag", "cvr"=>"failed"}, "cvv"=>{"reason_skipped"=>nil, "value"=>nil}, "emv"=>{"iac_online"=>nil, "iad"=>nil, "cvmr"=>nil, "aac"=>nil, "auc"=>0, "iac_default"=>nil, "signature"=>0, "tc"=>nil, "atc"=>0, "iso_track2"=>nil, "tvr"=>nil, "aid"=>nil, "arqc"=>nil, "aip"=>0, "last_attempt"=>0, "app_pan_seq"=>nil, "iac_denial"=>nil, "unumber"=>0}, "pin.smid"=>nil, "input_type"=>1, "pin.array"=>0, "expiry_date"=>DateTime.parse("Wed Sep 01 00:00:00 UTC 2027"), "cardholder_name"=>"MACKENZIE COLIN4          ", "pan"=>"4111111111111111", "scheme"=>"VISA", "avs"=>{"zip"=>nil}, "effective_date"=>nil, "issue_number"=>0, "mag"=>{"iso1_track"=>"B4111111111111111^MACKENZIE/COLIN4^2709", "iso2_track"=>"4111111111111111=2709", "service_code"=>"NA", "iso3_track"=>nil}, "pin.length"=>0, "issuer_name"=>"NA", "pin"=>nil}, "manual_entry"=>0, "transaction_type"=>"Credit", "payment"=>{"amount"=>1234, "trans_type"=>"debit", "amount_other"=>0}, "itid"=>"200", "oebr"=>{"submit_mode"=>"online", "time_zone"=>0}, "reference_num"=>"1234", "xmlns"=>"http://www.ingenico.co.uk/tml"})
  post "authorize", :processor => "sage",
       :merchant_id => 869440795604,
       :merchant_key => 'Y7Q7Q7C7G7A7',
       :txn => {"action" => "batch_inquiry", "approval_code"=>nil, "post_id"=>1775, "date"=>DateTime.parse("Mon, 01 Feb 2010"),
                                               "card"=>{
                                                       "mode" => "credit",
                                                       "parser"=>{"verdict"=>"online", "cvm"=>nil, "reject_reason"=>nil, "type"=>"mag", "cvr"=>"failed"},
                                                       "cvv"=>{"reason_skipped"=>nil, "value"=>nil},
                                                       "emv"=>{"iac_online"=>nil, "iad"=>nil, "cvmr"=>nil, "aac"=>nil, "auc"=>0, "iac_default"=>nil, "signature"=>0, "tc"=>nil, "atc"=>0, "iso_track2"=>nil, "tvr"=>nil, "aid"=>nil, "arqc"=>nil, "aip"=>0, "last_attempt"=>0, "app_pan_seq"=>nil, "iac_denial"=>nil, "unumber"=>0},
                                                       "pin.smid"=>nil, "input_type"=>1, "pin.array"=>0, "expiry_date"=>DateTime.parse("Wed Sep 01 00:00:00 UTC 2027"), "cardholder_name"=>"MACKENZIE COLIN4          ", "pan"=>"4111111111111111", "scheme"=>"VISA",
                                                       "avs"=>{"zip"=>nil}, "effective_date"=>nil, "issue_number"=>0,
                                                       "mag"=>{"iso1_track"=>"B4111111111111111^MACKENZIE/COLIN4^2709", "iso2_track"=>"4111111111111111=2709", "service_code"=>"NA", "iso3_track"=>nil}, "pin.length"=>0,
                                                       "issuer_name"=>"SAGE", "pin"=>nil
                                               },
                                               "manual_entry"=>0,
                                               "payment"=>{"amount"=>1234, "trans_type"=>"credit", "amount_other"=>0}, "itid"=>"200",
                                               "oebr"=>{"submit_mode"=>"online", "time_zone"=>0}, "reference_num"=>"1234", "xmlns"=>"http://www.ingenico.co.uk/tml"}
  assert_response :success
  #assert true
end





end
