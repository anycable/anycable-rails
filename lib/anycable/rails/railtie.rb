# frozen_string_literal: true

require "anycable/rails/action_cable_ext/connection"
require "anycable/rails/action_cable_ext/channel"
require "anycable/rails/action_cable_ext/remote_connections"
require "anycable/rails/action_cable_ext/broadcast_options"

require "anycable/rails/channel_state"
require "anycable/rails/connection_factory"

module AnyCable
  module Rails
    class Railtie < ::Rails::Railtie # :nodoc:
      initializer "anycable.disable_action_cable_mount", after: "action_cable.set_configs" do |app|
        next unless AnyCable::Rails.enabled?

        app.config.action_cable.mount_path = nil
      end

      initializer "anycable.logger", after: "action_cable.logger" do |_app|
        AnyCable.logger = ::ActionCable.server.config.logger

        AnyCable.configure_server do
          server_logger = AnyCable.logger = ::ActionCable.server.config.logger

          # Broadcast server logs to STDOUT in development
          if ::Rails.env.development? &&
              !ActiveSupport::Logger.logger_outputs_to?(::Rails.logger, $stdout)
            console = ActiveSupport::Logger.new($stdout)
            console.formatter = ::Rails.logger.formatter if ::Rails.logger.respond_to?(:formatter)
            console.level = ::Rails.logger.level if ::Rails.logger.respond_to?(:level)

            # Rails 7.1+
            if defined?(ActiveSupport::BroadcastLogger)
              AnyCable.logger = ActiveSupport::BroadcastLogger.new(AnyCable.logger, console)
            else
              AnyCable.logger.extend(ActiveSupport::Logger.broadcast(console))
            end
          end

          AnyCable.logger = ActiveSupport::TaggedLogging.new(AnyCable.logger) if server_logger.is_a?(::Logger)
        end

        # Add tagging middleware
        if AnyCable.logger.respond_to?(:tagged)
          require "anycable/rails/middlewares/log_tagging"

          AnyCable.middleware.use(AnyCable::Rails::Middlewares::LogTagging)
        end
      end

      initializer "anycable.executor" do |app|
        require "anycable/rails/middlewares/executor"
        # see https://github.com/rails/rails/pull/33469/files
        executor = app.config.reload_classes_only_on_change ? app.reloader : app.executor
        AnyCable.middleware.use(AnyCable::Rails::Middlewares::Executor.new(executor))

        if app.executor.respond_to?(:error_reporter)
          AnyCable.capture_exception do |ex, method, message|
            ::Rails.error.report(ex, handled: false, context: {method: method.to_sym, payload: message})
          end
        end

        if AnyCable.config.batch_broadcasts?
          if AnyCable.broadcast_adapter.respond_to?(:start_batching)
            app.executor.to_run { AnyCable.broadcast_adapter.start_batching }
            app.executor.to_complete { AnyCable.broadcast_adapter.finish_batching }
          else
            warn "[AnyCable] Auto-batching is enabled for broadcasts but your anycable version doesn't support it. Please, upgrade"
          end
        end
      end

      initializer "anycable.socket_id_tracking" do
        ActiveSupport.on_load(:action_controller) do
          require "anycable/rails/socket_id_tracking"
          include AnyCable::Rails::SocketIdTrackingController
        end

        ActiveSupport.on_load(:active_job) do
          require "anycable/rails/socket_id_tracking"
          include AnyCable::Rails::SocketIdTrackingJob
        end
      end

      initializer "anycable.connection_factory", after: "action_cable.set_configs" do |app|
        ActiveSupport.on_load(:action_cable) do
          app.config.to_prepare do
            AnyCable.connection_factory = AnyCable::Rails::ConnectionFactory.new
          end

          if AnyCable.config.persistent_session_enabled?
            require "anycable/rails/connections/persistent_session"
          end
        end
      end

      initializer "anycable.routes" do
        next unless AnyCable::Rails.enabled?

        config.after_initialize do |app|
          config = AnyCable.config
          unless config.http_rpc_mount_path.nil?
            app.routes.prepend do
              mount AnyCable::HTTRPC::Server.new => config.http_rpc_mount_path, :internal => true
            end
          end
        end
      end

      # Since Rails 6.1
      if respond_to?(:server)
        server do
          next unless AnyCable.config.embedded? && AnyCable::Rails.enabled?

          require "anycable/cli"
          AnyCable::CLI.embed!
        end
      end
    end
  end
end
