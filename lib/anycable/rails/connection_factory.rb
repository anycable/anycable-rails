# frozen_string_literal: true

require "anycable/rails/connection"

module AnyCable
  module Rails
    module ConnectionFactory
      def self.call(socket, **options)
        # TODO: Introduce a router to support multiple backends
        connection_class = ActionCable.server.config.connection_class.call
        AnyCable::Rails::Connection.new(connection_class, socket, **options)
      end
    end
  end
end
