# frozen_string_literal: true

module AnyCable
  module Rails
    module Connections
      module SerializableIdentification
        extend ActiveSupport::Concern

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
