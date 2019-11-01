# frozen_string_literal: true

module AnyCableRailsGenerators
  module Setup
    # Generator to help set up AnyCable in Docker environment
    class DockerGenerator < ::Rails::Generators::Base
      namespace "anycable:setup:docker"

      def info
        say "Docker development configuration could vary."
        say "Here is an example snippet for docker-compose.yml:"
        say <<~YML
          ─────────────────────────────────────────
          anycable-ws:
            image: anycable/anycable-go:v0.6.4
            ports:
              - '3334:3334'
            environment:
              PORT: 3334
              REDIS_URL: redis://redis:6379/0
              ANYCABLE_RPC_HOST: anycable-rpc:50051
            depends_on:
              - anycable-rpc
              - redis

          anycable-rpc:
            <<: *backend
            command: bundle exec anycable
            ports:
              - '50051'
          ─────────────────────────────────────────
        YML
      end
    end
  end
end
