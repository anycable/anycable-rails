# frozen_string_literal: true

module AnyCable
  module Rails
    module ChannelState
      module ClassMethods
        def state_attr_accessor(*names)
          names.each do |name|
            channel_state_attributes << name
            class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{name}
                return @#{name} if instance_variable_defined?(:@#{name})
                @#{name} = AnyCable::Rails.deserialize(connection.socket.istate["#{name}"], json: true) if connection.anycable_socket
              end

              def #{name}=(val)
                connection.socket.istate["#{name}"] = AnyCable::Rails.serialize(val, json: true) if connection.anycable_socket
                instance_variable_set(:@#{name}, val)
              end
            RUBY
          end
        end

        def channel_state_attributes
          return @channel_state_attributes if instance_variable_defined?(:@channel_state_attributes)

          @channel_state_attributes =
            if superclass.respond_to?(:channel_state_attributes)
              superclass.channel_state_attributes.dup
            else
              []
            end
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end
    end
  end
end

ActiveSupport.on_load(:action_cable) do
  # `state_attr_accessor` must be available in Action Cable
  ::ActionCable::Channel::Base.include(AnyCable::Rails::ChannelState)
end
