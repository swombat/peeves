module Peeves
  class TransactionRegistrationResponse
    attr_accessor :vps_protocol, :status, :status_detail, :vps_transaction_id, :security_key, :next_url
    
    def initialize(response)
      response.split("\n").each do |line|
        key, value = line.split("=")
        self[key] = value
      end
    end
    
    def []=(key, value)
      case key
        when "VPSProtocol"    : vps_protocol = value
        when "Status"         : status = value
        when "StatusDetail"   : status_detail = value
        when "VPSTxId"        : vps_transaction_id = value
        when "SecurityKey"    : security_key = value
        when "NextURL"        : next_url = value
        else self.send("#{key}=", value)
      end
    end
  end
end