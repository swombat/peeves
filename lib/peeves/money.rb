module Peeves
  class Money
    def initialize(amount, currency, cents=true)
      @amount = cents ? amount / 100.0 : amount
      @currency = currency
    end
    
    attr_accessor :amount, :currency
  end
end