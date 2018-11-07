# frozen_string_literal: true

module AnyCable
  module Rails
    module Middlewares
      # Executor runs Rails executor for each call
      # See https://guides.rubyonrails.org/v5.2.0/threading_and_code_execution.html#framework-behavior
      class Executor < AnyCable::Middleware
        attr_reader :executor

        def initialize(executor)
          @executor = executor
        end

        def call(*)
          executor.wrap { yield }
        end
      end
    end
  end
end
