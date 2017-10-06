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

    class Engine < ::Rails::Engine # :nodoc:
      initializer "disable built-in Action Cable mount" do |app|
        app.config.action_cable.mount_path = nil
      end

      initializer "set up logger" do |_app|
        Anycable.logger = LoggerProxy.new(::Rails.logger)
      end

      initializer "release AR connections in RPC handler" do |_app|
        ActiveSupport.on_load(:active_record) do
          require "anycable/rails/activerecord/release_connection"
          Anycable::RPCHandler.prepend Anycable::Rails::ActiveRecord::ReleaseConnection
        end
      end
    end
  end
end
