# frozen_string_literal: true

module AnyCable
  module Rails
    class Railtie < ::Rails::Railtie # :nodoc:
      initializer "anycable.disable_action_cable_mount", after: "action_cable.set_configs" do |app|
        # Disable Action Cable default route when AnyCable adapter is used
        adapter = ::ActionCable.server.config.cable&.fetch("adapter", nil)
        next unless AnyCable::Rails.compatible_adapter?(adapter)

        app.config.action_cable.mount_path = nil
      end

      initializer "anycable.logger", after: "action_cable.logger" do |_app|
        AnyCable.logger = ActiveSupport::TaggedLogging.new(::ActionCable.server.config.logger)

        # Broadcast server logs to STDOUT in development
        if ::Rails.env.development? &&
            !ActiveSupport::Logger.logger_outputs_to?(::Rails.logger, STDOUT)
          AnyCable.configure_server do
            console = ActiveSupport::Logger.new(STDOUT)
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
          adapter = ::ActionCable.server.config.cable&.fetch("adapter", nil)
          if AnyCable::Rails.compatible_adapter?(adapter)
            require "anycable/rails/actioncable/connection"

            app.config.to_prepare do
              AnyCable.connection_factory = ActionCable.server.config.connection_class.call
            end
          end
        end
      end
    end
  end
end
