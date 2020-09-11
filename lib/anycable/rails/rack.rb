# frozen_string_literal: true

require "rails/configuration"
require "action_dispatch/middleware/stack"

module AnyCable
  module Rails
    # Rack middleware stack to modify the HTTP request object.
    #
    # AnyCable Websocket server does not use Rack middleware processing mechanism (which Rails uses
    # when Action Cable is mounted into the main app).
    #
    # Some middlewares could enhance request env with useful information.
    #
    # For instance, consider the Rails session middleware: it's responsible for restoring the
    # session data from cookies.
    #
    # AnyCable adds session middelware by default to its own stack.
    #
    # You can also use any Rack/Rails middleware you want. For example, to enable Devise/Warden
    # you can add the following code to an initializer or any other configuration file:
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
          @rack_app ||= default_middleware_stack.yield_self do |stack|
                          middleware.merge_into(stack)
                        end.yield_self do |stack|
            stack.build { [-1, {}, []] }
          end
        end
      end
    end
  end
end
