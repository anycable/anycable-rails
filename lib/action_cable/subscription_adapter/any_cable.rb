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

      def broadcast(channel, payload)
        ::AnyCable.broadcast(channel, payload)
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
