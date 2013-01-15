require 'spec_helper'

describe PaymentGatewayController do
  context "#sage" do
    before(:each) do
      @params = {
        :processor => 'sage',
        :merchant_id => $mid,
        :merchant_key => $mkey
      }
    end
    
    it "should not alter the itid" do
      @params[:itid] = "010010"
      get :authorize, @params
      response.template.controller.instance_variable_get("@txn")[:itid].to_s.should == "010010"
    end
    
    context "card" do
      before(:each) do
        @params.merge!({
          :txn_type => 'sale' ,
          :card_pan => '4111111111111111',
          :card_iso2_track => "4111111111111111=2709",
          :amount => 100,
          :reference_code => '',
          :card_mode => "credit",
          :card_expiry_date => 1.year.from_now,
          :ton => '12345678',
          #:wiredump => true,
        })
      end

      context "with an empty card mode" do
        it "should raise an error" do
          @params[:card_mode] = ''
          get :authorize, @params
          response.code.should == '500'
        end
      end
    
      it "should run a $1.00 credit sale without croaking" do
        get :authorize, @params
      end


      it "should create a log message" do
        get :authorize, @params.merge(:card_input_type => 'swiped')
        TransactionLog.count.should == 1
      end

      it "should have a result" do
        get :authorize, @params.merge(:card_input_type => 'swiped')
        puts TransactionLog.all.to_xml
        TransactionLog.last.result.should_not be_nil
      end

    end
    
    it "#view_settled" do
      @params[:txn_type] = "view_settled"
      @params[:start_date] = 10.days.ago.to_s
      @params[:end_date] = Time.now.to_s
      
      get :authorize, @params
      if err = response.template.controller.instance_variable_get("@exception")
        raise err
      end
      response.code.should == '200'
    end
    
    it '#view_open' do
      @params[:txn_type] = "view_open"
      @params[:start_date] = 10.days.ago.to_s
      @params[:end_date] = Time.now.to_s
      @params[:wiredump] = true
      
      get :authorize, @params
      if err = response.template.controller.instance_variable_get("@exception")
        raise err
      end
      puts response.body
      response.code.should == '200'
    end
  end
end
