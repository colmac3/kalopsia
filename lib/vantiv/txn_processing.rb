require 'require_relative'
require_relative 'ipcommerce'

puts "See source for links to documentation"
ipc_instance=Ipcommerce.new();

workflow_ids=ipc_instance.get_service_information();
workflow_ids=workflow_ids["BankcardServices"]

workflow_ids.each {|svc|



  autotest_profile="IngenicoTest"
  #autotest_profile="Merchant_"+svc["ServiceId"]
	initialized=ipc_instance.is_merchant_profile_initialized(autotest_profile, svc["ServiceId"])


=begin
	puts svc, "Initialization check: "+if initialized then "true" else "false" end
	if (!initialized) then
		merchantProfile={ProfileId: autotest_profile,ServiceName: svc["ServiceName"],LastUpdated: Time.now,MerchantData:{CustomerServiceInternet: "",CustomerServicePhone: "303 3333333",Language: 127,Address: {Street1: "777 Cherry Street",Street2: "",City: "Denver",StateProvince: 7,PostalCode: "80220",CountryCode: 234},MerchantId: "IngenicoTest",Name: "IngenicoTest",Phone: "303 3333333",TaxId: "",BankcardMerchantData:{ABANumber: "1234",AcquirerBIN: "123456",AgentBank: "123456",AgentChain: "123456",Aggregator: false,ClientNumber: "1224",IndustryType: 4,Location: "000",MerchantType: "",PrintCustomerServicePhone: false,QualificationCodes: "",ReimbursementAttribute: "1",SIC: "1234",SecondaryTerminalId: "12345678",SettlementAgent: "1234",SharingGroup: "1234",StoreId: "1234",TerminalId: "124",TimeZoneDifferential: "123"},ElectronicCheckingMerchantData: {OrginatorId: "",ProductId: "",SiteId: ""}},TransactionData: {BankcardTransactionDataDefaults: {CurrencyCode: 4,CustomerPresent: 1,EntryMode: 0,RequestACI: 2,RequestAdvice: 2}}}
		ipc_instance.save_merchant_profile(merchantProfile, svc["ServiceId"])
	end
=end


}

#sure we made sure TestProfile exists, but we will use the first returned.
#Some service providers require username and password

# addendum={"Unmanaged"=>{"Any"=>["<Username>Ingenico<\/Username>","<Password>Tests<\/Password>"]}}
# removed CustomerData from txndata. place just before TenderData.
# CustomerData: nil,ReportingData: nil,Addendum: addendum, ApplicationConfigurationData: nil,

