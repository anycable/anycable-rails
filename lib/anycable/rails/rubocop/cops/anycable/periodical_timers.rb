# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module AnyCable
      # Checks for periodical timers usage.
      #
      # @example
      #   # bad
      #   class MyChannel < ApplicationCable::Channel
      #     periodically(:do_something, every: 2.seconds)
      #   end
      #
      class PeriodicalTimers < RuboCop::Cop::Base
        MSG = "Periodical Timers are not supported in AnyCable"
        RESTRICT_ON_SEND = %i[periodically].freeze

        alias_method :on_send, :add_offense
      end
    end
  end
end
