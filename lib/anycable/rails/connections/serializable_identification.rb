# frozen_string_literal: true

module AnyCable
  module Rails
    module Connections
      module SerializableIdentification
        extend ActiveSupport::Concern

        module ConnectionGID
          def connection_identifier
            unless defined? @connection_identifier
              @connection_identifier = connection_gid identifiers.filter_map { |id| instance_variable_get(:"@#{id}") || __send__(id) }
            end

            @connection_identifier
          end
        end

        included do
          prepend ConnectionGID
        end

        class_methods do
          def identified_by(*identifiers)
            super
            Array(identifiers).each do |identifier|
              define_method(identifier) do
                instance_variable_get(:"@#{identifier}") || fetch_identifier(identifier)
              end
            end
          end
        end

        # Generate identifiers info.
        # Converts GlobalID compatible vars to corresponding global IDs params.
        def identifiers_hash
          identifiers.each_with_object({}) do |id, acc|
            obj = instance_variable_get("@#{id}")
            next unless obj

            acc[id] = AnyCable::Serializer.serialize(obj)
          end.compact
        end

        def identifiers_json
          identifiers_hash.to_json
        end

        def identifiers_json=(val)
          @cached_ids = {}
          @serialized_ids = val ? ActiveSupport::JSON.decode(val) : {}
        end

        # Fetch identifier and deserialize if neccessary
        def fetch_identifier(name)
          return unless @cached_ids

          @cached_ids[name] ||= @cached_ids.fetch(name) do
            AnyCable::Serializer.deserialize(@serialized_ids[name.to_s])
          end
        end
      end
    end
  end
end
