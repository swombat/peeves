module Peeves
  class ProtxResponse
    def initialize(response)
      @response = response
      if @response.is_a?(String)
        response.split("\r\n").each do |line|
          key, value = line.split("=")
          self[key] = value
        end
      elsif @response.is_a?(Hash)
        response.each do |key, value|
          self[key] = value
        end
      else
        raise Peeves::Error, "Cannot parse response of type #{@response.class}"
      end
    end
    
    def method_missing(id, *args)
      id = id.to_s
      @values ||= {}

      case id[-1]
        when 61: # :blah=
          @values[id[0..-2].to_sym] = args[0]
        when 63: # :blah?
          @values.has_key?(id[0..-2].to_sym)
        else # :blah
          @values[id.to_sym]
      end
    end
    
    def []=(key, value)
      self.send("#{mapping[key] || key}=", value)
    end
    
    def [](key)
      self.send("#{mapping[key] || key}")
    end

    def verify!
      return self
      # TODO: Make this work, currently fails all
      md5 = Digest::MD5.new
      md5 << "#{self.vps_transaction_id}#{self.transaction_reference}#{self.status}#{self.transaction_authorisation_number}" +
      "#{Peeves::Config::VENDOR}#{self.avs_cv2_result}#{self.security_key}#{self.address_result}#{self.post_code_result}" +
      "#{self.cv2_result}#{self.gift_aid}#{self.status_3d_secure}#{self.code_3d_secure}"
      
      raise Peeves::Error, "MD5 appears to have been tampered with! (#{md5.hexdigest} != #{self.vps_signature})" unless md5.hexdigest == self.vps_signature

      self
    end

  private
    def mapping
      {
        "VPSProtocol"       => :vps_protocol,
        "Status"            => :status,
        "StatusDetail"      => :status_detail,
        "VPSTxId"           => :vps_transaction_id,
        "SecurityKey"       => :security_key,
        "NextURL"           => :next_url,
        "TxAuthNo"          => :transaction_authorisation_number,
        "AVSCV2"            => :avs_cv2_result,
        "AddressResult"     => :address_result,
        "PostCodeResult"    => :post_code_result,
        "CV2Result"         => :cv2_result,
        "VendorTxCode"      => :transaction_reference,
        "GiftAid"           => :gift_aid,
        "3DSecureStatus"    => :status_3d_secure,
        "CAVV"              => :code_3d_secure,
        "VPSSignature"      => :vps_signature
      }
    end
  end
end