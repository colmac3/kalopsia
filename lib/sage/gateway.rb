require 'rubygems'
# gem 'xml-simple'
#require 'xmlsimple'
gem 'hpricot'
require 'hpricot'



## "iso1_track"=>"B4111111111111111^VARMA/AMIT^2709", "iso2_track"=>"4111111111111111=2709",

class Sage::Gateway
  def initialize(wiredump = true)
    @sage_header =  {
                     "User-Agent" => "Ingenico Sage Application",
                     "Content-Type" => "application/x-www-form-urlencoded",
                  #   "Host" => "www.sagepayments.net",
                     "Connection" => "close"
                    }
  
    @wiredump = wiredump
  end
  terminal_message = {
             
             "000002" => "Invalid CVV",
           
             "000004" => "CVV Required",
             "000005" => "Check with Issuer",
         
             :W       => "Invalid Street Address",
             :U       => "System Unavailable",
             :E       => "Invalid Address Data",
             :S       =>  "AVS Not Supported"
          }
  # t_code values (transaction code)
  # 01 Sale  (debit)
  # 02 Authorization only
  # 03 Force/PriorAuthSale
  # 04 Void by Reference. Used with Electronic Commerce, MOTO, Retail and Restaurant transactions.
  # 06 Credit or Refund
  # 10 Credit or Refund by Reference - Used with Electronic Commerce, MOTO transactions
  # 11 Force by Reference - Used with Electronic Commerce, MOTO transactions
  # 12 void by TON
  #test merchant_id = 869440795604
  #test merchant_key = 'Y7Q7Q7C7G7A7'
  # process is the entry point for all transactions
  def process(txn, merchant_id, merchant_key)
    # Rails treats any blank field (x="") as false (x=false), so any parameter that we wish to treat as optional
    # needs to be given a default value of "" here.
    optional = [:shipping]
    optional.each { |key| txn[key] ||= "" } # if it has a nil or false value, give it "" instead.

=begin
    1.       ICT 220 – B&W IP Incendo Terminal
             APPID: INGETERMICT2200COUNAAE8USEN

    2.       ICT 250 – Color Incendo Terminal
             APPID: INGETERMICT2500COUNAAE9USEN
=end

    @t_device_id = txn[:itid]

    case txn[:model]
     when 'ICT220' then @t_application_id = "INGETERMICT2200COUNAAE8USEN"
     when 'ICT250' then @t_application_id = "INGETERMICT2500COUNAAE9USEN"
    end





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
      when "void"          then do_void(txn, merchant_id, merchant_key)
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



   c_exp       = txn[:card_expiry_date].strftime("%m%y")
   t_trackdata = credit_track_data(txn)
   t_customer_number = txn[:customer_number]

   if t_customer_number == false
     t_customer_number = nil
   end


   t_pin = "#{txn[:card_pin_block]}#{txn[:card_pin_smid]}"

   payload = {
              :C_cardnumber => txn[:card_pan],
              :T_pin        => t_pin.upcase,
              :T_trackdata  => t_trackdata,
              :M_id         => merchant_id,
              :M_key        => merchant_key,
              :T_cash_back_amt  => txn[:cash_back_amt].to_i / 100.0, 
              :T_amt        => txn[:amount].to_i / 100.0 + txn[:tax].to_i / 100.0 +  txn[:cash_back_amt].to_i / 100.0 ,
              :T_tax        => txn[:tax].to_i / 100.0,
              :C_address    => c_address,
              :C_zip        => c_zip,
              :T_code       => '01',
              :C_exp        => c_exp,
              :T_ordernum   => invoice_num,
              :T_customer_number => t_customer_number,
              :T_device_id  => @t_device_id,
              :T_application_id => @t_application_id,
              :T_uti        => txn[:ton]
   }

    sage_host =   "www.sagepayments.net"
    sage_webservice_access_point = "/cgi-bin/eftBankcard.dll?debit_transaction"


    resp =  "";
    resp = do_webservice(sage_host, sage_webservice_access_point, payload)
# check that the TON matches the original TON
    original_ton = txn[:ton]

