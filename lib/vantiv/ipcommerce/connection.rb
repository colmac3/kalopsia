#gem 'rexml'
#require 'rexml'

module Ipcommerce
	module Connection
		# Do not call this method. This is used internally to send a request.
		
		unless defined?(URL)
		  URL = 'cws-01.cert.ipcommerce.com'.freeze
		  ENDPOINT='/REST/2.0.16'.freeze
    end

		def action_with_token(method, function, params={})
      #p params

			#Each 
			svc_SvcInfo=[:token,:appProfile,:serviceInformation,:merchProfile]
			svc_Txn=[:Txn]
			svc_DataServices=[:transactionsFamily, :batch, :transactionsSummary, :transactionsDetail] #To be implemented
			##puts "action_with_token(#{function},#{params},#{method})"
			https = Net::HTTP.new(URL, Net::HTTP.https_default_port)
			https.use_ssl = true
			https.ssl_timeout = 2
			https.verify_mode = OpenSSL::SSL::VERIFY_NONE
			source = case 
				when svc_SvcInfo.include?(function); "SvcInfo"
				when svc_Txn.include?(function); ""
				when svc_DataServices.include?(function); "DataServices/TMS" #TODO:To Be Implemented
				else ""
			end
      body=params.delete :body
      target=params.delete :target
      action=function.to_s
      if (!target.nil?)then
        if (!target.is_a? Array) then target=[target.to_s] end
        target= #target can be a string or array
          target.join('/')+do_params(params)
          #the target uri. {target:['path','to','file'], params:{param1:"foo",param2:"bar"}}
      else
        target=""
        action+=do_params(params)
      end
      path=[ENDPOINT, source, action, target]
      path.delete("")
        #Deletes all empty values, to avoid a "//" within a path.
      path=path.compact.join("/")
      #puts "Sending to: #{path}"
			response=https.start { |http|

				request =case (method)
					when :get; Net::HTTP::Get.new(path)
					when :delete; Net::HTTP::Delete.new(path)
					when :put; Net::HTTP::Put.new(path)
					when :post; Net::HTTP::Post.new(path)
				end
				request.basic_auth(@session_token,"")
				request.set_content_type "application/json" #required
				request.delete "accept"	#if a non empty Accept header is sent, 
									#IPC server will send a text/xml response.
				#puts "Body Sent via #{method}","to #{path}:",body
				https.request(request, body)
			}
			if (function==:token and method==:get) then return response.body end 
			if (response.body.nil?) then return end
			begin
				g=JSON.parse(response.body)
      rescue JSON::ParserError
        #g=Hash.from_xml(response.body)
        #raise Ipcommerce::IpcommerceError, "XML error\n"+g.inspect

				begin
          # p "PARSE AS XML: ", response.body
          g=Hash.from_xml(response.body)
					raise Ipcommerce::IpcommerceError, "An xml error was passed.\n"+g.inspect
          #Body type must be ReturnTransaction, ReturnById, AuthorizeTransaction or AuthorizeAndCaptureTransaction
          #{:target=>"4365400001", :body=>"{\"MerchantProfileId\":\"IngenicoTest\",\"Transaction\":{\"TenderData\":{\"PaymentAccountDataToken\":null,\"EcommerceSecurityData\":null,\"SecurePaymentAccountData\":null,\"CardData\":{\"Expire\":\"1210\",\"Track1Data\":null,\"Track2Data\":null,\"CardType\":3,\"CardholderName\":null,\"PAN\":\"5454545454545454\"},\"CardSecurityData\":{\"CVDataProvided\":2,\"CVData\":\"123\",\"KeySerialNumber\":null,\"AVSData\":{\"Street\":\"777 Cherry Street\",\"City\":\"Denver\",\"Phone\":null,\"Country\":234,\"StateProvince\":\"CO\",\"PostalCode\":\"80220\",\"CardholderName\":\"SJohnson\"},\"PIN\":null}},\"__type\":\"BankcardTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Bankcard\",\"TransactionData\":{\"BatchAssignment\":null,\"CashBackAmount\":\"0.00\",\"EmployeeId\":\"12345\",\"InvoiceNumber\":null,\"CurrencyCode\":4,\"Amount\":\"10.00\",\"GoodsType\":2,\"OrderNumber\":\"12345\",\"CustomerPresent\":0,\"AccountType\":0,\"TransactionDateTime\":\"2011-12-08T12:47:11-05:00\",\"LaneId\":\"1\",\"IsPartialShipment\":false,\"EntryMode\":1,\"AlternativeMerchantData\":null,\"TipAmount\":\"0.00\",\"InternetTransactionData\":{\"SessionId\":\"12345\",\"IpAddress\":\"1.1.1.1\"},\"TerminalId\":null,\"SignatureCaptured\":false,\"IndustryType\":4,\"ApprovalCode\":null}},\"__type\":\"AuthorizeTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest\",\"ApplicationProfileId\":\"438812\"}"}
          #{:body=>"{\"__type\":\"AuthorizeTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest\",\"ApplicationProfileId\":\"438812\",\"MerchantProfileId\":\"IngenicoTest\",\"Transaction\":{\"__type\":\"BankcardTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Bankcard\",\"TenderData\":{\"PaymentAccountDataToken\":null,\"SecurePaymentAccountData\":null,\"CardData\":{\"CardType\":3,\"CardholderName\":null,\"PAN\":\"5454545454545454\",\"Expire\":\"1210\",\"Track1Data\":null,\"Track2Data\":null},\"CardSecurityData\":{\"AVSData\":{\"CardholderName\":\"SJohnson\",\"Street\":\"777 Cherry Street\",\"City\":\"Denver\",\"StateProvince\":\"CO\",\"PostalCode\":\"80220\",\"Country\":234,\"Phone\":null},\"CVDataProvided\":2,\"CVData\":\"123\",\"KeySerialNumber\":null,\"PIN\":null},\"EcommerceSecurityData\":null},\"TransactionData\":{\"Amount\":\"10.00\",\"CurrencyCode\":4,\"TransactionDateTime\":\"2011-12-08T12:48:48-05:00\",\"AccountType\":0,\"AlternativeMerchantData\":null,\"ApprovalCode\":null,\"CashBackAmount\":\"0.00\",\"CustomerPresent\":0,\"EmployeeId\":\"12345\",\"EntryMode\":1,\"GoodsType\":2,\"IndustryType\":4,\"LaneId\":\"1\",\"InternetTransactionData\":{\"IpAddress\":\"1.1.1.1\",\"SessionId\":\"12345\"},\"InvoiceNumber\":null,\"OrderNumber\":\"12345\",\"IsPartialShipment\":false,\"SignatureCaptured\":false,\"TerminalId\":null,\"TipAmount\":\"0.00\",\"BatchAssignment\":null}}}", :target=>"4365400001"}

				rescue REXML::ParseException, NoMethodError
					response.body
				end
			end
			
		end
		
		def do_params(params)
			params=if (params.size>=1) then
					"?".concat(params.collect { |k,v| if v =="" then "" else "#{k}=#{CGI::escape(v.to_s)}" end }.join('&'))
			else "" end 
		
		end
		
	end
end
