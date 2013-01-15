require 'vantiv/ipcommerce'

puts "See source for links to documentation"

puts "","########   Preparing the application to Transact ########",""
# https://my.ipcommerce.com/Docs/1.17.16/CWS_REST_Developer_Guide/RESTImplementation/PreparingTheAppToTransact/index.aspx

puts "","********   Step 1 - Sign On Authentication   **********",""
# https://my.ipcommerce.com/Docs/1.17.16/CWS_REST_Developer_Guide/RESTImplementation/PreparingTheAppToTransact/SignOnAuthentication/index.aspx

#This, along with other class variables is stored in config.dat,
#whenever the session is renewed.
identity_token="PHNhbWw6QXNzZXJ0aW9uIE1ham9yVmVyc2lvbj0iMSIgTWlub3JWZXJzaW9uPSIxIiBBc3NlcnRpb25JRD0iXzkyMmY1YTMyLWY0ZjUtNDNmMS1hZTc3LWUyOWU2YWVkMTlkYiIgSXNzdWVyPSJJcGNBdXRoZW50aWNhdGlvbiIgSXNzdWVJbnN0YW50PSIyMDExLTExLTEyVDAwOjE1OjQ3LjQ1OFoiIHhtbG5zOnNhbWw9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjEuMDphc3NlcnRpb24iPjxzYW1sOkNvbmRpdGlvbnMgTm90QmVmb3JlPSIyMDExLTExLTEyVDAwOjE1OjQ3LjQ1OFoiIE5vdE9uT3JBZnRlcj0iMjAxNC0xMS0xMlQwMDoxNTo0Ny40NThaIj48L3NhbWw6Q29uZGl0aW9ucz48c2FtbDpBZHZpY2U+PC9zYW1sOkFkdmljZT48c2FtbDpBdHRyaWJ1dGVTdGF0ZW1lbnQ+PHNhbWw6U3ViamVjdD48c2FtbDpOYW1lSWRlbnRpZmllcj5FNjY1NjUxOTU3MzAwMDAxPC9zYW1sOk5hbWVJZGVudGlmaWVyPjwvc2FtbDpTdWJqZWN0PjxzYW1sOkF0dHJpYnV0ZSBBdHRyaWJ1dGVOYW1lPSJTQUsiIEF0dHJpYnV0ZU5hbWVzcGFjZT0iaHR0cDovL3NjaGVtYXMuaXBjb21tZXJjZS5jb20vSWRlbnRpdHkiPjxzYW1sOkF0dHJpYnV0ZVZhbHVlPkU2NjU2NTE5NTczMDAwMDE8L3NhbWw6QXR0cmlidXRlVmFsdWU+PC9zYW1sOkF0dHJpYnV0ZT48c2FtbDpBdHRyaWJ1dGUgQXR0cmlidXRlTmFtZT0iU2VyaWFsIiBBdHRyaWJ1dGVOYW1lc3BhY2U9Imh0dHA6Ly9zY2hlbWFzLmlwY29tbWVyY2UuY29tL0lkZW50aXR5Ij48c2FtbDpBdHRyaWJ1dGVWYWx1ZT44ZGZjM2ZjNy0yMzllLTRkNmQtOWEzMC05NzYzZDY3Nzc5ODQ8L3NhbWw6QXR0cmlidXRlVmFsdWU+PC9zYW1sOkF0dHJpYnV0ZT48c2FtbDpBdHRyaWJ1dGUgQXR0cmlidXRlTmFtZT0ibmFtZSIgQXR0cmlidXRlTmFtZXNwYWNlPSJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcyI+PHNhbWw6QXR0cmlidXRlVmFsdWU+RTY2NTY1MTk1NzMwMDAwMTwvc2FtbDpBdHRyaWJ1dGVWYWx1ZT48L3NhbWw6QXR0cmlidXRlPjwvc2FtbDpBdHRyaWJ1dGVTdGF0ZW1lbnQ+PFNpZ25hdHVyZSB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyI+PFNpZ25lZEluZm8+PENhbm9uaWNhbGl6YXRpb25NZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzEwL3htbC1leGMtYzE0biMiPjwvQ2Fub25pY2FsaXphdGlvbk1ldGhvZD48U2lnbmF0dXJlTWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnI3JzYS1zaGExIj48L1NpZ25hdHVyZU1ldGhvZD48UmVmZXJlbmNlIFVSST0iI185MjJmNWEzMi1mNGY1LTQzZjEtYWU3Ny1lMjllNmFlZDE5ZGIiPjxUcmFuc2Zvcm1zPjxUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjZW52ZWxvcGVkLXNpZ25hdHVyZSI+PC9UcmFuc2Zvcm0+PFRyYW5zZm9ybSBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMTAveG1sLWV4Yy1jMTRuIyI+PC9UcmFuc2Zvcm0+PC9UcmFuc2Zvcm1zPjxEaWdlc3RNZXRob2QgQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjc2hhMSI+PC9EaWdlc3RNZXRob2Q+PERpZ2VzdFZhbHVlPklaSStVV2tySjVRcUFBdjMwRjFNeHhHcHAzOD08L0RpZ2VzdFZhbHVlPjwvUmVmZXJlbmNlPjwvU2lnbmVkSW5mbz48U2lnbmF0dXJlVmFsdWU+cE9Wdll6NVVhY2hKNFNRRnpYckgwNkZ4VHJjOTNhUWhRU2pacWgyMU9Ic2lTTnYvUFVyaEQvNDJuSStaaDAyR0NOQUVXNDFUS0pJd05qRHBOU2p5TGZreks4QVNOZWhya2ZTbVRWaEZZcTBZcWkwVklDcEZ6ZTg4YThMQmVlRDRBK2k1MkVVT3dRaDcrMi9PZVY4TXl3ZWVGd3VZd3BDbm9KMHN0RDZqekU4TWp6L2J1emNUK3QzLzJuQk9PMm16Y1hTazRsdTc2WlpRSnhScmFQSVo5WnVlSEZZbGJPTlczR1lZbU1XWFVVUEw0N2pRZHFiQWtnbHk1ZlRGOS9SQzdPbTBYU01XMUxzQ2kvdDdwZ0EwUm8zcHg5NFdiMk5seXlYUy9xcGRYNDFLK3d4Z0FZRGFSL1c0NTBIQVB6ZHhKSkMxUGRaNGJ6OFVnYm5ETjJPbXp3PT08L1NpZ25hdHVyZVZhbHVlPjxLZXlJbmZvPjxvOlNlY3VyaXR5VG9rZW5SZWZlcmVuY2UgeG1sbnM6bz0iaHR0cDovL2RvY3Mub2FzaXMtb3Blbi5vcmcvd3NzLzIwMDQvMDEvb2FzaXMtMjAwNDAxLXdzcy13c3NlY3VyaXR5LXNlY2V4dC0xLjAueHNkIj48bzpLZXlJZGVudGlmaWVyIFZhbHVlVHlwZT0iaHR0cDovL2RvY3Mub2FzaXMtb3Blbi5vcmcvd3NzL29hc2lzLXdzcy1zb2FwLW1lc3NhZ2Utc2VjdXJpdHktMS4xI1RodW1icHJpbnRTSEExIj4xK0xuclBRVHNvOFE5SElpSkFGR2xpS2VvUkU9PC9vOktleUlkZW50aWZpZXI+PC9vOlNlY3VyaXR5VG9rZW5SZWZlcmVuY2U+PC9LZXlJbmZvPjwvU2lnbmF0dXJlPjwvc2FtbDpBc3NlcnRpb24+";
ipc_instance=Ipcommerce.new({:identity_token => identity_token})


