require 'rubygems'
require 'activesupport'

$LOAD_PATH << "lib"

ActiveSupport::Dependencies.load_paths = $LOAD_PATH

p = PeevesGateway.new(:simulator)

transaction_reference = Peeves::UniqueId.generate("TEST")

response = p.authenticate Peeves::Money.new(1000, "GBP"),
              {
                :transaction_reference => transaction_reference,
                :description => "Test Transaction",
                :notification_url => "http://edge.woobius.net"
              }

puts response.inspect

puts p.cancel({
  :transaction_reference => transaction_reference,
  :vps_transaction_id => response.vps_transaction_id,
  :security_key => response.security_key
}).inspect