# TON matches so continue.

    resp_hash = create_debit_response_hash(resp)
   
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
  end #doSale

 def do_credit_sale(txn,merchant_id, merchant_key)

   # how was the tranaction derived :swiped, :emv, :keyed
   c_exp = txn[:card_expiry_date].strftime("%m%y")
   t_trackdata = credit_track_data(txn)
   invoice_num = txn[:invoice_num]
   t_customer_number = txn[:customer_number]


   if t_customer_number == false
     t_customer_number = nil
   end

   if invoice_num == false
     invoice_num = nil
   end

   
   c_zip = txn[:c_zip]
   c_address = txn[:c_address]

   if c_zip == false
     c_zip = nil
   end

   if c_address == false
     c_address = nil
   end




   ## The $sage_host and $sage_sale_endpoint are set in the config/environments/production.rb file.
   ## They are set for load testing in pre-prod.
  if txn[:ton] =~ /^1118833/
    $use_ssl = $use_stub_ssl
    sage_host = $sage_stub_host
    sage_webservice_access_point =  $sage_stub_sale_endpoint
   else
    # we are in Production so set ssl true
    $use_ssl = true
    sage_host = $sage_host
    sage_webservice_access_point = $sage_sale_endpoint
  end
#   sage_host =   "www.sagepayments.net"
#   sage_webservice_access_point = "/cgi-bin/eftBankcard.dll?retail_transaction"
   
   payload = {
             :C_cardnumber => txn[:card_pan],
             :T_trackdata  => t_trackdata,   #txn[:card_iso2_track],
             :C_exp        => c_exp,         #txn[:card_expiry_date].strftime("%m%y"), #if card number in manual must have expDate
             :M_id         => merchant_id,
             :M_key        => merchant_key,
             :C_address    => c_address,
             :C_zip        => c_zip,
             :T_amt        => txn[:amount].to_i / 100.0 + txn[:tax].to_i / 100.0,
             :T_tax        => txn[:tax].to_i / 100.0,
             :T_code       => '01',
             :T_ordernum   => invoice_num,
             :T_customer_number => t_customer_number,
             :T_device_id  => @t_device_id,
             :T_application_id => @t_application_id,
             :T_uti       => txn[:ton]
             }
   resp =  "";
   resp = do_webservice(sage_host, sage_webservice_access_point, payload)

   resp_hash = create_credit_response_hash(resp)

   # check that the TON matches the original TON
    original_ton = txn[:ton].to_s
    if resp_hash[:ton] != original_ton and not original_ton =~ /^1118833/
      raise "TON #{resp_hash[:ton].inspect} returned does not match original TON #{original_ton.inspect}"
    end

   txn = resp_hash # clear out the old txn for security reasons
   # TON matches so continue.
   # put the result of the transaction back into the txn.
   # txn[:ton] =   resp_hash[:ton] # the ton matches so why put it back in the txn
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

 def do_force_sale(txn,merchant_id, merchant_key)

   sage_host =   "www.sagepayments.net"
   sage_webservice_access_point = "/cgi-bin/eftBankcard.dll?retail_transaction"
   c_exp = txn[:card_expiry_date].strftime("%m%y")
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



   payload = {
             :C_cardnumber => txn[:card_pan],
             :T_pin        => txn[:card_pin_block],
             :T_trackdata  => t_trackdata,
             :C_name       => txn[:card_cardholder_name],
             :C_zip        => c_zip,
             :C_address    => c_address,
             :M_id         => merchant_id,
             :M_key        => merchant_key,
             :T_amt        => txn[:amount].to_i / 100.0  + txn[:tax].to_i / 100.0,
             :T_tax        => txn[:tax].to_i / 100.0,
             :T_code       => '03',   # Force
             :C_exp        => c_exp,
             :T_auth       => txn[:force_auth_code],  #T_auth is always 6 chars
             :T_ordernum   => invoice_num,
             :T_customer_number => t_customer_number,
             :T_device_id  => @t_device_id,
             :T_application_id => @t_application_id,
             :T_uti        => txn[:ton]
  }
   resp =  ""

   resp = do_webservice(sage_host, sage_webservice_access_point, payload)

   resp_hash = create_credit_response_hash(resp)
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

 end

 def do_pre_auth(txn,merchant_id, merchant_key)

    # how was the tranaction derived :swiped, :emv, :keyed
    c_exp = txn[:card_expiry_date].strftime("%m%y")
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




    sage_host =   "www.sagepayments.net"
    sage_webservice_access_point = "/cgi-bin/eftBankcard.dll?retail_transaction"

    payload = {
              :C_cardnumber => txn[:card_pan],
              :T_trackdata  => t_trackdata,
              :C_exp        => c_exp,
              :C_address    => c_address,
              :C_zip        => c_zip,
              :M_id         => merchant_id,
              :M_key        => merchant_key,
              :T_amt        => txn[:amount].to_i / 100.0  + txn[:tax].to_i / 100.0,
              :T_tax        => txn[:tax].to_i / 100.0,
              :T_code       => '02',   # 02 Authorization only
              :T_ordernum   => invoice_num,
              :T_customer_number => t_customer_number,
              :T_device_id  => @t_device_id,
              :T_application_id => @t_application_id,
              :T_uti       => txn[:ton] # this is our TON
              }
    resp =  "";
    resp = do_webservice(sage_host, sage_webservice_access_point, payload)


    resp_hash = create_credit_response_hash(resp)
    txn = resp_hash # clear out the old txn for security reasons

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

 def do_post_pre_auth_soap(txn,merchant_id, merchant_key) #not used
    # after a pre_auth you have to post the payment.
   sage_host =   "www.sagepayments.net"
   sage_webservice_access_point = "/web_services/vterm_extensions/transaction_processing.asmx/BANKCARD_PRIOR_AUTH_SALE?"
  
    payload = {

              :M_id         => merchant_id,
              :M_key        => merchant_key,
              :T_amt        => txn[:amount].to_i / 100.0  + txn[:tax].to_i / 100.0,
              :T_tax        => txn[:tax].to_i / 100.0,
              :T_shipping  =>  txn[:shipping],
              :T_auth      =>  txn[:auth_code],
              :T_reference  => txn[:reference]
              }
    resp =  "";
    resp = do_webservice(sage_host, sage_webservice_access_point, payload)
    txn = create_post_pre_auth_response_soap_hash(resp)
   
    return txn
  end   #not used (TON not implemented in SOAP)

 def do_post_pre_auth_http(txn,merchant_id, merchant_key)
     # after a pre_auth you have to post the payment.
    sage_host =   "www.sagepayments.net"
    sage_webservice_access_point = "/cgi-bin/eftBankcard.dll?retail_transaction"

     payload = {

               :M_id         => merchant_id,
               :M_key        => merchant_key,
               :T_amt        => txn[:amount].to_i / 100.0  + txn[:tax].to_i / 100.0,
               :T_tax        => txn[:tax].to_i / 100.0,
               :T_shipping  =>  "",
               #:T_auth      =>  txn[:auth_code],
               :T_reference  => txn[:reference],
               :T_uti        => txn[:ton],
               :T_device_id  => @t_device_id,
               :T_application_id => @t_application_id,
               :T_code       => '11'
               }
     resp =  ""
     resp = do_webservice(sage_host, sage_webservice_access_point, payload)
     txn = create_credit_response_hash(resp)
     txn[:state] = case txn[:approval_indicator]
                     when 'A' then :approved
                              else :declined # TODO: Need some error checking here.
     end

     return txn
   end

 def do_sale_return(txn,merchant_id, merchant_key)
   sage_host =   "www.sagepayments.net"
   sage_webservice_access_point = "/cgi-bin/eftBankcard.dll?retail_transaction"



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

   #t_pin = "#{txn[:card_pin_block]}#{txn[:card_pin_smid]}"
   #:T_pin        => t_pin.upcase
   
   
   payload = {
             :C_cardnumber => txn[:card_pan],
             :T_trackdata  => txn[:card_iso2_track],
             :C_exp        => txn[:card_expiry_date].strftime("%m%y"), #if card number in manual must have expDate
             :C_name       => txn[:card_cardholder_name],
             :C_address    => c_address,
             :C_zip        => c_zip,
             :M_id         => merchant_id,
             :M_key        => merchant_key,
             :T_amt        => txn[:amount].to_i / 100.0 + txn[:tax].to_i / 100.0,
             :T_tax        => txn[:tax].to_i / 100.0,
             :T_code       => '06',   # 06 Credit or Refund
             :T_ordernum   => invoice_num,
             :T_device_id  => @t_device_id,
             :T_application_id => @t_application_id,
             :T_uti       => txn[:ton]
           #  :T_reference  => txn[:reference_code]
             }
   resp =  ""
   resp = do_webservice(sage_host, sage_webservice_access_point, payload)

   resp_hash = create_credit_response_hash(resp)
   txn = resp_hash # clear out the old txn for security reasons
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

   # how was the tranaction derived :swiped, :emv, :keyed
   c_exp = txn[:card_expiry_date].strftime("%m%y")
   t_trackdata = credit_track_data(txn)
   invoice_num = txn[:invoice_num]



   sage_host =   "www.sagepayments.net"
   sage_webservice_access_point = "/cgi-bin/eftBankcard.dll?retail_transaction"

   payload = {
             :C_cardnumber => txn[:card_pan],
             :T_trackdata  => t_trackdata,   #txn[:card_iso2_track],
             :C_exp        => c_exp,         #txn[:card_expiry_date].strftime("%m%y"), #if card number in manual must have expDate
             :M_id         => merchant_id,
             :M_key        => merchant_key,
             :T_amt        => txn[:amount].to_i / 100.0 + txn[:tax].to_i / 100.0,
             :T_tax        => txn[:tax].to_i / 100.0,
             :T_code       => '12',
             :T_ordernum   => invoice_num,
             :T_device_id  => @t_device_id,
             :T_application_id => @t_application_id,
             :T_uti       => txn[:ton]
             }
   resp =  "";
   resp = do_webservice(sage_host, sage_webservice_access_point, payload)

   resp_hash = create_credit_response_hash(resp)

   # check that the TON matches the original TON
    original_ton = txn[:ton].to_s
    if resp_hash[:ton] != original_ton.to_s
      raise "TON #{resp_hash[:ton].inspect} returned does not match original TON #{original_ton.inspect}"
    end

   txn = resp_hash # clear out the old txn for security reasons
   # TON matches so continue.
   # put the result of the transaction back into the txn.
   # txn[:ton] =   resp_hash[:ton] # the ton matches so why put it back in the txn
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

 def do_void(txn,merchant_id, merchant_key)
   #clear the old response out
   txn[:message] = nil
   txn[:state] = nil
   txn[:auth_code] = nil

   sage_host =   "www.sagepayments.net"
   sage_webservice_access_point = "/cgi-bin/eftBankcard.dll?retail_transaction"

   payload = {
#             :C_cardnumber => txn[:card_pan],
#             :T_trackdata  => txn[:card_iso2_track],
#             :C_exp        => txn[:card_expiry_date].strftime("%m%y"), #if card number in manual must have expDate
#             :C_name       => txn[:card_cardholder_name],
             :M_id         => merchant_id,
             :M_key        => merchant_key,
             :T_amt        => txn[:amount].to_i / 100.0 + txn[:tax].to_i / 100.0,
             :T_tax        => txn[:tax].to_i / 100.0,
             :T_code       => '04',   # Void by reference_code
             :T_reference  => txn[:reference_code],
             :T_device_id  => @t_device_id,
             :T_application_id => @t_application_id,
             :T_uti      =>  txn[:ton]
             }
   resp =  "";
   resp = do_webservice(sage_host, sage_webservice_access_point, payload)

   resp_hash = create_credit_response_hash(resp)
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

 end

 def do_settlement(txn,merchant_id, merchant_key)