# -- Load from a previously saved application profile
# puts "Loading application_id and token from saved state in config.dat..."
# ipc_instance.load
# -- Or do Step 2 Below.


puts "","********   Step 2 - Managing Application Configuration Data  **********",""
# https://my.ipcommerce.com/Docs/1.17.16/CWS_REST_Developer_Guide/RESTImplementation/PreparingTheAppToTransact/ManagingAppConfigData/index.aspx



#The PTLS Id is used to uniquely identify an application.
my_PTLS="MIIEwjCCA6qgAwIBAgIBEjANBgkqhkiG9w0BAQUFADCBsTE0MDIGA1UEAxMrSVAgUGF5bWVudHMgRnJhbWV3b3JrIENlcnRpZmljYXRlIEF1dGhvcml0eTELMAkGA1UEBhMCVVMxETAPBgNVBAgTCENvbG9yYWRvMQ8wDQYDVQQHEwZEZW52ZXIxGjAYBgNVBAoTEUlQIENvbW1lcmNlLCBJbmMuMSwwKgYJKoZIhvcNAQkBFh1hZG1pbkBpcHBheW1lbnRzZnJhbWV3b3JrLmNvbTAeFw0wNjEyMTUxNzQyNDVaFw0xNjEyMTIxNzQyNDVaMIHAMQswCQYDVQQGEwJVUzERMA8GA1UECBMIQ29sb3JhZG8xDzANBgNVBAcTBkRlbnZlcjEeMBwGA1UEChMVSVAgUGF5bWVudHMgRnJhbWV3b3JrMT0wOwYDVQQDEzRFcWJwR0crZi8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vL0E9MS4wLAYJKoZIhvcNAQkBFh9zdXBwb3J0QGlwcGF5bWVudHNmcmFtZXdvcmsuY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQD7BTLqXah9t6g4W2pJUfFKxJj/R+c1Dt5MCMYGKeJCMvimAJOoFQx6Cg/OO12gSSipAy1eumAqClxxpR6QRqO3iv9HUoREq+xIvORxm5FMVLcOv/oV53JctN2fwU2xMLqnconD0+7LJYZ+JT4z3hY0mn+4SFQ3tB753nqc5ZRuqQIDAQABo4IBVjCCAVIwCQYDVR0TBAIwADAdBgNVHQ4EFgQUk7zYAajw24mLvtPv7KnMOzdsJuEwgeYGA1UdIwSB3jCB24AU3+ASnJQimuunAZqQDgNcnO2HuHShgbekgbQwgbExNDAyBgNVBAMTK0lQIFBheW1lbnRzIEZyYW1ld29yayBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkxCzAJBgNVBAYTAlVTMREwDwYDVQQIEwhDb2xvcmFkbzEPMA0GA1UEBxMGRGVudmVyMRowGAYDVQQKExFJUCBDb21tZXJjZSwgSW5jLjEsMCoGCSqGSIb3DQEJARYdYWRtaW5AaXBwYXltZW50c2ZyYW1ld29yay5jb22CCQD/yDY5hYVsVzA9BglghkgBhvhCAQQEMBYuaHR0cHM6Ly93d3cuaXBwYXltZW50c2ZyYW1ld29yay5jb20vY2EtY3JsLnBlbTANBgkqhkiG9w0BAQUFAAOCAQEAFk/WbEleeGurR+FE4p2TiSYHMau+e2Tgi+L/oNgIDyvAatgosk0TdSndvtf9YKjCZEaDdvWmWyEMfirb5mtlNnbZz6hNpYoha4Y4ThrEcCsVhfHLLhGZZ1YaBD+ZzCQA7vtb0v5aQb25jX262yPVshO+62DPxnMiJevSGFUTjnNisVniX23NVouUwR3n12GO8wvzXF8IYb5yogaUcVzsTIxEFQXEo1PhQF7JavEnDksVnLoRf897HwBqcdSs0o2Fpc/GN1dgANkfIBfm8E9xpy7k1O4MuaDRqq5XR/4EomD8BWQepfJY0fg8zkCfkuPeGjKkDCitVd3bhjfLSgTvDg=="
appdata={
	:ApplicationAttended => 'false',
	:ApplicationLocation => 4,
	:ApplicationName => 'TestApp',
	:HardwareType => 2,
	:PINCapability => 3,
	:PTLSSocketId => my_PTLS,
	:ReadCapability => 2,
	:SerialNumber => 12345,
	:SoftwareVersion => 1,
	:SoftwareVersionDate => Time.now #Can be a Time, Integer, or Json \/Date(integer+)\/ string
}
puts "","Save Application Data ...","Result:",
app_id=ipc_instance.save_application_data(appdata);


