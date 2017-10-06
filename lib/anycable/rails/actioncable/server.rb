# frozen_string_literal: true

require "action_cable/server/base"

module ActionCable
  module Server
    # Override pubsub for ActionCable
    class Base
      def pubsub
        Anycable.pubsub
      end
    end
  end
end