#Response Format:[STX]A   265BATCH 1 OF 1 CLOSED             000002000000002.00C7KA7olCu0[FS][ETX]
#stx approval_indicator batch_number message batch_item_count batch_net reference field_separator extra_data
# "a1a1a6a32a6a12a10a1a*"
   sage_host =   "www.sagepayments.net"
   sage_webservice_access_point = "/cgi-bin/eftBankcard.dll?settlement"

   payload = {

             :M_id         => merchant_id,
             :T_device_id  => @t_device_id,
             :T_application_id => @t_application_id,
             :M_key        => merchant_key
  }
   


   resp =  "";
   resp = do_webservice(sage_host, sage_webservice_access_point, payload)

   resp_hash = create_response_settlement_hash(resp)
   txn = resp_hash # clear out the old txn for security reasons
   #txn[:message] = resp_hash[:message]
   txn[:state] = case txn[:approval_indicator]
                   when 'A' then :approved
                            else :declined # TODO: Need some error checking here.
               end

   return txn


  end

 def do_batch_inquiry(txn,merchant_id, merchant_key)

    sage_host =   "www.sagepayments.net"
    sage_webservice_access_point = "/cgi-bin/eftBankcard.dll?settlement"


    payload = {
              :T_device_id  => @t_device_id,
              :T_application_id => @t_application_id,
              :M_id         => merchant_id,
              :M_key        => merchant_key,
              :B_count      => -1,
              :B_net        => -1
   }

    resp =  "";
    # resp format example:[STX]I    20BATCH INQUIRY                   000110000001198.64B25ABnE1E0[FS][ETX]

    resp = do_webservice(sage_host, sage_webservice_access_point, payload)

