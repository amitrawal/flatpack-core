require 'active_support/inflector'

module Flatpack
  module Core
    class Unpacker
      
      include MapInitialize
      
      attr_accessor :verbose, :entity_module

      # Returns a Reified FlatPack entity from the given JSON data
      def unpack(json_map)
        @all_entities = {}
        
        if(@verbose)
          puts "** Deserializing entity from FlatPack **"
          puts JSON.pretty_generate(json_map)
        end
        
        # Make a first pass through the data to ensure stub entities exist
        uuid_to_data = {}
        (json_map['data'] || []).each do |entity_name, entities|
          if(entities.is_a?(Array))
            entities.each do |entity_data|
              uuid = entity_data['uuid']
              if(allocate_or_get_entity(entity_name, uuid))
                uuid_to_data[uuid] = entity_data
              end
            end
          end
        end
        
        # Then ingest
        uuid_to_data.each { |uuid, data| ingest_item(uuid, data) }
          
        # Return the unpacked entities corresponding to those in the value section
        value = json_map['value']
        value.is_a?(Array) ? value.map{|v| @all_entities[v]} : @all_entities[value]
      end
      
      private
      
      # ingests the given data into the entity associated with the given uuid
      def ingest_item(uuid, data)
        entity = @all_entities[uuid]
        collection_key = entity.entity_name.underscore.pluralize
        reified_properties = {}
          
        data.each do |key, value|
            
          # fooBarsUuid -> foo_bars
          key = key.underscore
          
          # If the key name ends in _date or _at, we assume this is a date property
          if(key.end_with?('_date') or key.end_with?('_at'))
            reified_properties[key] = Time.parse(value).utc
          end
          
          # The value is referencing another entity or collection of entities
          if(key.end_with?('uuid'))
            
            # foo_bar_uuid -> foo_bar
            key = key[0..-6]
            
            if(value.is_a?(Array))
              reified_properties[key] = value.map { |uuid| @all_entities[uuid] }
                
            else
              referent = @all_entities[value]
             
              # If the referent doesn't exist, it's because the server has sent us a sparse
              # payload with a dangling fooUuid reference.  We'll attempt to unpack this 
              # reference using the type informtion encoded within each entity description
              unless referent
                referent_class = entity.class_for_property(key)
                referent = referent_class.new(:uuid => value) if referent_class
              end
             
              # If a referent was not included in the payload, and no type information exists
              # for this property name, we simply drop the property
              next unless referent
              
              reified_properties[key] = referent
             
              # Find or create a collection in the referent to establish a bidirectional mapping.
              # For example a foo.bar property should contain a bar.foos collection.
              if(referent.respond_to?(collection_key))
                collection = referent.send(collection_key)
                unless collection
                  collection = []
                  collection_setter = "#{collection_key}="
                  if(referent.respond_to?(collection_setter))
                    referent.send(collection_setter, collection)
                  end
                end
                collection.push(entity)
              end
            end
            
          # The value is just a plain old property
          else
            reified_properties[key] = value
          end
        end
        
        entity.set_properties(reified_properties)
      end
      
      # Finds the existing entity associated with the given uuid in the local
      # entity store, or stores and returns a new one
      def allocate_or_get_entity(entity_name, uuid)
        entity = @all_entities[uuid]
        return entity if entity
        
        klass = entity_class_for_name(entity_name)
        if(klass != nil)
          @all_entities[uuid] = klass.new({:uuid => uuid})
        end
        klass
      end
      
      # Finds the Ruby class associated with the given entity name
      def entity_class_for_name(name)
        class_name = "#{name[0,1].capitalize}#{name[1..-1]}"
        if @entity_module
          class_name = "#{@entity_module}::#{class_name}"
        end

        result = nil
        begin
          result = class_name.constantize

        rescue NameError
          puts "could not create class for name #{class_name}"
        end

        result 
      end
    end
  end
end