txndata={
         :TenderData => {
                          :PaymentAccountDataToken => nil,:SecurePaymentAccountData => nil,
                          :CardData => {
                                         :CardType => 3, :CardholderName => nil,
                                         :PAN => "5454545454545454",:Expire => "1210",
                                         :Track1Data => nil,:Track2Data => nil
                                       },
                          :CardSecurityData => {
                                                 :AVSData => {
                                                               :CardholderName => "SJohnson",
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
                               :Amount => "10.00",
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
                               :TerminalId => nil,
                               :TipAmount => "0.00",
                               :BatchAssignment => nil
                             } #TransactionData
        }#end txndata
#https://my.ipcommerce.com/Docs/1.17.15/CWS_API_Reference/BaseTxnDataElements/Transaction.aspx

workflow_ids.each {|svc|
  profile="IngenicoTest"
  #autotest_profile="Merchant_"+svc["ServiceId"]
	         #profile="Merchant_"+svc["ServiceId"]
	workflow_id=svc["ServiceId"]

  if (svc["Operations"]["Authorize"]) then
		puts "","","Begin Authorize with WorkflowId: #{workflow_id}"

    puts "Result:"
		basic_txn=ipc_instance.authorize_and_capture(txndata,profile, workflow_id)
    puts basic_txn.inspect

    transaction_id = basic_txn["TransactionId"]
    status_message = basic_txn["StatusMessage"]
    amount=basic_txn["Amount"]
    puts "The transaction id is " + transaction_id
    puts "Status Message is " + status_message
    puts "The amount is " + amount.to_s

    puts "Doing Void"
    puts "Result:",
	  void_txn=ipc_instance.void(transaction_id, workflow_id) #.inspect

    transaction_id = void_txn["TransactionId"]
    status_message = void_txn["StatusMessage"]
    puts "Void Complete"
	end


  # this is for settle
  #if (svc["Operations"]["Capture"] and !basic_txn.nil?) then
  #  puts "","","Begin Capture with WorkflowId: #{workflow_id}"
  #  puts "Result:",
  #  captured_txn=ipc_instance.capture(basic_txn,{Amount: "20.00"},  profile, workflow_id)
  #end


exit(99)







=begin
  if (svc["Operations"]["AuthAndCapture"]) then
    if (svc["Tenders"]["CreditAuthorizeSupport"]==2)
      puts "","","Begin Authorize and Capture with WorkflowId: #{workflow_id}"
      puts "Result:",
      auth_result = ipc_instance.authorize_and_capture(txndata, profile, workflow_id)
      transaction_id = auth_result["TransactionId"]
      puts "The transaction id is " + transaction_id

      puts "Doing Void"
      puts "Result:",
      ipc_instance.void(transaction_id, workflow_id)
      puts "Void Complete"
    end
  end

	if (svc["Operations"]["Authorize"]) then
		puts "","","Begin Authorize with WorkflowId: #{workflow_id}"
		puts "Result:",
		basic_txn=ipc_instance.authorize(txndata,profile, workflow_id)
	end

	if (svc["Operations"]["Authorize"]) then
		puts "","","Begin Authorize with WorkflowId: #{workflow_id}"
		puts "Result:",
		capture_selective_txn=ipc_instance.authorize(txndata,profile, workflow_id)
	end
	
	if (svc["Operations"]["Authorize"] and  !capture_selective_txn.nil?) then
		payment_token=capture_selective_txn["PaymentAccountDataToken"]
		txndata_tokenized=txndata.clone
		txndata_tokenized['CardData']=nil
		txndata_tokenized['PaymentAccountDataToken']=payment_token
		
		
		puts "","","Begin Tokenized Authorize with WorkflowId: #{workflow_id} templating from previous transaction."
		puts "Result:",
		tokenized_txn=ipc_instance.authorize(txndata_tokenized, profile, workflow_id)
	end
	
	if (svc["Operations"]["Capture"] and !basic_txn.nil?) then
		puts "","","Begin Capture with WorkflowId: #{workflow_id}"
		puts "Result:",
		captured_txn=ipc_instance.capture(basic_txn,{Amount: "20.00"},  profile, workflow_id)
	end
	
	if (svc["Operations"]["Capture"] and !tokenized_txn.nil?) then
		puts "","","Begin Tokenized Capture with WorkflowId: #{workflow_id}"
		puts "Result:",
		captured_txn_to_return=ipc_instance.capture(tokenized_txn,{Amount: "20.00"},  profile, workflow_id)
	end
	
	if (svc["Operations"]["CaptureSelective"] and !capture_selective_txn.nil?) then
		puts "","","Begin Capture Selective with WorkflowId: #{workflow_id}"
		puts "Result:",
		captured_txns=ipc_instance.capture_selective(profile, workflow_id, [capture_selective_txn["TransactionId"]])
		captured_txn_to_return=capture_selective_txn
	end
	
	if (svc["Operations"]["CaptureAll"] and !basic_txn.nil? and svc["Tenders"]["BatchAssignmentSupport"] != 3) then
		puts "","","Begin Capture All with WorkflowId: #{workflow_id}"
		puts "Result:",
		captured_txns=ipc_instance.capture_all(profile, workflow_id)
	end
	
	if (svc["Operations"]["ReturnById"] and !captured_txn_to_return.nil?) then
		puts "","","Begin ReturnById with WorkflowId: #{workflow_id}"
		puts "Result:",
		ipc_instance.return_by_id(captured_txn_to_return,{Amount:"5.00"},  profile, workflow_id)
	end
=end

	
}
puts "","","Completed Test."