#stx, settlement_indicator, code, message, batch_count, batch_negative_indicator,
#batch_net, unique_batch_number, extra_data

    resp_hash = create_response_settlement_hash(resp)
    txn = resp_hash # clear out the old txn for security reasons
    #put the result of the transaction back into the txn.
    #txn[:message] = resp_hash[:message]
    txn[:state] = case txn[:approval_indicator]
                    when 'I' then :approved
                             else :declined # TODO: Need some error checking here.
                end
    return txn

 end

 def do_webservice(sage_host, sage_webservice_access_point, payload)

    resp =  ""
    port = $use_ssl ? 443 : 80
    http = Net::HTTP.new(sage_host, port)
    http.use_ssl = $use_ssl

    if @wiredump
      Rails.logger.debug "WIREDUMP UP: #{sage_host}:#{port} - #{sage_webservice_access_point.inspect} - #{@sage_header.inspect}"
      Rails.logger.debug ">>>>>>>>>>>>>>>>>"
      Rails.logger.debug payload.to_yaml
      Rails.logger.debug ">>>>>>>>>>>>>>>>>"
    end
    http.start do |http_r|
    req = Net::HTTP::Post.new(sage_webservice_access_point, @sage_header)
    req.body = payload.to_query
    response = http_r.request(req)
    resp = response.body
    end
    if @wiredump
      Rails.logger.debug "WIREDUMP DOWN:"
      Rails.logger.debug resp
      Rails.logger.debug "<<<<<<<<<<<<<<<<<"
    end
    return resp
  end

 def view_current_open_batch_listing(txn,merchant_id, merchant_key)
