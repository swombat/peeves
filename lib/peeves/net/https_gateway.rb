require 'net/https'

module Peeves
  module Net

    class ConnectionError < Peeves::Error
    end

    class RetriableConnectionError < Peeves::Error
    end

    class HttpsGateway

      MAX_RETRIES = 3
      OPEN_TIMEOUT = 60
      READ_TIMEOUT = 60
      
      def initialize(url, retry_safe=false, debug=false)
        @url        = url
        @retry_safe = retry_safe
        @debug      = debug
      end
      
      def retry_safe?
        @retry_safe
      end
      
      def debug?
        @debug
      end
      
      def send(headers, data)
        headers['Content-Type'] ||= "application/x-www-form-urlencoded"
        
        uri   = URI.parse(@url)
        
        http = ::Net::HTTP.new(uri.host, uri.port)
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT

        http.set_debug_output $stdout if debug?
        
        http.use_ssl      = true
        
        http.verify_mode    = ::OpenSSL::SSL::VERIFY_NONE
        
        retry_exceptions do 
          begin
            http.post(uri.request_uri, data, headers).body
          rescue EOFError => e
            raise ConnectionError, "The remote server dropped the connection"
          rescue Errno::ECONNRESET => e
            raise ConnectionError, "The remote server reset the connection"
          rescue Errno::ECONNREFUSED => e
            raise RetriableConnectionError, "The remote server refused the connection"
          rescue Timeout::Error, Errno::ETIMEDOUT => e
            raise ConnectionError, "The connection to the remote server timed out"
          end
        end
        
      end
      
      def retry_exceptions
        retries = MAX_RETRIES
        begin
          yield
        rescue RetriableConnectionError => e
          retries -= 1
          puts e.inspect
          retry unless retries.zero?
          raise ConnectionError, e.message
        rescue ConnectionError
          retries -= 1
          retry if retry_safe? && !retries.zero?
          raise
        end
      end
    end
  end
end