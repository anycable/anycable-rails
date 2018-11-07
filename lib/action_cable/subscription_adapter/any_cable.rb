# frozen_string_literal: true

require "anycable-rails"

module ActionCable
  module SubscriptionAdapter
    # AnyCable subscription adapter delegates broadcasts
    # to AnyCable
    class AnyCable < Base
      def initialize(*); end

      def broadcast(channel, payload)
        ::AnyCable.broadcast(channel, payload)
      end

      def shutdown
        # nothing to do
        # we only need this method for development,
        # 'cause code reloading triggers `server.restart` -> `pubsub.shutdown`
      end
    end
  end
end