#    Pre-Auth list will fall under the current Batch Inquiry solution.
#    The pre-auth transactions are returned with the current
#    Batch Inquiry with transaction listing code (2) to identify them
#    as auth only.
    #Test URL:
    #https://www.sagepayments.net/web_services/vterm_extensions/reporting.asmx?op=VIEW_CURRENT_BATCH_LISTING
    sage_host =   "www.sagepayments.net"
    sage_webservice_access_point = "/web_services/vterm_extensions/reporting.asmx/VIEW_CURRENT_BATCH_LISTING?"


    payload = {

              :M_id         => merchant_id,
              :M_key        => merchant_key,
    }

    resp =  "";
    # resp will contain a rather complex MS ADO XML string. Visit the URL above to test
    # and examine the response.
    resp = do_webservice(sage_host, sage_webservice_access_point, payload)


 # Test for soap return
    doc = Hpricot::XML(resp)
    ret = []
      (doc/"Table").each do |tables|
        txn = {}
        txn[:transaction_code] = (tables/"transaction_code").inner_html
        txn[:reference] = (tables/"reference").inner_html
        txn[:message] = (tables/"message").inner_html
        txn[:transaction_type] = (tables/"transaction_type").inner_html
        txn[:primary_data] = (tables/"primary_data").inner_html
        txn[:date] = (tables/"date").inner_html
        txn[:total_amount] = (tables/"total_amount").inner_html
        ret << txn
      end
    return ret
  end

 def view_bankcard_settled_batch_detail(txn,merchant_id, merchant_key)
