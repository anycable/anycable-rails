# frozen_string_literal: true

require "anycable/rails/action_cable_ext/connection"
require "anycable/rails/action_cable_ext/channel"
require "anycable/rails/action_cable_ext/remote_connections"

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
          AnyCable.logger = ActiveSupport::TaggedLogging.new(::ActionCable.server.config.logger)
          # Broadcast server logs to STDOUT in development
          if ::Rails.env.development? &&
              !ActiveSupport::Logger.logger_outputs_to?(::Rails.logger, $stdout)
            console = ActiveSupport::Logger.new($stdout)
            console.formatter = ::Rails.logger.formatter
            console.level = ::Rails.logger.level
            AnyCable.logger.extend(ActiveSupport::Logger.broadcast(console))
          end
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
      end

      initializer "anycable.connection_factory", after: "action_cable.set_configs" do |app|
        ActiveSupport.on_load(:action_cable) do
          app.config.to_prepare do
            AnyCable.connection_factory = AnyCable::Rails::ConnectionFactory.new
          end

          if AnyCable::Rails.enabled? && AnyCable.config.persistent_session_enabled
            require "anycable/rails/connections/persistent_session"
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
