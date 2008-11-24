module Peeves
  class ProtxResponse
    def initialize(response)
      @response = response
      response.split("\r\n").each do |line|
        key, value = line.split("=")
        self[key] = value
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

  private
    def mapping
      {
        "VPSProtocol"       => :vps_protocol,
        "Status"            => :status,
        "StatusDetail"      => :status_detail,
        "VPSTxId"           => :vps_transaction_id,
        "SecurityKey"       => :security_key,
        "NextURL"           => :next_url
      }
    end
  end
end