#    batch_reference_number comes from view_settled_batch_summary
#    Pre-Auth list will fall under the current Batch Inquiry solution.
#    The pre-auth transactions are returned with the current
#    Batch Inquiry with transaction listing code (2) to identify them
#    as auth only.
    #Test URL:

    sage_host =   "www.sagepayments.net"
    sage_webservice_access_point = "/web_services/vterm_extensions/reporting.asmx/VIEW_BANKCARD_SETTLED_BATCH_LISTING?"


    payload = {

              :M_id         => merchant_id,
              :M_key        => merchant_key,
              :BATCH_REFERENCE => txn[:batch_reference_number]  # comes from view_settled_batch_summary
    }

    resp =  "";
    # resp will contain a rather complex MS ADO XML string. Visit the URL above to test
    # and examine the response.
    resp = do_webservice(sage_host, sage_webservice_access_point, payload)

    ret = []

    doc = Hpricot::XML(resp)
    (doc/"Table").each do |table|
      txn = {}
      
      %w(date name address city state zip country email_addr telephone fax recipient ship_address ship_city ship_state
         ship_zip ship_country cardnumber card_exp_date approved message code order_number avs_code status_code
         transaction_code total_amount tax_amount shipping_amount settle_date card_type reference cvv_code
         batch_reference customer_number).each do |field|
        ele = (table / field)
        txn[field.to_sym] = ele.inner_html if ele
      end

