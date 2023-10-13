# frozen_string_literal: true

require "anycable-rails"

module ActionCable
  module SubscriptionAdapter
    # AnyCable subscription adapter delegates broadcasts
    # to AnyCable
    class AnyCable < Base
      ACTION_CABLE_SERVER_ERROR_MESSAGE = <<~STR
        Looks like you're trying to connect to Rails Action Cable server, not an AnyCable one.

        Please make sure your client is configured to connect to AnyCable server.

        See https://docs.anycable.io/troubleshooting
      STR

      def initialize(*)
      end

      def broadcast(channel, payload, **options)
        options.merge!(::AnyCable::Rails.current_broadcast_options || {})
        to_others = options.delete(:to_others)
        options[:exclude_socket] ||= ::AnyCable::Rails.current_socket_id if to_others
        ::AnyCable.broadcast(channel, payload, **options.compact)
      end

      def subscribe(*)
        raise NotImplementedError, ACTION_CABLE_SERVER_ERROR_MESSAGE
      end

      def unsubscribe(*)
        raise NotImplementedError, ACTION_CABLE_SERVER_ERROR_MESSAGE
      end

      def shutdown
        # nothing to do
        # we only need this method for development,
        # 'cause code reloading triggers `server.restart` -> `pubsub.shutdown`
      end
    end
  end
end
