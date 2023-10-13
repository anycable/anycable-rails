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
          sid = metadata["sid"]

          if ::Rails.respond_to?(:error)
            executor.wrap do
              ::Rails.error.record(context: {method: method, payload: message.to_h, sid: sid}) do
                Rails.with_socket_id(sid) { yield }
              end
            end
          else
            executor.wrap { Rails.with_socket_id(sid) { yield } }
          end
        end
      end
    end
  end
end
