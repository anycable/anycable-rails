# frozen_string_literal: true

module AnyCable
  module Rails
    module Middlewares
      # Middleware to add `sid` (session ID) tag to logs.
      #
      # Session ID could be provided through gRPC metadata `sid` key.
      #
      # See https://github.com/grpc/grpc-go/blob/master/Documentation/grpc-metadata.md
      class LogTagging < AnyCable::Middleware
        def call(_method, _request, metadata)
          sid = metadata["sid"]
          return yield unless sid

          AnyCable.logger.tagged("AnyCable sid=#{sid}") { yield }
        end
      end
    end
  end
end
