require 'rubygems'
require 'active_support'
require 'active_support/core_ext'

require 'net/https'
require 'uri'
require 'nokogiri'


## "iso1_track"=>"B4111111111111111^VARMA/AMIT^2709", "iso2_track"=>"4111111111111111=2709",

class Element::Gateway
  def initialize(wiredump_unused = true)
    # require_relative 'application_and_merchant_setup.rb'
  end

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
  # txn[:card_pan] txn[:card_expiry_date].strftime("%m%y")

credit_sale_hash =
{
  :Application =>
  {
    :ApplicationID => "1258",
    :ApplicationName => "IngenicoApp",
    :ApplicationVersion => "v1"
  }, # end Application
  :Credentials =>
  {
    :AcceptorID => "3928907",
    :AccountID => "1001194",
    :AccountToken => "CA16460306C7ACDE1BB2FC4862A7AB7DE27BF93B3B981E0280E3D4FD9564D09268E8DF01"
  }, # end Credentials
  :Transaction =>
  {
    :TransactionAmount =>  sprintf("%09.2f", txn[:amount].to_i / 100.0),
    #:TransactionAmount => "1.23",
    :MarketCode => "7"
  },# end Transaction>
  :Terminal =>
  {
    # :TerminalID => "01",
    :TerminalID =>  "01",
    :CardPresentCode => "2",
    :CardholderPresentCode => "2",
    :CVVPresenceCode => "4",
    :TerminalCapabilityCode => "5",
    :TerminalEnvironmentCode => "1",
    :MotoECICode => "1",
    :CardInputCode => "2"
  }, # end Terminal
  :Card =>
  {
    # :Track2Data => "1234567890123456=12129876543210"
    :Track2Data => txn[:card_iso2_track]
  }# end Card
} # end credit_sale_hash

   xml_req_credit_sale = credit_sale_hash.to_xml(:dasherize => false, :camelize => true, :skip_types =>true, :skip_instruct => true, :root => "CreditCardSale").sub(/<CreditCardSale/, "<CreditCardSale xmlns='https://transaction.elementexpress.com'")

   # p xml_req_credit_sale.inspect

   uri = URI.parse("https://certtransaction.elementexpress.com")
   http = Net::HTTP.new(uri.host, uri.port)
   http.use_ssl = true
   http.verify_mode = OpenSSL::SSL::VERIFY_NONE
   request = Net::HTTP::Post.new(uri.request_uri)
   request.content_type = 'text/xml'

   request.body =  xml_req_credit_sale

   response = http.request(request)
   response_xml = response.body


   xml_doc  = Nokogiri::XML(response.body)
   #approved_number = xml_doc.xpath("//xmlns:TransactionID")
   #p approved_number.text
   #p xml_doc.css('xmlns|TransactionID').text
   #p xml_doc.css('Transaction TransactionID').text
   transaction_id     = xml_doc.css('TransactionID').text
   approval_number    = xml_doc.css('ApprovalNumber').text
   transaction_status = xml_doc.css('TransactionStatus').text
   response_message = xml_doc.css('ExpressResponseMessage').text
   response_code = xml_doc.css('ExpressResponseCode').text
   approved_amount = xml_doc.css('ApprovedAmount').text



#p "ANOUNT +++++++++ = " + sprintf("%09.2f", txn[:amount].to_i / 100.0)
#p "TRACKDATA****** = " + txn[:card_iso2_track]
#p "Transaction ID = " + transaction_id
#p "Approved Amount = " + approved_amount
#p "Approval Number = " + approval_number
#p "Transaction Status = " + transaction_status
#p "response message = " + response_message
#p "response code = " + response_code






   txn[:ton] = transaction_id
   status_message = transaction_status

   if status_message == "Approved" then
     txn[:approval_indicator] = 'A'
   end

   txn[:state] = case txn[:approval_indicator]
                   when 'A' then
                     txn[:message] = status_message
                     txn[:amount] = approved_amount
                     txn[:reference_code] =  transaction_id
                     :approved
                   else :declined # TODO: Need some error checking here.
                  end


   return txn

 end # do_credit_sale

 def do_void(txn)

   #clear the old response out
   txn[:message] = nil
   txn[:state] = nil
   txn[:auth_code] = nil
   void_number = txn[:ton]


   credit_void_hash =
   {
     :Application =>
     {
       :ApplicationID => "1258",
       :ApplicationName => "IngenicoApp",
       :ApplicationVersion => "v1"
     }, # end Application
     :Credentials =>
     {
       :AcceptorID => "3928907",
       :AccountID => "1001194",
       :AccountToken => "CA16460306C7ACDE1BB2FC4862A7AB7DE27BF93B3B981E0280E3D4FD9564D09268E8DF01"
     }, # end Credentials
     :Transaction =>
     {
       :TransactionAmount =>  sprintf("%09.2f", txn[:amount].to_i / 100.0),
       #:TransactionID => txn[:ton]
       :TransactionID =>  txn[:reference_code]
     },# end Transaction>
     :Terminal =>
     {
       :TerminalID => "01",
       :CardPresentCode => "2",
       :CardholderPresentCode => "2",
       :CVVPresenceCode => "4",
       :TerminalCapabilityCode => "5",
       :TerminalEnvironmentCode => "1",
       :MotoECICode => "1",
       :CardInputCode => "2"
     }, # end Terminal
     :Card =>
     {
        #:Track2Data => "1234567890123456=12129876543210"
        :Track2Data => txn[:card_iso2_track]
     }# end Card
   } # end credit_sale_hash

   xml_req_credit_void = credit_void_hash.to_xml(:dasherize => false, :camelize => true, :skip_types =>true, :skip_instruct => true, :root => "CreditCardVoid").sub(/<CreditCardVoid/, "<CreditCardVoid xmlns='https://transaction.elementexpress.com'")

   uri = URI.parse("https://certtransaction.elementexpress.com")
   http = Net::HTTP.new(uri.host, uri.port)
   http.use_ssl = true
   http.verify_mode = OpenSSL::SSL::VERIFY_NONE
   request = Net::HTTP::Post.new(uri.request_uri)
   request.content_type = 'text/xml'
   request.body = xml_req_credit_void
   response = http.request(request)
   puts response.body

   xml_doc  = Nokogiri::XML(response.body)
   #approved_number = xml_doc.xpath("//xmlns:TransactionID")
   #p approved_number.text
   #p xml_doc.css('xmlns|TransactionID').text
   #p xml_doc.css('Transaction TransactionID').text

   transaction_id     = xml_doc.css('TransactionID').text
   approval_number    = xml_doc.css('ApprovalNumber').text
   transaction_status = xml_doc.css('TransactionStatus').text
   response_message = xml_doc.css('ExpressResponseMessage').text
   response_code = xml_doc.css('ExpressResponseCode').text


   p "Transaction ID = " + transaction_id
   p "Approval Number = " + approval_number
   p "Transaction Status = " + transaction_status
   p "response message = " + response_message
   p "response code = " + response_code

  status_message =   transaction_status

  if status_message == "Success" || status_message == "Approved" then
    txn[:approval_indicator] = 'A'
  end

  txn[:state] = case txn[:approval_indicator]
                   when 'A' then
                     txn[:message] = status_message
                     #txn[:amount] = amount
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
