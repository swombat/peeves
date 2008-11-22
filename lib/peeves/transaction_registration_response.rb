module Peeves
  class TransactionRegistrationResponse
    attr_accessor :vps_protocol, :status, :status_detail, :vps_transaction_id, :security_key, :next_url
    
    def initialize(response)
      @response = response
      response.split("\r\n").each do |line|
        key, value = line.split("=")
        self[key] = value
      end
    end
    
    def []=(key, value)
      case key
        when "VPSProtocol"    : self.vps_protocol = value
        when "Status"         : self.status = value
        when "StatusDetail"   : self.status_detail = value
        when "VPSTxId"        : self.vps_transaction_id = value
        when "SecurityKey"    : self.security_key = value
        when "NextURL"        : self.next_url = value
        else self.send("#{key}=", value)
      end
    end
    
    def to_s
      "#<Peeves::TransactionRegistrationResponse:#{self.object_id} VPSProtocol=#{vps_protocol} Status=#{status} StatusDetail=#{status_detail} " +
      "VPSTxId=#{vps_transaction_id} SecurityKey=#{security_key} NextURL=#{next_url} response='#{@response.gsub("\r\n", "\\r\\n")}'>"
    end
  end
end