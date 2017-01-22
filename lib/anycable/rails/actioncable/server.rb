# frozen_string_literal: true
require "action_cable"

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
