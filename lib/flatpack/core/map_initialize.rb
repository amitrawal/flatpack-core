module Flatpack
  module Core
    
    module MapInitialize
      
      def initialize(map={})
        set_properties(map)
      end
      
      def set_properties(map)
        map.each do |key, value|
          method_key = "#{key}="
          if(self.respond_to?(method_key))
            self.send(method_key, value)
          end
        end
        self
      end
      
    end
  end
end
