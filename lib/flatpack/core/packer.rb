require 'active_support/inflector'
require 'json'

module Flatpack
  module Core
    class Packer
      
      include MapInitialize
      
      attr_accessor :verbose, :pretty
      
      # Generate a FlatPack JSON string from the given entity
      def pack(entity)
        return {} unless entity
          
        @uuid_stack = []
        @all_entities = {}
        @data = {}
          
        recursive_pack(entity)
        
        json = {
          :data => @data,
          :value => entity.uuid
        }
        json = @pretty ? JSON.pretty_generate(json) : json.to_json
        
        if(@verbose)
          puts "*** Serializing #{entity.entity_name} to FlatPack ***"
          puts json
        end
        
        json
      end
      
      private
      
      def recursive_pack(entity)
        # we only proceed if the entity has a uuid property, 
        # and we haven't seen it before
        uuid = entity.uuid
        return if !entity.respond_to?(:uuid) or @all_entities.keys.include?(uuid)
        
        @all_entities[uuid] = entity
        parent_uuid = @uuid_stack.length > 0 ? @uuid_stack.last : nil
        @uuid_stack.push(uuid)
        
        # walk through our properties
        json = entity.properties
        json.keys.each do |name|
          camelName = name.to_s().camelcase(:lower)
          value = json[name]
          uuid_name = "#{camelName}Uuid"
          
          # The name we're working with will be replaced with a 
          # properly cased name or uuid reference
          json.delete(name)
          
          # property is another entity
          if(value.respond_to?(:uuid))
            recursive_pack(value)
            json[uuid_name] = value.uuid
          
          # property is a collection of (potentially) other entities
          elsif(value.is_a?(Array))
            
            # we'll recurse down to each referenced value
            value.each do |referenced_value|
              recursive_pack(referenced_value)
              referenced_value.uuid
            end
            
            # and add our uuid reference
            json[uuid_name] = value.map {|v| v.uuid}
            
          # property is a plain old property
          else
            # TODO how to handle local..At dates?  
            # Pass a timezone into the pack function as an option?
            
            json[camelName] = value
          end
        end
        
        # add our parent uuid reference if neccessary
        if parent_uuid
          parent = @all_entities[parent_uuid]
          json["#{parent.entity_name}Uuid"] = parent_uuid
        end
        
        # add the resulting json to the correct bucket in our data hash
        bucket = @data[entity.entity_name]
        if(!bucket)
          bucket = []
          @data[entity.entity_name] = bucket
        end
        bucket.push(json)
        
        @uuid_stack.pop
      end
      
    end
  end
end
