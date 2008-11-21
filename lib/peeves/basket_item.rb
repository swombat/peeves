module Peeves
  class BasketItem
    attr_accessor :description, :quantity, :unit_cost_without_tax, :tax_applied, :unit_cost_with_tax, :total_cost_with_tax
    
    def to_post_data
      "#{description}:#{quantity}:#{unit_cost_with_tax}:#{tax_applied}:#{unit_cost_with_tax}:#{total_cost_with_tax}"
    end
    
    alias_method :to_s, :to_post_data
  end
end