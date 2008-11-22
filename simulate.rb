require 'rubygems'
require 'activesupport'

$LOAD_PATH << "lib"

ActiveSupport::Dependencies.load_paths = $LOAD_PATH

p = PeevesGateway.new(:simulator)

response = p.payment Peeves::Money.new(1000, "GBP"),
              {
                :transaction_reference => Peeves::UniqueId.generate("TEST"),
                :description => "Test Transaction",
                :notification_url => "http://edge.woobius.net"
              }

puts response.inspect
