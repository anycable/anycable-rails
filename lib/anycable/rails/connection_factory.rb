# frozen_string_literal: true

require "action_cable"

begin
  ActionCable::Server::Socket
rescue
end

if defined?(ActionCable::Server::Socket)
  require "anycable/rails/next/connection"
  require "anycable/rails/next/action_cable_ext/connection"
  require "anycable/rails/next/action_cable_ext/channel"
else
  require "anycable/rails/connection"

  require "anycable/rails/action_cable_ext/connection"
  require "anycable/rails/action_cable_ext/channel"
end

require "anycable/rails/action_cable_ext/remote_connections"
require "anycable/rails/action_cable_ext/broadcast_options"

module AnyCable
  module Rails
    class ConnectionFactory
      def initialize(&block)
        @mappings = []
        @use_router = false
        instance_eval(&block) if block
      end

      def call(socket, **options)
        connection_class = use_router? ? resolve_connection_class(socket.env) :
                                         ActionCable.server.config.connection_class.call

        AnyCable::Rails::Connection.new(connection_class, socket, **options)
      end

      def map(route, &block)
        raise ArgumentError, "Block is required" unless block

        @use_router = true
        mappings << [route, block]
      end

      private

      attr_reader :mappings, :use_router
      alias_method :use_router?, :use_router

      def resolve_connection_class(env)
        path = env["PATH_INFO"]

        mappings.each do |(prefix, resolver)|
          return resolver.call if path.starts_with?(prefix)
        end

        raise "No connection class found matching #{path}"
      end
    end
  end
end
