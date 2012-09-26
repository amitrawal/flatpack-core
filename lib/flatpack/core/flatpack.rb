module Flatpack
  module Core
    class Flatpack
      
      include MapInitialize
      
      attr_reader :packer, :unpacker, :configuration
      
      def initialize(map={})
        set_properties(map)
        @packer = Packer.new(map)
        @unpacker = Unpacker.new(map)
      end
    end
  end
end