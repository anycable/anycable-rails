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
                @#{name} = AnyCable::Rails.deserialize(__istate__["#{name}"], json: true) if connection.anycable_socket
              end

              def #{name}=(val)
                __istate__["#{name}"] = AnyCable::Rails.serialize(val, json: true) if connection.anycable_socket
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

      # Make it possible to provide istate explicitly for a channel instance
      attr_writer :__istate__

      def __istate__
        @__istate__ ||= connection.socket.istate
      end
    end

    module ConnectionState
      module ClassMethods
        def state_attr_accessor(*names)
          names.each do |name|
            connection_state_attributes << name
            class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{name}
                return @#{name} if instance_variable_defined?(:@#{name})
                @#{name} = AnyCable::Rails.deserialize(__cstate__["#{name}"], json: true) if anycable_socket
              end

              def #{name}=(val)
                __cstate__["#{name}"] = AnyCable::Rails.serialize(val, json: true) if anycable_socket
                instance_variable_set(:@#{name}, val)
              end
            RUBY
          end
        end

        def connection_state_attributes
          return @connection_state_attributes if instance_variable_defined?(:@connection_state_attributes)

          @connection_state_attributes =
            if superclass.respond_to?(:connection_state_attributes)
              superclass.connection_state_attributes.dup
            else
              []
            end
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end

      # Make it possible to provide istate explicitly for a connection instance
      attr_writer :__cstate__

      def __cstate__
        @__cstate__ ||= socket.cstate
      end
    end
  end
end

ActiveSupport.on_load(:action_cable) do
  # `state_attr_accessor` must be available in Action Cable
  ::ActionCable::Connection::Base.include(AnyCable::Rails::ConnectionState)
  ::ActionCable::Channel::Base.include(AnyCable::Rails::ChannelState)
end
