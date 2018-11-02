# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module AnyCable
      # Checks for remote disconnect usage inside channels.
      #
      # @example
      #   # bad
      #   class MyChannel < ApplicationCable::Channel
      #     periodically(:do_something, every: 2.seconds)
      #   end
      #
      class PeriodicalTimers < RuboCop::Cop::Cop
        MSG = "Periodical Timers are not supported in AnyCable"

        def_node_matcher :calls_periodically?, <<-PATTERN
          (send _ :periodically ...)
        PATTERN

        def on_send(node)
          add_offense(node) if calls_periodically?(node)
        end
      end
    end
  end
end
