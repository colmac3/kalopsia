require 'rubygems'
# gem 'xml-simple'
#require 'xmlsimple'
gem 'hpricot'
require 'hpricot'
require 'savon'
#require 'nokogiri'
require 'trans_first/require_relative' if RUBY_VERSION < "1.9"
require_relative 'trans_first_webservice'


#production
#wsdl.document = "https://ws.processnow.com/portal/merchantframework/MerchantWebServices-v1?wsdl"
# Test
#wsdl.document = " https://ws.cert.processnow.com:443/portal/merchantframework/MerchantWebServices-v1?wsdl"


## "iso1_track"=>"B4111111111111111^VARMA/AMIT^2709", "iso2_track"=>"4111111111111111=2709",
# trans_first_transaction.merc_key = "J8Q53WQ5GHAL467T"
# trans_first_transaction.merc_id  = "7777777740"

class TransFirst::Gateway

  def initialize(wiredump_unused = true)

  end

  # process is the entry point for all transactions
  # (merchant) <v1:id>7777777740</v1:id>
  # (merchant) <v1:regKey>J8Q53WQ5GHAL467T</v1:regKey>
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
      when "void"          then do_void_by_ton(txn, merchant_id, merchant_key)
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

 def do_debit_sale(txn,merchant_id, merchant_key)

   ####
   #### TransFirst has no Debit at this time.
   ####

   invoice_num = txn[:invoice_num]
   c_zip       = txn[:c_zip]
   c_address   = txn[:c_address]


   if invoice_num == false
     invoice_num = nil
   end

   if c_zip == false
     c_zip = nil
   end

   if c_address == false
     c_address = nil
   end



   c_exp       = txn[:card_expiry_date].strftime("%y%m")
   t_trackdata = credit_track_data(txn)
   t_customer_number = txn[:customer_number]

   if t_customer_number == false
     t_customer_number = nil
   end


   t_pin = "#{txn[:card_pin_block]}#{txn[:card_pin_smid]}"



    resp =  "";

  # resp_hash = call trans_first_webservice blah,




# check that the TON matches the original TON
    original_ton = txn[:ton]

