# frozen_string_literal: true

require "rails/configuration"
require "action_dispatch/middleware/stack"

module AnyCable
  module Rails
    # Rack middleware stack to set request's environment keys.
    #
    # AnyCable Websocket server does not use Rack middleware processing mechanism.
    # But some middleware modules could set necessary payload to a request.
    # For instance, one of the ver important is session middleware. Btw, it is enabled by default.
    # You could also use any Rack/Rails middleware what you want.
    # To do that you need to add an initializer to `config/initializers/anycable.rb`
    # with the below code:
    #
    #   AnyCable::Rails::Rack.middleware.use Warden::Manager do |config|
    #     Devise.warden_config = config
    #   end
    module Rack
      def self.app_build_lock
        @app_build_lock
      end

      @app_build_lock = Mutex.new

      def self.middleware
        @middleware ||= ::Rails::Configuration::MiddlewareStackProxy.new
      end

      def self.default_middleware_stack
        config = ::Rails.application.config

        ActionDispatch::MiddlewareStack.new do |middleware|
          middleware.use(config.session_store, config.session_options)
        end
      end

      def self.app
        @rack_app || app_build_lock.synchronize do
          @rack_app ||= begin
            stack = default_middleware_stack
            @middleware = middleware.merge_into(stack)
            middleware.build { [-1, {}, []] }
          end
        end
      end
    end
  end
end
