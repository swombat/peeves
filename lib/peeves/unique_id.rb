module Peeves
  class UniqueId
    def self.generate(specific=nil)
      "W-#{specific[0..14]}-#{Time.now.to_f}-#{'%05d' % rand(99999)}"
    end
  end
end