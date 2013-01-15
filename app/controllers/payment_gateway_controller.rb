class PaymentGatewayController < ApplicationController
  protect_from_forgery :except => [:authorize, :query_log, :log_message]

  def log_message
    log = TransactionLog.create(params)
    render :xml => log
  end

  def ping
   respond_to do |fmt|
     fmt.xml { render :xml  => {:message => "running"} }
     fmt.html {render :text => "running"}
   end

  end


  def query_log
    if (params[:id])
      log = TransactionLog.find(params[:id])
    else
      log = TransactionLog.all
    end
    render :xml => log
  end

# URL to test kalopsai to sage.
#http://localhost:3000/payment_gateway/authorize?amount=100&auth_code=&c_address=&c_zip=&card_expiry_date=Sat+Dec+01+05%3A00%3A00+UTC+2012&card_input_type=swiped&card_iso2_track=371449635392376%3D1212030765713&card_mode=credit&card_pan=371449635392376&card_pin_block=&cash_back_amt=0&invoice_num=&merchant_id=869440795604&merchant_key=Y7Q7Q7C7G7A7&processor=sage&shipping=&tax=0&ton=3262&txn_type=sale


#test_rename merchant_id = 869440795604
#test_rename merchant_key = 'Y7Q7Q7C7G7A7'

  def authorize()
    merchant_id = params[:merchant_id]
    merchant_key = params[:merchant_key]
    
    # Rails prefills params[:action] with 'authorize' (the name of this action). So we'll use :txn_type instead.
    params[:action] = params[:txn_type] if params[:txn_type]

    @txn = params.inject({}) do |hash, (key,value)|
      # Attempt to convert string value into a Ruby object. If that fails, just use the string value.
      # Bugfix: Empty strings are loaded in YAML as boolean false. This causes errors. We'll just use nil instead.
      if key.to_s == 'reference_code' or key.to_s == 'itid'
        hash[key] = value
      else
        hash[key] = value.blank? ? nil : (YAML::load(value) rescue value)
      end

      hash
    end
    @txn = @txn.with_indifferent_access
    Rails.logger.debug "Receive transaction: #{filter_parameters(@txn).to_query}"

    log = TransactionLog.create(:processor => params[:processor],
                                :action => params[:action],
                                :merchant_id => params[:merchant_id],
                                :merchant_key => params[:merchant_key],
                                :transaction => filter_parameters(@txn).with_indifferent_access.merge(
                                    :merchant_id => @txn[:merchant_id]
                                )
    )
    
    # if params[:wiredump] is true, all data transmitted and received will be logged.
    @resp = "#{params[:processor]}/gateway".camelize.constantize.new(params.delete(:wiredump)).process(@txn, merchant_id, merchant_key)
    Rails.logger.debug "Response object: #{@resp.inspect}"
    log.result = @resp
    log.save

    respond_to do |fmt|
      fmt.xml  { render :xml =>  @resp.to_xml  }
      fmt.json { render :json => @resp.to_json }
      fmt.yaml { render :text => @resp.to_yaml }
      fmt.html
    end
  rescue
    Rails.logger.error "#{$!.class}: #{$!.message}"
    Rails.logger.error $!.backtrace.join("\n")

    err = { 'error' => $!.message, 'backtrace' => $!.backtrace.join("\n") }
    if (log)
      log.result = err
      log.save
    end

    respond_to do |fmt|
      fmt.xml  { render :xml  => err.to_xml,  :status => 500 }
      fmt.json { render :json => err.to_json, :status => 500 }
      fmt.yaml { render :yaml => err.to_yaml, :status => 500 }
      fmt.html { raise $! }
    end
  end
end
