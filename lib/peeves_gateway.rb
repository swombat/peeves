class PeevesGateway
  include Peeves::ProtxServices
    
  APPROVED = 'OK'
  
  VPS_PROTOCOL = "2.22"
  
  TRANSACTIONS = {
    :payment          => 'PAYMENT',
    :authenticate     => 'AUTHENTICATE',
    :deferred         => 'DEFERRED',
    :refund           => 'REFUND',
    :authorization    => 'DEFERRED',
    :release          => 'RELEASE',
    :repeat           => 'REPEAT',
    :void             => 'VOID',
    :cancel           => 'CANCEL',
    :abort            => 'ABORT'
  }
  
  AVS_CVV_CODE = {
    "NOTPROVIDED" => nil, 
    "NOTCHECKED" => 'X',
    "MATCHED" => 'Y',
    "NOTMATCHED" => 'N'
  }
    
  def initialize(mode)
    @mode = mode
  end
  
  def debug=(value)
    @no_debug = !value
  end
  
  def debug?
    @mode == :simulator && !@no_debug
  end
  
  # Options:
  # => transaction_reference (required, String(40))
  # => description (required, String(100))
  # => notification_url (required, String)
  # => billing_data (optional, BillingData)
  # => basket (optional, Basket)
  def payment(money, options)
    add_common TRANSACTIONS[:payment]
    add_registration(money, options)
    add_billing(options)
    add_basket(options)
    
    commit! :payment
  end
  
  # Options:
  # => transaction_reference (required, String(40))
  # => description (required, String(100))
  # => notification_url (required, String)
  # => billing_data (optional, BillingData)
  # => basket (optional, Basket)
  def authenticate(money, options)
    add_common TRANSACTIONS[:authenticate]
    add_registration(money, options)
    add_billing(options)
    add_basket(options)
    
    commit! :payment
  end  
  
  # Submits a repeat transaction.
  # Options:
  # => transaction_reference (required, String(40))
  # => description (required, String(100))
  # => related_transaction_reference (required, String(40))
  # => related_vps_transaction_id (required, String(38))
  # => related_security_key (required, String(10))
  # => related_transaction_authorisation_number (required, Long Integer)  
  # Response:
  # => status
  # => status_detail
  # => vps_transaction_id
  # => transaction_authorisation_number
  # => security_key
  def repeat(money, options)
    add_common TRANSACTIONS[:repeat]
    add_related(options)
    add_registration(money, options)
    
    commit! :repeat
  end
  
  # Options:
  # => transaction_reference (required, String(40))
  # => vps_transaction_id (required, String(38))
  # => security_key (required, String(10))
  def cancel(options)
    add_common TRANSACTIONS[:cancel]
    add_post_processing(options)
    
    commit! :cancel
  end

  # Releases (processes for payment) a DEFERRED or REPEATDEFERRED payment.
  # Options:
  # => transaction_reference (required, String(40))
  # => vps_transaction_id (required, String(38))
  # => security_key (required, String(10))
  # => transaction_authorisation_number (required, Long Integer)
  # Response:
  # => status
  # => status_detail
  def release(money, options)
    add_common TRANSACTIONS[:release]
    add_post_processing(options)
    @post["ReleaseAmount"]        = "%.2f" % money.amount
    
    commit! :release
  end
  
  # Voids a previously authorised payment (only possible after receiving the NotificationURL response).
  # Options:
  # => transaction_reference (required, String(40))
  # => vps_transaction_id (required, String(38))
  # => security_key (required, String(10))
  # => transaction_authorisation_number (required, Long Integer)
  # Response:
  # => status
  # => status_detail
  def void(options)
    add_common TRANSACTIONS[:void]
    add_post_processing(options)
    
    commit! :void
  end
  
  
  # Aborts (cancels) a DEFERRED payment.
  # Options:
  # => transaction_reference (required, String(40))
  # => vps_transaction_id (required, String(38))
  # => security_key (required, String(10))
  # => transaction_authorisation_number (required, Long Integer)  
  # Response:
  # => status
  # => status_detail
  def abort(options)
    add_common TRANSACTIONS[:abort]
    add_post_processing(options)
    
    commit! :abort
  end
  
  # Refunds a previously settled transaction.
  # Options:
  # => transaction_reference (required, String(40))
  # => description (required, String(100))
  # => related_transaction_reference (required, String(40))
  # => related_vps_transaction_id (required, String(38))
  # => related_security_key (required, String(10))
  # => related_transaction_authorisation_number (required, Long Integer)
  # Response:
  # => status
  # => status_detail
  # => vps_transaction_id
  # => transaction_authorisation_number
  def refund(money, options)
    add_common TRANSACTIONS[:refund]
    add_related(options)
    add_registration(money, options)
    
    commit! :refund
  end
  
private
  def url_for(action)
    BASE_URL[@mode] + SERVICE[@mode][action]
  end

  def commit!(action)
    response = Peeves::Net::HttpsGateway.new(url_for(action), true, debug?).send({}, @post.to_post_data)
    Peeves::ProtxResponse.new(response)
  end

  def add_common(type)
    @post = Peeves::PostData.new
    @post["TxType"]         = type
    @post["VPSProtocol"]    = VPS_PROTOCOL
    @post["Vendor"]         = Peeves::Config::VENDOR
  end

  def add_post_processing(options)
    @post["VendorTxCode"]         = options[:transaction_reference][0..39]
    @post["VPSTxId"]              = options[:vps_transaction_id][0..37]
    @post["SecurityKey"]          = options[:security_key][0..9]
    @post["TxAuthNo"]             = options[:transaction_authorisation_number] unless options[:transaction_authorisation_number].nil?
  end
  
  def add_related(options)
    @post["RelatedVendorTxCode"]         = options[:related_transaction_reference][0..39]
    @post["RelatedVPSTxId"]              = options[:related_vps_transaction_id][0..37]
    @post["RelatedSecurityKey"]          = options[:related_security_key][0..9]
    @post["RelatedTxAuthNo"]             = options[:related_transaction_authorisation_number] unless options[:transaction_authorisation_number].nil?    
  end
  
  def add_registration(money, options)
    @post["VendorTxCode"]         = options[:transaction_reference][0..39]
    @post["Amount"]               = "%.2f" % money.amount
    @post["Currency"]             = money.currency
    @post["Description"]          = options[:description][0..99]
    @post["NotificationURL"]      = options[:notification_url][0..254] unless options[:notification_url].nil?
  end
  
  def add_billing(options)
    unless options[:billing_data].nil?
      @post["BillingAddress"]     = options[:billing_data].address[0..199]
      @post["BillingPostCode"]    = options[:billing_data].post_code[0..9]
      @post["CustomerName"]       = options[:billing_data].name[0..99]
      @post["CustomerEmail"]      = options[:billing_data].email[0..254]
      @post["ContactNumber"]      = options[:billing_data].contact_number[0..19]
    end
  end
  
  def add_basket(options)
    unless options[:basket].nil?
      @post["Basket"]             = options[:basket].to_post_data
    end
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