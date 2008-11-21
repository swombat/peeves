class Peeves
  
  TEST_URL = 'https://ukvpstest.protx.com/vspgateway/service'
  LIVE_URL = 'https://ukvps.protx.com/vspgateway/service'
  SIMULATOR_URL = 'https://ukvpstest.protx.com/VSPSimulator'

  APPROVED = 'OK'
  
  TRANSACTIONS = {
    :purchase => 'PAYMENT',
    :credit => 'REFUND',
    :authorization => 'DEFERRED',
    :capture => 'RELEASE',
    :repeat => 'REPEAT',
    :void => 'VOID'
  }
  
  CREDIT_CARDS = {
    :visa => "VISA",
    :master => "MC",
    :delta => "DELTA",
    :solo => "SOLO",
    :switch => "MAESTRO",
    :maestro => "MAESTRO",
    :american_express => "AMEX",
    :electron => "UKE",
    :diners_club => "DC",
    :jcb => "JCB"
  }
  
  ELECTRON = /^(424519|42496[23]|450875|48440[6-8]|4844[1-5][1-5]|4917[3-5][0-9]|491880)\d{10}(\d{3})?$/
  
  AVS_CVV_CODE = {
    "NOTPROVIDED" => nil, 
    "NOTCHECKED" => 'X',
    "MATCHED" => 'Y',
    "NOTMATCHED" => 'N'
  }
  
  self.supported_cardtypes = [:visa, :master, :american_express, :discover, :jcb, :switch, :solo, :maestro, :diners_club]
  
  def initialize(mode)
    @url = case mode
      when :test      : TEST_URL
      when :live      : LIVE_URL
      when :simulator : SIMULATOR_URL
    end
  end
  
  def payment(money, options)
    
  end
  
  def repeat(money, options)
    
  end
  
private
  def requires!(hash, *params)
    params.each do |param| 
      if param.is_a?(Array)
        raise ArgumentError.new("Missing required parameter: #{param.first}") unless hash.has_key?(param.first) 

        valid_options = param[1..-1]
        raise ArgumentError.new("Parameter: #{param.first} must be one of #{valid_options.to_sentence(:connector => 'or')}") unless valid_options.include?(hash[param.first])
      else
        raise ArgumentError.new("Missing required parameter: #{param}") unless hash.has_key?(param) 
      end
    end
  end    
end