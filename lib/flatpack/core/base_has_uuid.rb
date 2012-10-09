require 'uuidtools'

module Flatpack
  module Core
    class BaseHasUuid
      include MapInitialize
      
      PROPERTY_NAMES = [:uuid]
        
      attr_accessor *PROPERTY_NAMES
      
      # returns this entity's assigned uuid. If no uuid has been assigned,
      # a new uuid will be generated and assigned before returning.
      def uuid 
        @uuid = @uuid || UUIDTools::UUID.random_create
      end
      
      # returns an array of all flatpack property names for this entity
      def property_names
        names = []
        klass=self.class
        while (klass)
          names += klass::PROPERTY_NAMES if defined? klass::PROPERTY_NAMES
          klass = klass.superclass
        end
        names
      end
      
      # returns a hash of all flatpack property names => non-nil values for this entity
      def properties
        map = {}
        property_names.each do |name|
          value = self.send(name)
          map[name] = value unless value == nil
        end
        map
      end
      
      # returns the flatpack entity name for this entity
      def entity_name
        name = self.class.name.gsub(/^.*::/,'')
        name[0,1].downcase + name[1..-1]
      end

      # Equality should be based solely on uuid
      def <=>(other)
        @uuid <=> other.uuid
      end
      
      def class_for_property(property)
        klass=self.class
        result = nil
        while (klass and !result)
          result = klass::TYPE_MAP[property.to_sym] if defined? klass::TYPE_MAP
          klass = klass.superclass
        end
        result
      end
      
    end
  end
end