puts "","Get Application Data ...","Result:",
ipc_instance.get_application_data(app_id);

# -- You may
# ipc_instance.delete_application_data(app_id);
#
# This will yield a warning if the current application profile is given.
# pass with (app_id, true) to skip that check.


puts "","********   Step 3 - Retreiving Service Information  **********",""
# https://my.ipcommerce.com/Docs/1.17.15/CWS_REST_Developer_Guide/RESTImplementation/PreparingTheAppToTransact/RetrievingServiceInformation.aspx

puts "","Get Service Information...","Result:"

workflows=ipc_instance.get_service_information()

puts bankcard_services=workflows["BankcardServices"];

services_list=bankcard_services.collect() { |svc|
  ipc_instance.service_name(svc["ServiceId"])+" (#{svc["ServiceId"]})"
}

puts "#{services_list.length} Service(s) returned: #{services_list.join(',')}",""



red_services=workflows["Workflows"]

services_list=red_services.collect() { |svc|
  "#{svc["ServiceId"]}\n- [#{svc["WorkflowId"]}] #{svc["Name"]}"
}

if (services_list.length >= 1) then
  puts "The following service(s) have WorkflowId(s):", "#{services_list.join("\n")}"
end
#puts "Result:",services

puts "","********   Step 4 - Managing Merchant Profiles **********",""
# https://my.ipcommerce.com/Docs/1.17.15/CWS_REST_Developer_Guide/RESTImplementation/PreparingTheAppToTransact/ManagingMerchantProfiles/index.aspx

