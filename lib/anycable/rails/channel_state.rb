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
                return unless anycabled?

                val = __istate__["#{name}"]

                @#{name} = val.present? ? AnyCable::Serializer.deserialize(JSON.parse(val)) : nil
              end

              def #{name}=(val)
                __istate__["#{name}"] = AnyCable::Serializer.serialize(val).to_json if anycabled?
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
        @__istate__ ||= connection.anycable_socket.istate
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
                return unless anycabled?

                val = __cstate__["#{name}"]
                @#{name} = val.present? ? AnyCable::Serializer.deserialize(JSON.parse(val)) : nil
              end

              def #{name}=(val)
                __cstate__["#{name}"] = AnyCable::Serializer.serialize(val).to_json if anycabled?
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
        @__cstate__ ||= anycable_socket.cstate
      end
    end
  end
end

if ActiveSupport::VERSION::MAJOR < 6
  # `state_attr_accessor` must be available in Action Cable
  ActiveSupport.on_load(:action_cable) do
    ::ActionCable::Connection::Base.include(AnyCable::Rails::ConnectionState)
    ::ActionCable::Channel::Base.include(AnyCable::Rails::ChannelState)
  end
else
  # `state_attr_accessor` must be available in Action Cable
  ActiveSupport.on_load(:action_cable_connection) do
    ::ActionCable::Connection::Base.include(AnyCable::Rails::ConnectionState)
  end

  ActiveSupport.on_load(:action_cable_channel) do
    ::ActionCable::Channel::Base.include(AnyCable::Rails::ChannelState)
  end
end
