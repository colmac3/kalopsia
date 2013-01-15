require 'rubygems'
# gem 'xml-simple'
#require 'xmlsimple'
gem 'hpricot'
require 'hpricot'
require 'rest-client'
#require 'nokogiri'
require 'tsys/require_relative' if RUBY_VERSION < "1.9"
require_relative 'tsys_rest_web_service'

class Tsys::Gateway

  def initialize(wiredump_unused = true)

  end


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
          when 'debit'        then do_debit_sale(txn, merchant_id, merchant_key )
          when 'credit'       then do_credit_sale(txn, merchant_id, merchant_key)
          else raise "invalid card mode: #{txn[:card_mode]} (expected one of 'debit', 'credit')"
        end
      when 'sale_return'   then do_sale_return(txn, merchant_id, merchant_key)
      when 'pre_auth'      then do_pre_auth(txn, merchant_id, merchant_key)
      when 'post_pre_auth' then do_post_pre_auth_http(txn, merchant_id, merchant_key)
      when "force_sale"    then do_force_sale(txn, merchant_id, merchant_key)
      when "void"          then credit_void_by_reference_code(txn, merchant_id, merchant_key)
      when "void_by_ton"   then do_void_by_ton(txn, merchant_id, merchant_key)
      when "settlement"    then do_settlement(txn, merchant_id, merchant_key)
      when "batch_inquiry" then do_batch_inquiry(txn, merchant_id, merchant_key)
      when "view_detail"   then view_bankcard_settled_batch_detail(txn, merchant_id, merchant_key)
      when "view_open"     then view_current_open_batch_listing(txn,merchant_id, merchant_key)
      when "view_settled"  then view_settled_batch_summary(txn,merchant_id, merchant_key)
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


 def do_credit_sale(txn,merchant_id, merchant_key)

   tsys_transaction = TsysRestWebService.new()
   tsys_transaction.operator = "TA32150"
   tsys_transaction.merc_id  = "888800000087"
   tsys_transaction.device_id = "88880000008701"
   tsys_transaction.password = "001ToFly!"
   tsys_transaction.txn = txn
   response_hash = tsys_transaction.credit_sale()

   message        = response_hash["InfoNox_Interface"]["TransNox_API_Interface"]["CardRS"]["Status"]["Message"]
   rsp_code       = response_hash["InfoNox_Interface"]["TransNox_API_Interface"]["CardRS"]["Status"]["Code"]
   reference_code = response_hash["InfoNox_Interface"]["TransNox_API_Interface"]["CardRS"]["Status"]["Reference_Number"]
   merchant_id    = response_hash["InfoNox_Interface"]["TransNox_API_Interface"]["CardRS"]["Device_Info"]["Merchant_ID"]
   device_id      = response_hash["InfoNox_Interface"]["TransNox_API_Interface"]["CardRS"]["Device_Info"]["Device_ID"]
   transaction_id = response_hash["InfoNox_Interface"]["TransNox_API_Interface"]["CardRS"]["Transaction_Info"]["Transaction_ID"]
   amount         = response_hash["InfoNox_Interface"]["TransNox_API_Interface"]["CardRS"]["Transaction_Info"]["Transaction_ID"]

   txn[:reference_code] =  reference_code

   if rsp_code == "0000"
     txn[:approval_indicator] = 'A'
   end

   txn[:state] = case txn[:approval_indicator]
                   when 'A' then
                     txn[:message] = message
                     txn[:amount]  = amount
                     :approved
                   else
                     txn[:message] = message
                     :declined # TODO: Need some error checking here.
   end

   return txn
 end # do_credit_sale

 def credit_void_by_reference_code(txn, merchant_id, merchant_key)

  tsys_transaction = TsysRestWebService.new()
  tsys_transaction.operator = "TA32150"
  tsys_transaction.merc_id  = "888800000087"
  tsys_transaction.device_id = "88880000008701"
  tsys_transaction.password = "001ToFly!"
  tsys_transaction.txn = txn
  response_hash = tsys_transaction.credit_void_by_reference_code()

  message = response_hash["InfoNox_Interface"]["TransNox_API_Interface"]["CardRS"]["Status"]["Message"]
  rsp_code = response_hash["InfoNox_Interface"]["TransNox_API_Interface"]["CardRS"]["Status"]["Code"]
  reference_number = response_hash["InfoNox_Interface"]["TransNox_API_Interface"]["CardRS"]["Status"]["Reference_Number"]
  merchant_id = response_hash["InfoNox_Interface"]["TransNox_API_Interface"]["CardRS"]["Device_Info"]["Merchant_ID"]
  device_id = response_hash["InfoNox_Interface"]["TransNox_API_Interface"]["CardRS"]["Device_Info"]["Device_ID"]
  transaction_id = response_hash["InfoNox_Interface"]["TransNox_API_Interface"]["CardRS"]["Transaction_Info"]["Transaction_ID"]
  amount = response_hash["InfoNox_Interface"]["TransNox_API_Interface"]["CardRS"]["Transaction_Info"]["Amount"]


  if rsp_code == "0000"
    txn[:approval_indicator] = 'A'
  end


  txn[:state] = case txn[:approval_indicator]
                  when 'A' then
                    if message == "APPROVED"
                      txn[:message] = "CREDIT VOID"
                      :approved
                    end
                  else
                    txn[:message] = message
                    :declined # TODO: Need some error checking here.
                end

   return txn
end


##################################
##################################
 def do_debit_sale(txn,merchant_id, merchant_key)
 end
 def do_force_sale(txn,merchant_id, merchant_key)
 end
 def do_pre_auth(txn,merchant_id, merchant_key)
 end
 def do_void(txn,merchant_id, merchant_key)
 end

 def do_settlement(txn,merchant_id, merchant_key)
 end

 def do_batch_inquiry(txn,merchant_id, merchant_key)
 end

 def view_current_open_batch_listing(txn,merchant_id, merchant_key)
 end

 def view_bankcard_settled_batch_detail(txn,merchant_id, merchant_key)
 end

 def view_settled_batch_summary(txn, merchant_id, merchant_key)

 end

def create_credit_response_hash(resp)
end # createResponseHash

def create_debit_response_hash(resp)
end #create_debit_response_hash

def create_response_settlement_hash(resp)
end  # create_response_settlement_hash

end #gateway class
