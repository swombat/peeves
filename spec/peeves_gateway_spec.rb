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
    
    it "should be a TransactionRegistrationResponse" do
      @response.is_a?(Peeves::TransactionRegistrationResponse).should be_true
    end
  end
  
  describe "sending a void request" do
    it "should description" do
      
    end
  end

end