# Can be used to reset merchant profiles
#
#workflow_ids.each {|svc|
#	merchant_profiles=ipc_instance.get_merchant_profile(nil,default_workflow_id)
#	merchant_profiles.each{|profile|
#		ipc_instance.delete_merchant_profile(profile["id"])
#		
#	}
#}

bankcard_services.each {|svc|
	
	# autotest_profile="Merchant_"+svc["ServiceId"]

  autotest_profile="IngenicoTest"
	
	puts "","Is Merchant Profile Initialized: #{autotest_profile} ...","Result:",
	initialized=ipc_instance.is_merchant_profile_initialized(autotest_profile, svc["ServiceId"])
	if (!initialized) then
	
		merchant_profile={:ProfileId => autotest_profile,
                      :WorkflowId => svc["ServiceId"],
                      :ServiceName => svc["ServiceName"],
                      :LastUpdated => Time.now,
                      :MerchantData => {
                                         :CustomerServiceInternet => "",
                                         :CustomerServicePhone => "303 3333333",
                                         :Language => 127,
                                         :Address => {
                                                       :Street1 => "777 Cherry Street",
                                                       :Street2 => "",
                                                       :City => "Denver",
                                                       :StateProvince => 7,
                                                       :PostalCode => "80220",
                                                       :CountryCode => 234
                                                     },#Address
                                         :MerchantId => "123456789012",
                                         :Name => "ABCTest",
                                         :Phone => "303 3333333",
                                         :TaxId => "",
                                         :BankcardMerchantData => {
                                                                    :ABANumber => "1234",
                                                                    :AcquirerBIN => "123456",
                                                                    :AgentBank => "123456",
                                                                    :AgentChain => "123456",
                                                                    :Aggregator => false,
                                                                    :ClientNumber => "1224",
                                                                    :IndustryType => 4,
                                                                    :Location => "001",
                                                                    :MerchantType => "",
                                                                    :PrintCustomerServicePhone => false,
                                                                    :QualificationCodes => "",
                                                                    :ReimbursementAttribute => "1",
                                                                    :SIC => "1234",
                                                                    :SecondaryTerminalId => "12345678",
                                                                    :SettlementAgent => "1234",
                                                                    :SharingGroup => "1234",
                                                                    :StoreId => "1234",
                                                                    :TerminalId => "1234",
                                                                    :TimeZoneDifferential => "123"
                                                                  }, #BankcardMerchantData
                                         :ElectronicCheckingMerchantData => {
                                                                              :OrginatorId => "",
                                                                              :ProductId => "",
                                                                              :SiteId => ""
                                                                            } #ElectronicCheckingMerchantData
                                    },#MerchantData
                      :TransactionData => {
                                          :BankcardTransactionDataDefaults => {
                                                                                :CurrencyCode => 4,
                                                                                :CustomerPresent => 1,
                                                                                :EntryMode => 1,
                                                                                :RequestACI => 2,
                                                                                :RequestAdvice => 2
                                                                              } #BankcardTransastionDataDefaults
                                          } #TransactionData
                      }#merchant_profile

		puts "","Save Merchant Profile: #{autotest_profile} ...","Result:",
		ipc_instance.save_merchant_profile(merchant_profile, svc["ServiceId"]);
	end
	
	puts "","Get Merchant Profile: #{autotest_profile} ...","Result:",
	ipc_instance.get_merchant_profile(autotest_profile, svc["ServiceId"])
}


#sure we made sure TestProfile exists, but we will use the first returned.



puts "","########   Ready to Transact ########",""
