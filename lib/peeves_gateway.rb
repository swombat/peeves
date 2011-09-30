require 'cgi'

class PeevesGateway
  include Peeves::ProtxServices
    
  APPROVED  = 'OK'
  INVALID   = 'INVALID'
  NOTAUTHED = 'NOTAUTHED'
  ABORT     = 'ABORT'
  REJECTED  = 'REJECTED'
  ERROR     = 'ERROR'
  
  VPS_PROTOCOL = "2.23"
  
  TRANSACTIONS = {
    :payment          => 'PAYMENT',
    :authenticate     => 'AUTHENTICATE',
    :authorise        => 'AUTHORISE',
    :deferred         => 'DEFERRED',
    :refund           => 'REFUND',
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
    
  def initialize(mode=Peeves::Config.gateway_mode)
    @mode = mode
  end
  
  def debug=(value)
    @no_debug = !value
  end
  
  def debug?
    @mode == :simulator && !@no_debug
  end
  
  # Registers a payment so that the user can enter their details.
  # Returns a URL that the user must be forwarded to to make the payment. If the process following this request is
  # followed (i.e. redirect to next_url, user fills in their details, protx notifies server, and server responds with OK)
  # the settlement will go out the next day, automatically, for the full amount.
  # Options:
  # => transaction_reference (required, String(40))
  # => description (required, String(100))
  # => notification_url (required, String)
  # => billing_data (optional, BillingData)
  # => basket (optional, Basket)
  # Response:
  # => status
  # => status_detail
  # => vps_transaction_id
  # => security_key
  # => next_url
  def payment(money, options)
    # TODO check parameters in options to avoid cryptic error messages later
    log "payment", options
    
    add_common TRANSACTIONS[:payment]
    add_registration(money, options)
    add_customer(options)
    add_basket(options)
    
    commit! :payment
  end
  
  # Registers a payment so that the user can enter their details.
  # Returns a URL that the user must be forwarded to to make the payment. If the process following this request is
  # followed (i.e. redirect to next_url, user fills in their details, protx notifies server, and server responds with OK)
  # the settlement will NOT go out the next day. Further "Authorise" requests are required before the user will be
  # charged.
  # Options:
  # => transaction_reference (required, String(40))
  # => description (required, String(100))
  # => notification_url (required, String)
  # => billing_data (optional, BillingData)
  # => basket (optional, Basket)
  # Response:
  # => status
  # => status_detail
  # => vps_transaction_id
  # => security_key
  # => next_url
  def authenticate(money, options)
    log "authenticate", options
    
    add_common(TRANSACTIONS[:authenticate])
    add_registration(money, options)
    add_customer(options)
    add_basket(options)
    
    commit! :payment
  end
  
  # Registers a payment so that the user can enter their details.
  # Returns a URL that the user must be forwarded to to make the payment. If the process following this request is
  # followed (i.e. redirect to next_url, user fills in their details, protx notifies server, and server responds with OK)
  # the settlement will NOT go out the next day, but a "shadow" will be placed on the account until the deferred payment
  # is "Released" or "Aborted". Deferred payments are only supposed to be used to add a delay of up to 7 days, to allow
  # cahrging at the point when the order is shipped.
  # Options:
  # => transaction_reference (required, String(40))
  # => description (required, String(100))
  # => notification_url (required, String)
  # => billing_data (optional, BillingData)
  # => basket (optional, Basket)
  # Response:
  # => status
  # => status_detail
  # => vps_transaction_id
  # => security_key
  # => next_url
  def deferred(money, options)
    log "deferred", options
    
    add_common TRANSACTIONS[:deferred]
    add_registration(money, options)
    add_customer(options)
    add_basket(options)
    
    commit! :deferred
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
    log "repeat", options
    
    add_common(TRANSACTIONS[:repeat])
    add_related(options)
    add_registration(money, options)
    
    commit! :repeat
  end
  
  # Authorises a previously authenticated transaction. This can be done multiple times, for amounts adding up to
  # a maximum of 115% of the authenticated amount.
  # => transaction_reference (required, String(40))
  # => description (required, String(100))
  # => related_transaction_reference (required, String(40))
  # => related_vps_transaction_id (required, String(38))
  # => related_security_key (required, String(10))
  # Response:
  # => status
  # => status_detail
  # => vps_transaction_id
  # => transaction_authorisation_number
  # => security_key
  # => avs_cv2_result
  # => address_result
  # => post_code_result
  # => cv2_result
  def authorise(money, options)
    log "authorise", options
    
    add_common TRANSACTIONS[:authorise]
    add_related(options)
    add_registration(money, options)
    
    commit! :authorise
  end
  
  # Cancels a previously authenticated transaction.
  # Options:
  # => transaction_reference (required, String(40))
  # => vps_transaction_id (required, String(38))
  # => security_key (required, String(10))
  # Response:
  # => status
  # => status_detail
  def cancel(options)
    log "cancel", options
    
    add_common TRANSACTIONS[:cancel]
    add_post_processing(options)
    
    commit! :cancel
  end

  # Releases (processes for payment/settlement) a DEFERRED or REPEATDEFERRED payment.
  # Options:
  # => transaction_reference (required, String(40))
  # => vps_transaction_id (required, String(38))
  # => security_key (required, String(10))
  # => transaction_authorisation_number (required, Long Integer)
  # Response:
  # => status
  # => status_detail
  def release(money, options)
    log "release", options
    
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
    log "void", options
    
    add_common(TRANSACTIONS[:void])
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
    log "abort", options
    
    add_common(TRANSACTIONS[:abort])
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
    log "refund", options
    
    add_common(TRANSACTIONS[:refund])
    add_related(options)
    add_registration(money, options)
    
    commit! :refund
  end
  
  def self.parse_notification(params)
    Peeves::ProtxResponse.new(params).verify!
  end
  
  def self.response(status, redirect_url, status_detail)
    "Status=#{status}\r\n" +
    "RedirectURL=#{redirect_url}\r\n" +
    "StatusDetail=#{status_detail}"
  end
  
private
  def url_for(action)
    BASE_URL[@mode] + SERVICE[@mode][action]
  end

  def commit!(action)
    RAILS_DEFAULT_LOGGER.debug  "Sending Protx post to #{url_for(action)}:\n" +
                                "Post: #{@post.inspect}\n" +
                                "Post data: #{@post.to_post_data}"
    response = Peeves::Net::HttpsGateway.new(url_for(action), true, debug?).send({}, @post.to_post_data)
    Peeves::ProtxResponse.new(response)
  end

  def add_common(type)
    @post = Peeves::PostData.new
    @post["TxType"]         = type
    @post["VPSProtocol"]    = VPS_PROTOCOL
    @post["Vendor"]         = Peeves::Config.vendor
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
    @post["RelatedTxAuthNo"]             = options[:related_transaction_authorisation_number] unless options[:related_transaction_authorisation_number].nil?
  end
  
  def add_registration(money, options)
    @post["VendorTxCode"]         = options[:transaction_reference][0..39]
    @post["Amount"]               = "%.2f" % money.amount
    @post["Currency"]             = money.currency
    @post["Description"]          = options[:description][0..99]
    @post["NotificationURL"]      = options[:notification_url][0..254] unless options[:notification_url].nil?
  end
  
  def add_customer(options)
    unless options[:customer_data].nil?
      @post["CustomerEMail"]     = options[:customer_data][:email]
      add_billing(options[:customer_data])
      add_delivery(options[:customer_data])
    end
  end

  def add_billing(options)
    unless options[:billing].nil?
      # removed character limitation, as they should be enforced in view
      @post["BillingSurname"]     = options[:billing].surname
      @post["BillingFirstnames"]  = options[:billing].firstnames
      @post["BillingAddress1"]    = options[:billing].address1
      @post["BillingAddress2"]    = options[:billing].address2
      @post["BillingCity"]        = options[:billing].city
      @post["BillingState"]       = options[:billing].state
      @post["BillingPostCode"]    = options[:billing].post_code
      @post["BillingCountry"]     = options[:billing].country
      @post["BillingPhone"]       = options[:billing].phone
    end
  end

  def add_delivery(options)
    unless options[:delivery].nil?
      # removed character limitation, as they should be enforced in view
      @post["DeliverySurname"]     = options[:delivery].surname
      @post["DeliveryFirstnames"]  = options[:delivery].firstnames
      @post["DeliveryAddress1"]    = options[:delivery].address1
      @post["DeliveryAddress2"]    = options[:delivery].address2
      @post["DeliveryCity"]        = options[:delivery].city
      @post["DeliveryState"]       = options[:delivery].state
      @post["DeliveryPostCode"]    = options[:delivery].post_code
      @post["DeliveryCountry"]     = options[:delivery].country
      @post["DeliveryPhone"]       = options[:delivery].phone
    end
  end
  
  def add_basket(options)
    unless options[:basket].nil?
      @post["Basket"]             = options[:basket].to_post_data
    end
  end
  
  def log(method, options)
    RAILS_DEFAULT_LOGGER.debug "Called #{method} with options #{options.inspect}"
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
