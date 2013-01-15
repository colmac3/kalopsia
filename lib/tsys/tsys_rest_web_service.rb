require 'nokogiri'
require 'rest_client'


=begin
      <Merchant_ID>888800000087</Merchant_ID>
      <Device_ID>88880000008701</Device_ID>
      <Operator>TA32150</Operator>
      <Password>001ToFly!</Password>
=end
class TsysRestWebService
  attr_accessor :tsys_rest_request_uri, :merc_id, :txn, :device_id, :operator, :password

  def initialize()
    @tsys_rest_request_uri = "https://stagegw.transnox.com/servlets/TransNox_API_Server"
  end


  def credit_sale()
    body = File.read(File.expand_path("tsys_retail_sale.xml.erb", File.dirname(__FILE__)))
    erb = ERB.new(body).result(binding)
    response = RestClient.post @tsys_rest_request_uri, erb, {:content_type => 'text/xml'}
    response_hash = Hash.from_xml(response)
  end  # credit_sale

  def  credit_void_by_reference_code()
    body = File.read(File.expand_path("tsys_retail_void.xml.erb", File.dirname(__FILE__)))
    erb = ERB.new(body).result(binding)
    response = RestClient.post @tsys_rest_request_uri, erb, {:content_type => 'text/xml'}
    response_hash = Hash.from_xml(response)
  end


end #TsysRestWebService