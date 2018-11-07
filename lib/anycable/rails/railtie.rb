# frozen_string_literal: true

module AnyCable
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
      initializer "anycable.disable_action_cable_mount", after: "action_cable.set_configs" do |app|
        # Disable Action Cable when AnyCable adapter is used
        next unless ActionCable.server.config.cable.fetch("adapter", nil) == "any_cable"

        app.config.action_cable.mount_path = nil
      end

      initializer "anycable.logger", after: :initialize_logger do |_app|
        AnyCable.logger = LoggerProxy.new(::Rails.logger)

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

      initializer "anycable.executor" do |app|
        require "anycable/rails/middlewares/executor"
        # see https://github.com/rails/rails/pull/33469/files
        executor = app.config.reload_classes_only_on_change ? app.reloader : app.executor
        AnyCable.middleware.use(AnyCable::Rails::Middlewares::Executor.new(executor))
      end

      initializer "anycable.connection_factory", after: "action_cable.set_configs" do |_app|
        ActiveSupport.on_load(:action_cable) do
          AnyCable.connection_factory = connection_class.call
        end
      end
    end
  end
end