#      txn[:transaction_code]  = (tables/"transaction_code").inner_html
#      txn[:batch_reference] = (tables/"batch_reference").inner_html
#      txn[:card_type] = (tables/"card_type").inner_html
#      txn[:transaction_type] = (tables/"transaction_type").inner_html
#      txn[:date] = (tables/"date").inner_html
#      txn[:total_amount] = (tables/"total_amount").inner_html
      ret << txn
    end

    return ret

  end

 def view_settled_batch_summary(txn, merchant_id, merchant_key)
    #https://www.sagepayments.net/web_services/vterm_extensions/reporting.asmx
    # this response will be in the form of XML
    sage_host =   "www.sagepayments.net"
    sage_webservice_access_point = "/web_services/vterm_extensions/reporting.asmx/VIEW_SETTLED_BATCH_SUMMARY?"
    #add the following to complete request M_ID=string&M_KEY=string&START_DATE=string&END_DATE=string&INCLUDE_BANKCARD=false&INCLUDE_VIRTUAL_CHECK=false"
    # where dates are MM/DD/YYY
    #GET /web_services/vterm_extensions/reporting.asmx/VIEW_SETTLED_BATCH_SUMMARY?M_ID=string&M_KEY=string&START_DATE=string&END_DATE=string&INCLUDE_BANKCARD=string&INCLUDE_VIRTUAL_CHECK=string HTTP/1.1
    #Host: www.sagepayments.net
    
    payload = {

              :M_id         => merchant_id,
              :M_key        => merchant_key,
              :START_DATE      => txn[:start_date].strftime("%m/%d/%Y 00:00:00"),
              :END_DATE        => txn[:end_date].strftime("%m/%d/%Y 23:59:59"),
              :INCLUDE_BANKCARD => 'true',
              :INCLUDE_VIRTUAL_CHECK => 'false'

   }
    resp =  "";
    resp = do_webservice(sage_host, sage_webservice_access_point, payload)

    ret = []
    doc = Hpricot::XML(resp)
    (doc/"Table").each do |tables|
      txn = {}
      txn[:type] = (tables/"type").inner_html
      txn[:count] = (tables/"count").inner_html
      txn[:reference] = (tables/"reference").inner_html
      txn[:net] = (tables/"net").inner_html
      txn[:date] = (tables/"date").inner_html
      ret << txn
    end
 
    ret

  end

 def create_post_pre_auth_response_soap_hash(resp)    #not used
    doc = Hpricot::XML(resp)

    ret = []

    (doc/"Table1").each do |tables|
      txn = {}
      txn[:state] = case (tables/"APPROVAL_INDICATOR").inner_html
                      when 'A' then :approved
                               else :declined # TODO: Need some error checking here.
      end
      
      txn[:approval_indicator] = (tables/"APPROVAL_INDICATOR").inner_html
      txn[:code] = (tables/"CODE").inner_html
      txn[:message] = (tables/"MESSAGE").inner_html
      txn[:front_end_indicator] = (tables/"FRONT_END_INDICATOR").inner_html
      txn[:cvv_indicator] = (tables/"CVV_INDICATOR").inner_html
      txn[:avs_indicator] = (tables/"AVS_INDICATOR").inner_html
      txn[:risk_indicator] = (tables/"RISK_INDICATOR").inner_html
      txn[:reference] = (tables/"REFERENCE").inner_html
      txn[:order_number] = (tables/"ORDER_NUMBER").inner_html
      ret << txn
    end

    return ret
  end

 def create_credit_response_hash(resp)

    if resp[-1] != ?\03
      raise "No ETX on response string #{resp.inspect}"
    end
    resp = resp[0...-1]  # remove ETX

    stx, approval_indicator, code, message, front_end, cvv_indicator, avs_indicator, risk_indicator, extra_data = resp.unpack("a1a1a6a32a2a1a1a2a*")
    reference_code, order_number, ton = extra_data.split("\34") # 34=FS



    if (message && message =~ /VIOLATION/)
      raise Errors::BadCredentials, "SECURITY VIOLATION"
    end
    

    if ton
      ton = ton[4..-1]  #remove that ridiculous UTI embedded in the extra data. Remove the FS
    else
      raise "No TON found in response data!\n\n#{resp.inspect}"
    end
    resp_hash = {}
    %w(stx approval_indicator code message front_end cvv_indicator avs_indicator risk_indicator reference_code order_number ton).each {|item|
    resp_hash[item.to_sym] = eval(item)
    }
    return resp_hash

  end # createResponseHash

 def create_debit_response_hash(resp)

    if resp[-1] != ?\03
      raise "No ETX on response string #{resp.inspect}"
    end
    resp = resp[0...-1]

    stx, approval_indicator, code, message, front_end, cvv_indicator, dummy1, risk_indicator, extra_data = resp.unpack("a1a1a6a32a2a1a1a2a*")
    reference_code, order_number, ton = extra_data.split("\34") # 34=FS

    if (message && message =~ /VIOLATION/)
      raise Errors::BadCredentials, "SECURITY VIOLATION"
    end


    ton = ton[4..-1]
    resp_hash = {}
    %w(stx approval_indicator code message front_end cvv_indicator dummy1 risk_indicator reference_code order_number ton).each { |item|
    resp_hash[item.to_sym] = eval(item)
    }
    return resp_hash
end #create_debit_response_hash

 def create_response_settlement_hash(resp)
  #example of inquiry returned from sage
  #Batch Settlement Response:[STX]A   265BATCH 1 OF 1 CLOSED             000002000000002.00C7KA7olCu0[FS][ETX]
  #Batch Inquiry Response:   [STX]I   20BATCH INQUIRY                   000110000001198.64B25ABnE1E0[FS][ETX]
  # current response:        [STX]A   205BATCH 1 OF 1 CLOSED             000020000000214.94C9RABs5BH0[FS]DT  09272010115306[ETX]

   if resp[-1] != ?\03
     raise "No ETX on response string #{resp.inspect}"
   end
   resp = resp[0...-1]
  

  stx, approval_indicator, batch_number, message, batch_item_count, batch_net, reference, field_separator, extra_data = resp.unpack("a1a1a6a32a6a12a10a1a*")

  if (message && message =~ /VIOLATION/)
    raise Errors::BadCredentials, "SECURITY VIOLATION"
  end
  

  settlement_date = extra_data.split("\34")[0]
  settlement_date = settlement_date[4..-1]

