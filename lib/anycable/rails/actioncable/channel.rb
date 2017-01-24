# frozen_string_literal: true
require "action_cable/channel"

module ActionCable
  module Channel
    class Base # :nodoc:
      alias handle_subscribe subscribe_to_channel

      public :handle_subscribe, :subscription_rejected?

      def subscribe_to_channel
        # noop
      end

      def stream_from(broadcasting, callback = nil, coder: nil)
        raise ArgumentError('Unsupported') if callback.present? || coder.present? || block_given?
        connection.socket.stream broadcasting
      end

      def stop_all_streams
        connection.socket.stop_all_streams
      end

      def delegate_connection_identifiers
        connection.identifiers.each do |identifier|
          define_singleton_method(identifier) do
            connection.fetch_identifier(identifier)
          end
        end
      end
    end
  end
end
