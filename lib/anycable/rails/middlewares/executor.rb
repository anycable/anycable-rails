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

        def call(method, message, metadata)
          if ::Rails.respond_to?(:error)
            executor.wrap do
              sid = metadata["sid"]

              ::Rails.error.record(context: {method: method, payload: message.to_h, sid: sid}) do
                yield
              end
            end
          else
            executor.wrap { yield }
          end
        end
      end
    end
  end
end