p settlement_date
  resp_hash = {}
   %w(stx approval_indicator batch_number message batch_item_count batch_net reference field_separator settlement_date).each {|item|
   resp_hash[item.to_sym] = eval(item)
   }
 
  return resp_hash
 end  # create_response_settlement_hash

end #gateway class

# The following is the Transaction Data Format sent to us by Sage
=begin
Transaction debit/credit sale:
     [STX]A000001APPROVED 000001                 10M 00C1IA72diT0[FS]ID1IA72diU[FS]0[FS][ETX]
This is the format of the response string from sage
Field/Data Element, Length, Start Position, Description
STX                      1               1   ASCII 02, Start of Message Indicator
Approval Indicator       1               2   · A = Approved
                                             · E = Front-End Error / Non-Approved
                                             · X = Gateway Error / Non-Approved
Code                     6               3   Approval or Error Code
Message                 32               9   Approval or Error Message
Front-End                2     CVV Indicator            1              43   · M = Match
                                             · N = CVV No Match
                                             · P = Not Processed
                                             · S = Merchant Has Indicated that CVV2 Is Not Present
                                             · U = Issuer is not certified and/or has not provided Visa Encryption Keys
AVS Indicator            1              44   · X = Exact; match on address and 9 Digit Zip Code
                                             · Y = Yes; match on address and 5 Digit Zip Code
                                             · A = Address matches, Zip does not
                                             · W = 9 Digit Zip matches, address does not
                                             · Z = 5 Digit Zip matches, address does not
                                             · N = No; neither zip nor address match
                                             · U = Unavailable
                                             · R = Retry
                                             · E = Error
                                             · S = Service Not Supported
                                             · " " = Service Not Supported International AVS Codes
                                             · D = Match Street Address and Postal Code match for International Transaction
                                             · M = Match Street Address and Postal Code match for International Transaction
                                             · B = Partial Match Street Address Match for International Transaction. Postal Code not verified due to incompatible formats
                                             · P = Partial Match Postal Codes match for International Transaction but street address not verified due to incompatible formats
                                             · C = No Match Street Address and Postal Code not verified for International Transaction due to incompatible formats
                                             · I = No Match Address Information not verified by International issuer
                                             · G = Not Supported Non-US. Issuer does not participate         41   Front-End Indicator (Internal Use Only)

Risk Indicator           2              45   · 01 = Max Sale Exceeded
                                             · 02 = Min Sale Not Met
                                             · 03 = 1 Day Volume Exceeded
                                             · 04 = 1 Day Usage Exceeded
                                             · 05 = 3 Day Volume Exceeded
                                             · 06 = 3 Day Usage Exceeded
                                             · 07 = 15 Day Volume Exceeded
                                             · 08 = 15 Day Usage Exceeded
                                             · 09 = 30 Day Volume Exceeded
                                             · 10 = 30 Day Usage Exceeded
                                             · 11 = Stolen or Lost Card
                                             · 12 = AVS Failure
Reference              10               47   Unique Reference Code
Field Separator         1               57   ASCII 28, Field Separator
Order Number     Variable              N/A   Order Number
Field Separator         1              N/A   ASCII 28, Field Separator
Recurring Indicator     1              N/A   1 = Added as a Recurring Transaction
Field Separator         1              N/A   ACSII 28, Field Separator
ExtraUTIData    Variable              N/A   Ingenico uses this for the TON Number. Sage returns "UTI<TON>"
ETX                     1              N/A   ASCII 03, End of Message Indicator
=end
