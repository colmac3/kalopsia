require 'test_helper'
#test_rename merchant_id = 869440795604
#test_rename merchant_key = 'Y7Q7Q7C7G7A7'

class Sage::CreditTest < ActionController::TestCase
  ### A test_rename starting with numbers (e.g. "1 credit force auth code is incorrect") is referring to its Lighthouse
  # ticket number and name.

  def setup
    @controller = PaymentGatewayController.new
    @options = { :merchant_id => 869440795604,
                 :merchant_key => 'Y7Q7Q7C7G7A7',
                 :processor => "sage",
                 :format => 'yaml' }
  end

  def dispatch(txn, options = {})
    post "authorize", @options.merge(:txn => txn.attributes).merge(options)
    assert_response :success
    
    yaml = @controller.response.body
    if yaml =~ /body \{ /m
      puts yaml
      flunk "Response was in HTML format"
    end
    txn.from(YAML::load(yaml))
  end

  test "1 credit force auth code is incorrect" do
    txn = rtml_transactions(:credit_force_100)
    txn.hidden_data[:force_auth_code] = '123456'
    txn = dispatch txn
    assert_equal '123456', txn.auth_code
  end

  test "2 auth code is not parsed from message" do
    txn = dispatch rtml_transactions(:credit_force_100)
    assert_not_equal txn.reference_code.value, txn.auth_code
  end

  test "sage credit sale" do
    txn = dispatch rtml_transactions(:credit_sale_100)
    assert_approved txn
  end

  test "sage credit force" do
    txn = rtml_transactions(:credit_force_100)
    txn.hidden_data[:force_auth_code] = '123456'
    txn = dispatch txn

    assert_approved txn
    assert_equal '123456', txn.auth_code
  end

  test "sage credit return" do
    txn = dispatch rtml_transactions(:credit_return_100)
    assert_approved txn
  end

  test "sage credit void" do
    # run a sale
    txn = dispatch rtml_transactions(:credit_sale_100)
    assert_approved txn
    # now reverse that sale
    txn.action = 'void'
    txn = dispatch txn
    assert_approved txn
  end
end
