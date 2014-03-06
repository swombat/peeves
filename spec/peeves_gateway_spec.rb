require './spec/spec_helper'

describe PeevesGateway do

  before(:each) do
    @p = PeevesGateway.new(:simulator)
    @p.debug = false
  end
  
  describe "sending a payment request" do
    before(:each) do
      customer_data = Peeves::CustomerData.new(:surname	=> 'blah',
                                               :firstnames => 'blah',
                                               :address1 => 'blah',
                                               :address2 => 'blah',
                                               :city => 'blah',
                                               :post_code => 'blah',
                                               :country => 'gb'
                                              )

      @response = @p.payment(Peeves::Money.new(1000, "GBP"),
                    {
                      :transaction_reference => Peeves::UniqueId.generate("TEST"),
                      :description           => "Test Transaction",
                      :notification_url      => "http://test.example.com",
                      :customer_data         => {:billing => customer_data, :delivery =>customer_data} ,
                    })
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

  # commented out
  # AUTHORISE can only be used after AUTHENTICATE, not PAYMENT
#  describe "sending an authenticate request" do
#    before(:each) do
#      pending
#      @transaction_reference = Peeves::UniqueId.generate("TEST")
#      @response = @p.authenticate Peeves::Money.new(1000, "GBP"),
#        {
#          :transaction_reference => @transaction_reference,
#          :description => "Test Transaction",
#          :notification_url => "http://test.example.com"
#        }
#    end
#
#    it "should return a ProtxResponse" do
#      @response.is_a?(Peeves::ProtxResponse).should be_true
#    end
#
#    it "should have a vps_transaction_id" do
#      @response.vps_transaction_id.should_not be_nil
#    end
#
#    it "should have a security_key" do
#      @response.security_key.should_not be_nil
#    end
#
#    it "should not have a transaction_authorisation_number" do
#      @response.transaction_authorisation_number.should be_nil
#    end
#
#    it "should be cancellable" do
#      @response2 = @p.cancel({
#        :transaction_reference => @transaction_reference,
#        :vps_transaction_id => @response.vps_transaction_id,
#        :security_key => @response.security_key
#      })
#      @response2.status.should == PeevesGateway::APPROVED
#    end
#  end

  describe "receiving a notification" do
    before(:each) do
      params = {
        "Status"=>"OK", 
        "TxType"=>"PAYMENT", 
        "VPSTxId"=>"{861A2DB0-E734-4DEB-8F8B-12C47B9ADF3E}", 
        "VendorTxCode"=>"W-TEST-1227524828.86576-59414", 
        "GiftAid"=>"0", 
        "AVSCV2"=>"ALL MATCH", 
        "TxAuthNo"=>"8661", 
        "VPSProtocol"=>"2.22", 
        "CAVV"=>"MNL2CYF4URE47IQNBI6DAH", 
        "3DSecureStatus"=>"OK", 
        "VPSSignature"=>"49A6FA9FE0631919D9B1E72ACE57584D", 
        "CV2Result"=>"MATCHED", 
        "PostCodeResult"=>"MATCHED", 
        "AddressResult"=>"MATCHED"
      }
      @result = PeevesGateway.parse_notification(params)
    end

    it "should be able to parse the notification into a ProtX Response" do
      @result.is_a?(Peeves::ProtxResponse).should be_true
    end
  end

end
