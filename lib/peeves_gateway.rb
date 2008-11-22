class PeevesGateway
  
  # TEST_URL = 'https://ukvpstest.protx.com/vspgateway/service'
  # LIVE_URL = 'https://ukvps.protx.com/vspgateway/service'
  SIMULATOR_URL = 'https://ukvpstest.protx.com/VSPSimulator/VSPServerGateway.asp?Service=VendorRegisterTx'
  
  APPROVED = 'OK'
  
  VPS_PROTOCOL = "2.22"
  
  TRANSACTIONS = {
    :payment => 'PAYMENT',
    :refund => 'REFUND',
    :authorization => 'DEFERRED',
    :capture => 'RELEASE',
    :repeat => 'REPEAT',
    :void => 'VOID'
  }
  
  AVS_CVV_CODE = {
    "NOTPROVIDED" => nil, 
    "NOTCHECKED" => 'X',
    "MATCHED" => 'Y',
    "NOTMATCHED" => 'N'
  }
    
  def initialize(mode, login)
    @url = case mode
      when :test      : TEST_URL
      when :live      : LIVE_URL
      when :simulator : SIMULATOR_URL
    end
    @login = login
  end
  
  # Options:
  # => transaction_reference (required, String(40))
  # => description (required, String(100))
  # => notification_url (required, String)
  # => billing_data (optional, BillingData)
  # => basket (optional, Basket)
  def payment(money, options)
    set_default_post_parameters
    @post["TxType"]               = TRANSACTIONS[:payment]
    @post["VendorTxCode"]         = options[:transaction_reference][0..39]
    @post["Amount"]               = "%.2f" % money.amount
    @post["Currency"]             = money.currency
    @post["Description"]          = options[:description][0..99]
    @post["NotificationURL"]      = options[:notification_url][0..254]
    unless options[:billing_data].nil?
      @post["BillingAddress"]     = options[:billing_data].address[0..199]
      @post["BillingPostCode"]    = options[:billing_data].post_code[0..9]
      @post["CustomerName"]       = options[:billing_data].name[0..99]
      @post["CustomerEmail"]      = options[:billing_data].email[0..254]
      @post["ContactNumber"]      = options[:billing_data].contact_number[0..19]
    end
    unless options[:basket].nil?
      @post["Basket"]             = options[:basket].to_post_data
    end
    
    commit!
  end
  
  def repeat(money, options)
    
  end
  
private
  def commit!
    response = Peeves::Net::HttpsGateway.new(@url).send({}, @post.to_post_data)
    Peeves::TransactionRegistrationResponse.new(response)
  end

  def set_default_post_parameters
    @post = Peeves::PostData.new
    @post["VPSProtocol"]    = VPS_PROTOCOL
    @post["Vendor"]         = Peeves::Config::VENDOR
  end

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