# TON matches so continue.


   
    if resp_hash[:ton] != original_ton.to_s
      raise "TON returned does not match original TON"
    end

    txn = resp_hash # clear out the old txn for security reasons

    #put the result of the transaction back into the txn.
    #txn[:message] = resp_hash[:message]
    txn[:state] = case txn[:approval_indicator]
                    when 'A' then :approved
                             else :declined # TODO: Need some error checking here.
                end
    #txn[:auth_code] = resp_hash[:reference_code]
    if (txn[:message] && txn[:message] =~ /^APPROVED(\s+)([^\s]*)/)
     txn[:auth_code] =  $~[2].strip
    end

    # have to override RTML's automatic ref code with the one returned from server
    # not all servers require this.
    txn[:reference_code] = resp_hash[:reference_code]
    return txn
  end #do_debit_sale

 def do_credit_sale(txn,merchant_id, merchant_key)


   trans_first_transaction = TransFirstWebservice.new()
   trans_first_transaction.merc_id = merchant_id
   trans_first_transaction.merc_key = merchant_key
   trans_first_transaction.txn = txn

   res_hash = trans_first_transaction.credit_sale()
   rsp_code             =  res_hash[:rsp_code]
   txn[:reference_code] =  res_hash[:reference_code]
   amount               =  res_hash[:amount]

 if rsp_code == "00"
   txn[:approval_indicator] = 'A'
 end

   txn[:state] = case txn[:approval_indicator]
                   when 'A' then
                     txn[:message] = "APPROVED"
                     txn[:amount] = amount
                     :approved
                else :declined # TODO: Need some error checking here.
   end

   return txn
 end # do_credit_sale

 def do_force_sale(txn,merchant_id, merchant_key)

   c_exp = txn[:card_expiry_date].strftime("%y%m")
   t_trackdata = credit_track_data(txn)
   invoice_num = txn[:invoice_num]

   if invoice_num == false
     invoice_num = nil
   end


   c_address = txn[:c_address]
   c_zip     = txn[:c_zip]
   t_customer_number = txn[:customer_number]

   if c_zip == false
     c_zip = nil
   end

   if c_address == false
     c_address = nil
   end

   if t_customer_number == false
     t_customer_number = nil
   end

   # todo , Call trans_first_webservice


   #put the result of the transaction back into the txn.
   #txn[:message] = resp_hash[:message]
   txn[:state] = case txn[:approval_indicator]
                   when 'A' then :approved
                            else :declined # TODO: Need some error checking here.
                 end
   #txn[:auth_code] = resp_hash[:reference_code]
   if (txn[:message] && txn[:message] =~ /^APPROVED(\s+)([^\s]*)/)
    txn[:auth_code] =  $~[2].strip
   end

   # have to override RTML's automatic ref code with the one returned from server
   # not all servers require this.
   txn[:reference_code] = resp_hash[:reference_code]
   return txn

 end

 def do_pre_auth(txn,merchant_id, merchant_key)

    # how was the tranaction derived :swiped, :emv, :keyed
    c_exp = txn[:card_expiry_date].strftime("%y%m")
    t_trackdata = credit_track_data(txn)
    invoice_num = txn[:invoice_num]

    if invoice_num == false
      invoice_num = nil
    end
    

    c_zip       = txn[:c_zip]
    c_address   = txn[:c_address]
    t_customer_number = txn[:customer_number]


    if c_zip == false
      c_zip = nil
    end

    if c_address == false
      c_address = nil
    end

    if t_customer_number == false
      t_customer_number = nil
    end

   # todo , Call trans_first_webservice


    #put the result of the transaction back into the txn.
    #txn[:message] = resp_hash[:message]
    txn[:state] = case txn[:approval_indicator]
                    when 'A' then :approved
                             else :declined # TODO: Need some error checking here.
    end


   if (txn[:message] && txn[:message] =~ /^APPROVED(\s+)([^\s]*)/)
    txn[:auth_code] =  $~[2].strip
   end

   # txn[:auth_code] = resp_hash[:reference_code]
    # have to override RTML's automatic ref code with the one returned from server
    # not all servers require this.
    txn[:reference_code] = resp_hash[:reference_code]
    return txn
 end

 def do_post_pre_auth_http(txn, merchant_id, merchant_key)
     # blah call tran_first_webservice

   txn[:state] = case txn[:approval_indicator]
                     when 'A' then :approved
                              else :declined # TODO: Need some error checking here.
                 end

     return txn
 end

 def do_sale_return(txn, merchant_id, merchant_key)

   invoice_num = txn[:invoice_num]

   c_zip       = txn[:c_zip]
   c_address   = txn[:c_address]

   if invoice_num == false
     invoice_num = nil
   end
   
   if c_zip == false
     c_zip = nil
   end

   if c_address == false
     c_address = nil
   end

  # todo , Call trans_first_webservice

   #put the result of the transaction back into the txn.
   #txn[:message] = resp_hash[:message]
   txn[:state] = case txn[:approval_indicator]
                   when 'A' then :approved
                            else :declined # TODO: Need some error checking here.
               end
   #txn[:auth_code] = resp_hash[:reference_code]
   # have to override RTML's automatic ref code with the one returned from server
   # not all servers require this.

   if (txn[:message] && txn[:message] =~ /^APPROVED(\s+)([^\s]*)/)
    txn[:auth_code] =  $~[2].strip
   end

   txn[:reference_code] = resp_hash[:reference_code]
   return txn

 end

def do_void_by_ton(txn,merchant_id, merchant_key)

  trans_first_transaction = TransFirstWebservice.new()
  trans_first_transaction.merc_id = merchant_id
  trans_first_transaction.merc_key = merchant_key
  trans_first_transaction.txn = txn
  # this is actually void by reference_code
  res_hash = trans_first_transaction.credit_void_by_ton()

  rsp_code             =  res_hash[:rsp_code]
  txn[:reference_code] =  res_hash[:reference_code]
  amount               =  res_hash[:amount]


  if rsp_code == "00"
    txn[:approval_indicator] = 'A'
  end
  txn[:state] = case txn[:approval_indicator]
                  when 'A' then
                    txn[:message] = "CREDIT VOID"
                    :approved
                  else :declined # TODO: Need some error checking here.
                end

   return txn
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
