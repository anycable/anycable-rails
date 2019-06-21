# frozen_string_literal: true

require "action_cable/channel"

module ActionCable
  module Channel
    class Base # :nodoc:
      alias handle_subscribe subscribe_to_channel

      public :handle_subscribe, :subscription_rejected?

      # Action Cable calls this method from inside the Subscriptions#add
      # method, which we use to initialize the channel instance.
      # We don't want to invoke `subscribed` callbacks every time we do that.
      def subscribe_to_channel
        # noop
      end

      def start_periodic_timers
        # noop
      end

      def stop_periodic_timers
        # noop
      end

      def stream_from(broadcasting, _callback = nil, _options = {})
        connection.socket.subscribe identifier, broadcasting
      end

      def stop_all_streams
        connection.socket.unsubscribe_from_all identifier
      end
    end
  end
end
