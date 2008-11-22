module Peeves
  class UniqueId
    def self.generate(specific=nil)
      "W-#{specific[0..14]}-#{Time.now.to_f}-#{'%5i' % rand(100000)}"
    end
  end
end