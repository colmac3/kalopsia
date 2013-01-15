shared_examples_for "a gateway" do
  def run_txn(options = {})
    options[:wiredump] = true if @txn[:wiredump]
    pp @txn if @txn[:verbose] || ENV['VERBOSE']
    gateway = subject.class.new(options.delete(:wiredump))
    gateway.process(@txn.merge(options), @txn.merge(options)[:merchant_id], @txn.merge(options)[:merchant_key])
  end

  let(:__defaults) do
    {
      :itid => '111',
      :action => 'sale' ,
      :card_pan => '4111111111111111',
      :card_iso2_track => "4111111111111111=2709",
      :reference_code => '',
      :card_expiry_date => 1.year.from_now,
      :ton => Time.new.usec.to_s,
      :customer_number => "",
      :merchant_id => "merchant id",
      :merchant_key => "merchant key"
    }.with_indifferent_access
  end

  class << self
    def defaults
      let(:txn_defaults) { __defaults.dup.tap { |defs| yield defs } }
    end
  end
  
  before(:each) { @txn = txn_defaults }

  context "with a debit card" do
    before(:each) do
      @txn[:card_mode] = 'debit'
    end
    
    context "for $1.00" do
      before(:each) {
        @txn[:amount] = 100
        @txn[:cash_back_amt] = 200
        @txn[:tax] = 1
      }

      context "without a PIN" do
        it "should not be approved" do
          @txn[:card_input_type] = :swiped
          run_txn(:wiredump => true)[:state].should_not == :approved
        end
      end

      context "with a PIN" do
        before(:each) do
          @txn[:card_input_type] = :swiped
          @txn[:card_pin_block] = '81dc9bdb52d04dc20036dbd8313ed055'
        end
        
        it "should be approved" do
          run_txn[:state].should == :approved
        end
      end
    end
  end
  
  context "with a credit card" do
    before(:each) do
      @txn[:action] = 'sale'
      @txn[:card_mode] = 'credit'
    end

    context "manually entered" do
      before(:each) do
        @txn.delete :card_iso2_track
        @txn[:card_input_type]=:keyed
      end
      context "without an amount" do
        it "should decline the txn" do
          txn = run_txn
          txn[:state].should == :declined
        end
      end

      context "with an amount of $1.00" do
        before(:each) do
          @txn[:amount] = 100
        end

        it "should approve the txn" do
          txn = run_txn()
          txn[:state].should == :approved
        end

        it "should not include original card data" do
          txn = run_txn
          txn.keys.should_not include(:card_pan)
          txn.keys.should_not include(:card_iso2_track)
          txn.keys.should_not include(:card_expiry_date)
        end
      end
    end

    context "swiped" do
      before(:each) do
        @txn[:card_input_type] = :swiped
      end

      context "#sale" do
        context "without an amount" do
          it "should decline the txn" do
            txn = run_txn
            txn[:state].should == :declined
          end
        end

       context "with bad merchant ID" do
          it "raise an error" do
            @txn[:amount] = 100

            proc { Sage::Gateway.new(false).process(@txn, "GGG", "555") }.should raise_error(Errors::BadCredentials)
          end
        end

        context "with an amount of $1.00" do
          before(:each) do
            @txn[:amount] = 100
          end

          it "should approve the txn" do
            txn = run_txn
            txn[:state].should == :approved
          end

          it "should not include original card data" do
            txn = run_txn
            txn.keys.should_not include(:card_pan)
            txn.keys.should_not include(:card_iso2_track)
            txn.keys.should_not include(:card_expiry_date)
          end
        end
      end

      context "#debit" do
        context "without an amount" do
          it "should decline the txn" do
            txn = run_txn
            txn[:state].should == :declined
          end
        end

        context "with an amount of $1.00" do
          before(:each) do
            @txn[:amount] = 100
            @txn[:card_pin_block] = '81dc9bdb52d04dc20036dbd8313ed055'
            @txn[:card_mode] = 'debit'
          end

          it "should approve the txn" do
            txn = run_txn
            txn[:state].should == :approved
          end

          it "should not include original card data" do
            txn = run_txn
            txn.keys.should_not include(:card_pan)
            txn.keys.should_not include(:card_iso2_track)
            txn.keys.should_not include(:card_expiry_date)
          end
        end
      end



      context "#pre_auth" do
        before(:each) do
          @txn[:action] = 'pre_auth'
          @txn[:amount] = 100
        end

        it "should approve the txn" do
          txn = run_txn
          txn[:state].should == :approved
        end
      end

      context "#sale_return" do
        before(:each) do
          @txn[:action] = 'sale_return'
        end

        context "with an amount of $1.00" do
          before(:each) { @txn[:amount] = 100 }

          it "should approve the txn" do
            txn = run_txn
            txn[:state].should == :approved
          end
        end
      end


      it "#post_pre_auth" do
        @txn[:action] = 'pre_auth'
        @txn[:amount] = 100
        @txn[:shipping] = ""
        @txn[:auth_code] = ""
        resp = run_txn()
        resp[:state].should == :approved

        @txn[:action] = 'post_pre_auth'
        @txn[:reference] = resp[:reference_code]
        @txn[:amount] = 100
        #@txn[:tax] = nil
        resp = run_txn()

        #resp[:post_pre_auth_array][0][:APPROVAL_INDICATOR].should == 'A'
        resp[:state].should == :approved
      end

      it "#force_sale" do
        @txn[:amount] = 100
        @txn[:action] = 'force_sale'
        @txn[:force_auth_code] = '123456'

        resp = run_txn()
        resp[:state].should == :approved
      end

      it "#void" do
        @txn[:action] = 'sale'
        @txn[:amount] = 100
        resp = run_txn()
        resp[:state].should == :approved

        @txn[:action] = 'void'
        @txn[:reference_code] = resp[:reference_code]
        @txn[:amount] = 110
        @txn[:tax] = 10
        resp = run_txn()

        resp[:state].should == :approved
      end
    end # context swiped
  end # context with a credit card

  it "#void_by_ton" do
    @txn[:card_input_type] = :keyed
    @txn[:action] = 'sale'
    @txn[:card_mode] = 'credit'
    @txn[:amount] = 100
    resp = run_txn()
    resp[:state].should == :approved

    @txn[:action] = 'void_by_ton'
    @txn[:ton] = resp[:ton]
    @txn[:amount] = 100
    resp = run_txn()
    #pending "Fix from Sage"
    resp[:state].should == :approved
  end

  it "#settlement" do
    # Note, this will fail if there is no open batch. I think the only way to reliably make this pass will be to
    # mock up the server responses -- and I don't have time to do that right now.

    @txn[:action] = "settlement"
    txn = run_txn
    txn[:message].should =~ /BATCH (\d+) OF (\d+) CLOSED/
  end

  it "#batch_inquiry" do
    @txn[:action] = 'batch_inquiry'
    txn = run_txn
    txn[:message].strip.should == "BATCH INQUIRY" or txn[:message].strip.should == "NO TRANSACTIONS"
  end
  
  it "#view_settled" do
    @txn[:action] = "view_settled"
    @txn[:start_date] = 10.days.ago.to_s
    @txn[:end_date] = Time.now.to_s
    
    txn = run_txn
    txn.length.should_not == 0
  end
end
