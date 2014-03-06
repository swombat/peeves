module Peeves
  class Money
    def initialize(amount, currency, options = {})
      options[:cents] = true unless options.has_key?(:cents)

      @amount = options[:cents] ? (amount / 100.0) : amount.to_f
      @currency = currency
    end
    
    attr_accessor :amount, :currency

    def cents
      (amount * 100).to_i if amount
    end
  end
end
