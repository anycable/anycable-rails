# frozen_string_literal: true

require "action_cable"

module AnyCable
  module Rails
    class Connection
      class Subscriptions < ::ActionCable::Connection::Subscriptions
        # Wrap the original #execute_command to pre-initialize the channel for unsubscribe/message and
        # return true/false to indicate successful/unsuccessful subscription.
        def execute_command(data)
          cmd = data["command"]

          load(data["identifier"]) unless cmd == "subscribe"

          super

          return true unless cmd == "subscribe"

          subscription = subscriptions[data["identifier"]]
          !(subscription.nil? || subscription.rejected?)
        end

        # Restore channels from the list of identifiers and the state
        def restore(subscriptions, istate)
          subscriptions.each do |id|
            channel = load(id)
            channel.__istate__ = ActiveSupport::JSON.decode(istate[id]) if istate[id]
          end
        end

        # Find or create a channel for a given identifier
        def load(identifier)
          return subscriptions[identifier] if subscriptions[identifier]

          subscription = subscription_from_identifier(identifier)
          raise "Channel not found: #{ActiveSupport::JSON.decode(identifier).fetch("channel")}" unless subscription

          subscriptions[identifier] = subscription
        end
      end

      # We store logger tags in the connection state to be able
      # to re-use them in the subsequent calls
      LOG_TAGS_IDENTIFIER = "__ltags__"

      attr_reader :socket, :server

      delegate :identifiers_json, to: :conn
      delegate :cstate, :istate, to: :socket

      def initialize(connection_class, socket, identifiers: nil, subscriptions: nil, server: ::ActionCable.server)
        @socket = socket
        @server = server
        # TODO: Move protocol to socket.env as "anycable.protocol"
        @protocol = "actioncable-v1-json"

        logger_tags = fetch_logger_tags_from_state
        @logger = ActionCable::Server::TaggedLoggerProxy.new(AnyCable.logger, tags: logger_tags)

        @conn = connection_class.new(server, self)
        conn.subscriptions = Subscriptions.new(conn)
        conn.identifiers_json = identifiers
        conn.anycable_socket = socket
        conn.subscriptions.restore(subscriptions, socket.istate) if subscriptions
      end

      # == AnyCable RPC interface [BEGIN] ==
      def handle_open
        logger.info started_request_message if access_logs?

        return close unless allow_request_origin?

        conn.handle_open

        # Commit log tags to the connection state
        socket.cstate.write(LOG_TAGS_IDENTIFIER, logger.tags.to_json) unless logger.tags.empty?

        socket.closed?
      end

      def handle_close
        conn.handle_close
        close
        true
      end

      def handle_channel_command(identifier, command, data)
        conn.handle_incoming({"command" => command, "identifier" => identifier, "data" => data})
      end
      # == AnyCable RPC interface [END] ==

      # == Action Cable socket interface [BEGIN]
      attr_reader :protocol, :logger

      def request
        @request ||= begin
          env = socket.env
          environment = ::Rails.application.env_config.merge(env) if defined?(::Rails.application) && ::Rails.application
          AnyCable::Rails::Rack.app.call(environment) if environment

          ActionDispatch::Request.new(environment || env)
        end
      end

      delegate :env, to: :request

      def transmit(data)
        socket.transmit ActiveSupport::JSON.encode(data)
      end

      def close(...)
        return if socket.closed?
        logger.info finished_request_message if access_logs?
        socket.close(...)
      end

      def perform_work(receiver, method_name, *args)
        raise ArgumentError, "Performing work is not supported within AnyCable"
      end
      # == Action Cable socket interface [END]

      private

      attr_reader :conn

      def fetch_logger_tags_from_state
        socket.cstate.read(LOG_TAGS_IDENTIFIER).yield_self do |raw_tags|
          next [] unless raw_tags
          ActiveSupport::JSON.decode(raw_tags)
        end
      end

      def started_request_message
        format(
          'Started "%s"%s for %s at %s',
          request.filtered_path, " [AnyCable]", request.ip, Time.now.to_s
        )
      end

      def finished_request_message
        format(
          'Finished "%s"%s for %s at %s',
          request.filtered_path, " [AnyCable]", request.ip, Time.now.to_s
        )
      end

      def allow_request_origin?
        return true unless socket.env.key?("HTTP_ORIGIN")

        server.allow_request_origin?(socket.env)
      end

      def access_logs?
        AnyCable.config.access_logs_disabled == false
      end
    end
  end
end
