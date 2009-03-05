require 'rubygems'
require 'activesupport'

# require 'ruby-debug'

$LOAD_PATH << "lib"

ActiveSupport::Dependencies.load_paths = $LOAD_PATH

p = PeevesGateway.new(:simulator)

transaction_reference = Peeves::UniqueId.generate("TEST")
customer_data = Peeves::CustomerData.new(:surname => 'blah',
                                         :firstnames => 'blah',
                                         :address1 => 'blah',
                                         :address2 => 'blah',
                                         :city => 'blah',
                                         :post_code => 'blah',
                                         :country => 'gb',
                                         :email => 'customer@email.com'
                                        )

# Payment registration
payment_response = p.payment(Peeves::Money.new(1000, "GBP"),
              {
                :transaction_reference => transaction_reference,
                :description           => "Test Transaction",
                :notification_url      => "http://test.example.com",
                :customer_data         => { :billing  => customer_data,
                                            :delivery => customer_data,
                                            :email    => customer_data.email }
              })

puts payment_response.inspect

# Not yet working
# Issue with :related_transaction_authorisation_number which needs to come from
# A3: Notification of Results for Transactions
#
# Repeat payment registration
# repeat_response = p.repeat(Peeves::Money.new(1000, "GBP"),
#              {
#                :transaction_reference => Peeves::UniqueId.generate("TEST"),
#                :description           => "Test Repeat Transaction",
#                :notification_url      => "http://test.example.com",
#                :related_transaction_reference  => transaction_reference,
#                :related_vps_transaction_id     => payment_response[:vps_transaction_id],
#                :related_security_key           => payment_response[:security_key],
#                :related_transaction_authorisation_number => "1213121212"
#              })
#
# puts repeat_response


# AUTHORISE can only be used after AUTHENTICATE; not needed
# 
#response2 = p.authorise(Peeves::Money.new(1000, "GBP"),
#                          {
#                            :transaction_reference => Peeves::UniqueId.generate("TEST"),
#                            :description => "Test Authorise",
#                            :related_transaction_reference => transaction_reference,
#                            :related_vps_transaction_id => response.vps_transaction_id,
#                            :related_security_key => response.security_key
#                          })
#
#puts response2.inspect