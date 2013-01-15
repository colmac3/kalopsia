require 'rubygems'
require 'savon'
require 'nokogiri'




class TransFirstWebservice

  attr_accessor :merc_key, :merc_id, :operator, :operator_password, :txn

  def self.document
    # default to the specified url if one isn't already given
    @document ||= "https://ws.cert.processnow.com:443/portal/merchantframework/MerchantWebServices-v1?wsdl"
  end
  
  def self.document=(url)
    @document = url
  end
  
  def initialize()
    @response_hash = {}
    @client = Savon::Client.new do |wsdl, http|
      http.auth.ssl.verify_mode = :none
      wsdl.document = self.class.document
      #{}"https://ws.cert.processnow.com:443/portal/merchantframework/MerchantWebServices-v1?wsdl"
    end #do client
    #return @client
  end

  def credit_sale   
    response = @client.request :v1, "SendTranRequest" do
      soap.namespaces["xmlns:v1"] = "http://postilion/realtime/merchantframework/xsd/v1/"

      soap.body = <<-END_SOAP
      <v1:merc>
        <v1:id>#{merc_id}</v1:id>
        <v1:regKey>#{merc_key}</v1:regKey>
        <v1:inType>1</v1:inType>
      </v1:merc>
      <v1:tranCode>1</v1:tranCode>
      <v1:card>
        <v1:pan>#{txn[:card_pan]}</v1:pan>
        <v1:xprDt>#{txn[:card_expiry_date].strftime("%y%m")}</v1:xprDt>
      </v1:card>
      <v1:reqAmt>#{txn[:amount].to_i}</v1:reqAmt>
      END_SOAP

    end #do client request
    res_hash = response.to_hash
    @response_hash[:rsp_code] =       res_hash[:send_tran_response][:rsp_code]
    @response_hash[:reference_code] = res_hash[:send_tran_response][:tran_data][:tran_nr]
    @response_hash[:amount]        =  res_hash[:send_tran_response][:tran_data][:amt]
    return @response_hash
    #return @response
  end #credit_sale

  def credit_void_by_ton()

    response = @client.request :v1, "SendTranRequest" do
      soap.namespaces["xmlns:v1"] = "http://postilion/realtime/merchantframework/xsd/v1/"
      soap.body = <<-END_SOAP
    <v1:merc>
      <v1:id>#{merc_id}</v1:id>
      <v1:regKey>#{merc_key}</v1:regKey>
      <v1:inType>1</v1:inType>
    </v1:merc>
    <v1:tranCode>6</v1:tranCode>
    <v1:origTranData>
      <v1:tranNr>#{txn[:reference_code]}</v1:tranNr>
    </v1:origTranData>
   END_SOAP
    end # do client request
    res_hash = response.to_hash
    @response_hash[:rsp_code] =       res_hash[:send_tran_response][:rsp_code]
    @response_hash[:reference_code] = res_hash[:send_tran_response][:tran_data][:tran_nr]
    @response_hash[:amount]        =  res_hash[:send_tran_response][:tran_data][:amt]
    return @response_hash
  end #credit_void_by_ton

  def do_force_sale(txn, merchant_id, merchant_key)

    c_exp             = txn[:card_expiry_date].strftime("%m%y")
    t_trackdata       = credit_track_data(txn)
    invoice_num       = txn[:invoice_num]
    c_address         = txn[:c_address]
    c_zip             = txn[:c_zip]
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

end #TransFirstWebservice class
