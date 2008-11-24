require 'spec/spec_helper'

describe PeevesGateway do

  before(:each) do
    @p = PeevesGateway.new(:simulator)
    @p.debug = false
  end
  
  describe "sending a payment request" do
    before(:each) do
      @response = @p.payment Peeves::Money.new(1000, "GBP"),
        {
          :transaction_reference => Peeves::UniqueId.generate("TEST"),
          :description => "Test Transaction",
          :notification_url => "http://test.example.com"
        }
    end
    
    it "should return a ProtxResponse" do
      @response.is_a?(Peeves::ProtxResponse).should be_true
    end
    
    it "should have a vps_transaction_id" do
      @response.vps_transaction_id.should_not be_nil
    end

    it "should have a security_key" do
      @response.security_key.should_not be_nil
    end
    
    it "should not have a transaction_authorisation_number" do
      @response.transaction_authorisation_number.should be_nil
    end
  end
  
  describe "sending an authenticate request" do
    before(:each) do
      @transaction_reference = Peeves::UniqueId.generate("TEST")
      @response = @p.authenticate Peeves::Money.new(1000, "GBP"),
        {
          :transaction_reference => @transaction_reference,
          :description => "Test Transaction",
          :notification_url => "http://test.example.com"
        }
    end

    it "should return a ProtxResponse" do
      @response.is_a?(Peeves::ProtxResponse).should be_true
    end

    it "should have a vps_transaction_id" do
      @response.vps_transaction_id.should_not be_nil
    end

    it "should have a security_key" do
      @response.security_key.should_not be_nil
    end

    it "should not have a transaction_authorisation_number" do
      @response.transaction_authorisation_number.should be_nil
    end
    
    it "should be cancellable" do
      @response2 = @p.cancel({
        :transaction_reference => @transaction_reference,
        :vps_transaction_id => @response.vps_transaction_id,
        :security_key => @response.security_key
      })
      @response2.status.should == PeevesGateway::APPROVED
    end
  end

end