require 'rubygems'
# gem 'xml-simple'
#require 'xmlsimple'
#gem 'hpricot'
#require 'hpricot'
#require 'savon'
#require 'nokogiri'
require 'vantiv/require_relative' if RUBY_VERSION < "1.9"
require_relative 'ipcommerce'

## "iso1_track"=>"B4111111111111111^VARMA/AMIT^2709", "iso2_track"=>"4111111111111111=2709",

class Vantiv::Gateway
  def initialize(wiredump_unused = true)
     require_relative 'application_and_merchant_setup.rb'
  end
=begin
  def initialize(wiredump = true)
    @transfirst_header =  {
                     "User-Agent" => "Ingenico TransFirst Application",
                     "Content-Type" => "application/x-www-form-urlencoded",
                     "Connection" => "close"
                    }
  
    @wiredump = wiredump
  end
=end

  terminal_message = {
             
             "000002" => "Invalid CVV",
           
             "000004" => "CVV Required",
             "000005" => "Check with Issuer",
         
             :W       => "Invalid Street Address",
             :U       => "System Unavailable",
             :E       => "Invalid Address Data",
             :S       =>  "AVS Not Supported"
          }

  # process is the entry point for all transactions
  def process(txn, merchant_id, merchant_key)
    # Rails treats any blank field (x="") as false (x=false), so any parameter that we wish to treat as optional
    # needs to be given a default value of "" here.
    optional = [:shipping]
    optional.each { |key| txn[key] ||= "" } # if it has a nil or false value, give it "" instead.

    @t_device_id = txn[:itid]


    # Kalopsia expects dates to be Date objects, but they might be Strings.
    dates = [:card_expiry_date, :start_date, :end_date]
    dates.each do |date_key|
      if txn[date_key].kind_of?(String)
        txn[date_key] = DateTime.parse(txn[date_key])
      end
    end

    actions = %w(sale sale_return pre_auth post_pre_auth force_sale void void_by_ton settlement batch_inquiry view_detail view_open view_settled)
    case txn[:action]
      when 'sale'
        case txn[:card_mode]
         # when 'debit'        then do_debit_sale(txn)
          when 'credit'       then do_credit_sale(txn)
          else raise "invalid card mode: #{txn[:card_mode]} (expected one of 'debit', 'credit')"
        end
      when "void"          then do_void(txn)
      when "settlement"    then do_settlement(txn)
      else raise "action not found: #{txn[:action]} (expected one of #{actions.inspect})"
    end
  end #process
  
 def credit_track_data(txn)
  case txn[:card_input_type].to_s
    when 'keyed'  then nil
    when 'swiped' then txn[:card_iso2_track]
    else
      raise "card_input_type should be 'keyed' or 'swiped'; found '#{txn[:card_input_type].to_s}'"
  end
 end

 def do_credit_sale(txn)
   txn[:reference_code]  # = get from response
   txn[:approval_indicator] # get from response = 'A'

   ipc_instance=Ipcommerce.new();

   workflow_ids=ipc_instance.get_service_information();
   workflow_ids=workflow_ids["BankcardServices"]

   workflow_ids.each {|svc|
     autotest_profile="IngenicoTest"
     initialized=ipc_instance.is_merchant_profile_initialized(autotest_profile, svc["ServiceId"])
   }

   txndata={
      :TenderData => {
        :PaymentAccountDataToken => nil,
        :SecurePaymentAccountData => nil,
        :CardData => {
          :CardType => 3, :CardholderName => nil,
          :PAN => txn[:card_pan],:Expire => txn[:card_expiry_date].strftime("%m%y"),
          :Track1Data => nil,:Track2Data => nil
        },
        :CardSecurityData => {
          :AVSData => {
            :CardholderName => txn[:card_cardholder_name],
            :Street => "777 Cherry Street",
            :City => "Denver",
            :StateProvince => "CO",
            :PostalCode => "80220",
            :Country => 234,
            :Phone => nil
          },#AVSData
          :CVDataProvided => 2,
          :CVData => "123",
          :KeySerialNumber => nil,
          :PIN => nil
        }, #CardSeurityData
        :EcommerceSecurityData => nil
      }, #TenderData
      :TransactionData => {
        :Amount => sprintf("%09.2f", txn[:amount].to_i / 100.0),
        :CurrencyCode => 4,
        :TransactionDateTime => Time.now,
        :AccountType => 0,
        :AlternativeMerchantData => nil,
        :ApprovalCode => nil,
        :CashBackAmount => "0.00",
        :CustomerPresent => 0,
        :EmployeeId => "12345",
        :EntryMode => 1,
        :GoodsType => 2,
        :IndustryType => 4,
        :LaneId => "1",
        :InternetTransactionData => {
          :IpAddress => "1.1.1.1",
          :SessionId => "12345"
        },#InternetTransactionData
        :InvoiceNumber => nil,
        :OrderNumber => "12345",
        :IsPartialShipment => false,
        :SignatureCaptured => false,
        :TerminalId => txn[:itid],
        :TipAmount => "0.00",
        :BatchAssignment => nil
      } #TransactionData
    }#end txndata
   #https://my.ipcommerce.com/Docs/1.17.15/CWS_API_Reference/BaseTxnDataElements/Transaction.aspx

   basic_txn, workflow_id = nil, nil
   workflow_ids.each { |svc|
     profile="IngenicoTest"
     workflow_id=svc["ServiceId"]

     if (svc["Operations"]["Authorize"]) then
       basic_txn=ipc_instance.authorize_and_capture(txndata,profile, workflow_id)
     end

   }
   transaction_id = basic_txn["TransactionId"]
  # txn[:ton] = transaction_id
   txn[:reference_code] = [transaction_id, workflow_id].join('+')
   #txn[:workflow_id] = workflow_id

   status_message = basic_txn["StatusMessage"]
   amount=basic_txn["Amount"]

   if status_message == "Approved" then
     txn[:approval_indicator] = 'A'
   end

   txn[:state] = case txn[:approval_indicator]
                   when 'A' then
                     txn[:message] = status_message
                     txn[:amount] = amount
                     :approved
                   else :declined # TODO: Need some error checking here.
                  end


   return txn

 end # do_credit_sale

 def do_void(txn)
   ipc_instance=Ipcommerce.new();
   workflow_ids=ipc_instance.get_service_information();
   workflow_ids=workflow_ids["BankcardServices"]

   workflow_ids.each {|svc|
     autotest_profile="IngenicoTest"
     initialized=ipc_instance.is_merchant_profile_initialized(autotest_profile, svc["ServiceId"])
   }

   #clear the old response out
   txn[:message] = nil
   txn[:state] = nil
   txn[:auth_code] = nil


   transaction_id, workflow_id = *txn[:reference_code].split('+')
   basic_txn = nil
   workflow_ids.each { |svc|
     profile="IngenicoTest"
     # workflow_id=svc["ServiceId"]

     # if (svc["Operations"]["Authorize"]) then
     #   basic_txn=ipc_instance.authorize(txndata,profile, workflow_id)
     # end

   }
    #transaction_id = txn[:reference_code]
    #workflow_id    = txn[:workflow_id]

   resp =  "";
   resp = ipc_instance.void(transaction_id, workflow_id)

  status_message = resp["StatusMessage"]
  amount = (resp["Amount"] * 100).to_i
  puts "The transaction id is " + transaction_id
  puts "Status Message is " + status_message
  puts "The amount is " + amount.to_s

  if status_message == "Approved" then
    txn[:approval_indicator] = 'A'
  end

  txn[:state] = case txn[:approval_indicator]
                   when 'A' then
                     txn[:message] = status_message
                     txn[:amount] = amount
                     :approved
                   else :declined # TODO: Need some error checking here.
                  end


   return txn

 end  # do_void

# def do_settlement(txn)
#
#   txn[:state] = case txn[:approval_indicator]
#                   when 'A' then :approved
#                            else :declined # TODO: Need some error checking here.
#               end
#
#   return txn
#  end
end #gateway class
