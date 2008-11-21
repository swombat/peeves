module Peeves
  class Basket
    attr_accessor :items
    
    def initialize(*args)
      @items = args
    end
    
    def to_post_data
      "#{@items.length}:" + @items.join(':')
    end

    alias_method :to_s, :to_post_data    
  end
end