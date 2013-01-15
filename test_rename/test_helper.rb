ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test_rename method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test_rename database remains unchanged so your fixtures don't have to be reloaded
  # between every test_rename method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test_rename transactions.  Since your test_rename is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test_rename cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test_rename method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test_rename/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  # TODO: Can this be automated?
  set_fixture_class :rtml_card_avs => Rtml::CardAvs,
                    :rtml_card_cvvs => Rtml::CardCvv,
                    :rtml_card_parsers => Rtml::CardParser,
                    :rtml_cards => Rtml::Card,
                    :rtml_emv_card_data => Rtml::EmvCardData,
                    :rtml_mag_card_data => Rtml::MagCardData,
                    :rtml_reference_codes => Rtml::ReferenceCode,
                    :rtml_states => Rtml::State,
                    :rtml_terminals => Rtml::Terminal,
                    :rtml_transactions => Rtml::Transaction,
                    :rtml_card_pins => Rtml::CardPin

  def assert_approved(txn)
    assert_equal :approved, txn.state, "Trans not approved: \"#{txn.message}\""
    assert txn.message =~ /^APPROVED(\s+)([^\s]*)/, "Message \"#{txn.message}\" does not start with \"APPROVED \""
    assert_equal $~[2].strip, txn.auth_code, "Auth code does not match"
  end
end
