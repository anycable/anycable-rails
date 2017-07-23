# frozen_string_literal: true
module Anycable
  module Rails
    class Engine < ::Rails::Engine # :nodoc:
      initializer "disable built-in Action Cable mount" do |app|
        app.config.action_cable.mount_path = nil
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
