# frozen_string_literal: true

module Anycable
  module Rails
    # Use this proxy to quack like a TaggedLoggerProxy
    class LoggerProxy
      def initialize(logger)
        @logger = logger
      end

      def add_tags(*_tags)
        @logger.warn "Tagged logger is not supported by AnyCable. Skip"
      end

      %i[debug info warn error fatal unknown].each do |severity|
        define_method(severity) do |message|
          @logger.send severity, message
        end
      end
    end

    class Railtie < ::Rails::Railtie # :nodoc:
      initializer "anycable.disable_action_cable_mount", before: "action_cable.routes" do |app|
        app.config.action_cable.mount_path = nil
      end

      initializer "anycable.logger", after: :initialize_logger do |_app|
        Anycable.logger = LoggerProxy.new(::Rails.logger)

        # Broadcast logs to STDOUT in development
        if ::Rails.env.development? &&
           !ActiveSupport::Logger.logger_outputs_to?(::Rails.logger, STDOUT) &&
           !defined?(::Rails::Server)
          console = ActiveSupport::Logger.new(STDOUT)
          console.formatter = ::Rails.logger.formatter
          console.level = ::Rails.logger.level
          ::Rails.logger.extend(ActiveSupport::Logger.broadcast(console))
        end
      end

      initializer "anycable.release_connections" do |_app|
        ActiveSupport.on_load(:active_record) do
          require "anycable/rails/activerecord/release_connection"
          Anycable::RPCHandler.prepend Anycable::Rails::ActiveRecord::ReleaseConnection
        end
      end

      initializer "anycable.connection_factory", after: "action_cable.set_configs" do |_app|
        ActiveSupport.on_load(:action_cable) do
          Anycable.connection_factory = connection_class.call
        end
      end
    end
  end
end
