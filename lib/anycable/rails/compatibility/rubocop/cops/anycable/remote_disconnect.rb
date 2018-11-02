# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module AnyCable
      # Checks for remote disconnect usage.
      #
      # @example
      #   # bad
      #   class MyServive
      #     def call(user)
      #       ActionCable.server.remote_connections.where(current_user: user).disconnect
      #     end
      #   end
      #
      class RemoteDisconnect < RuboCop::Cop::Cop
        MSG = "Disconnecting remote clients is not supported in AnyCable"

        def_node_matcher :has_remote_disconnect?, <<-PATTERN
          (send (send (send _ :remote_connections) ...) :disconnect)
        PATTERN

        def on_send(node)
          add_offense(node) if has_remote_disconnect?(node)
        end
      end
    end
  end
end
