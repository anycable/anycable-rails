# frozen_string_literal: true

require "action_cable"

module AnyCable
  module Rails
    # Enhance Action Cable connection
    using(Module.new do
      refine ActionCable::Connection::Base do
        attr_writer :env, :websocket, :logger, :coder,
          :subscriptions, :serialized_ids, :cached_ids, :server,
          :anycable_socket

        # Using public :send_welcome_message causes stack level too deep 🤷🏻‍♂️
        def send_welcome_message
          transmit({
            type: ActionCable::INTERNAL[:message_types][:welcome],
            sid: env["anycable.sid"]
          }.compact)
        end

        def public_request
          request
        end
      end

      refine ActionCable::Channel::Base do
        def rejected?
          subscription_rejected?
        end
      end

      refine ActionCable::Connection::Subscriptions do
        # Find or add a subscription to the list
        def fetch(identifier)
          add("identifier" => identifier) unless subscriptions[identifier]

          unless subscriptions[identifier]
            raise "Channel not found: #{ActiveSupport::JSON.decode(identifier).fetch("channel")}"
          end

          subscriptions[identifier]
        end
      end
    end)

    class Connection
      # We store logger tags in the connection state to be able
      # to re-use them in the subsequent calls
      LOG_TAGS_IDENTIFIER = "__ltags__"

      delegate :identifiers_json, to: :conn

      attr_reader :socket, :logger

      def initialize(connection_class, socket, identifiers: nil, subscriptions: nil)
        @socket = socket

        logger_tags = fetch_logger_tags_from_state
        @logger = ActionCable::Connection::TaggedLoggerProxy.new(AnyCable.logger, tags: logger_tags)

        # Instead of calling #initialize,
        # we allocate an instance and setup all the required components manually
        @conn = connection_class.allocate
        # Required to access config (for access origin checks)
        conn.server = ActionCable.server
        conn.logger = logger
        conn.anycable_socket = conn.websocket = socket
        conn.env = socket.env
        conn.coder = ActiveSupport::JSON
        conn.subscriptions = ActionCable::Connection::Subscriptions.new(conn)
        conn.serialized_ids = {}
        conn.serialized_ids = ActiveSupport::JSON.decode(identifiers) if identifiers
        conn.cached_ids = {}
        conn.anycable_request_builder = self

        return unless subscriptions

        # Pre-initialize channels (for disconnect)
        subscriptions.each do |id|
          channel = conn.subscriptions.fetch(id)
          next unless socket.istate[id]

          channel.__istate__ = ActiveSupport::JSON.decode(socket.istate[id])
        end
      end

      def handle_open
        logger.info started_request_message if access_logs?

        verify_origin! || return

        conn.connect if conn.respond_to?(:connect)

        socket.cstate.write(LOG_TAGS_IDENTIFIER, logger.tags.to_json) unless logger.tags.empty?

        conn.send_welcome_message
      rescue ::ActionCable::Connection::Authorization::UnauthorizedError
        reject_request(
          ActionCable::INTERNAL[:disconnect_reasons]&.[](:unauthorized) || "unauthorized"
        )
      end

      def handle_close
        logger.info finished_request_message if access_logs?

        conn.subscriptions.unsubscribe_from_all
        conn.disconnect if conn.respond_to?(:disconnect)
        true
      end

      def handle_channel_command(identifier, command, data)
        conn.run_callbacks :command do
          # We cannot use subscriptions#execute_command here,
          # since we MUST return true of false, depending on the status
          # of execution
          channel = conn.subscriptions.fetch(identifier)
          case command
          when "subscribe"
            channel.handle_subscribe
            !channel.rejected?
          when "unsubscribe"
            conn.subscriptions.remove_subscription(channel)
            true
          when "message"
            channel.perform_action ActiveSupport::JSON.decode(data)
            true
          else
            false
          end
        end
      # Support rescue_from
      # https://github.com/rails/rails/commit/d2571e560c62116f60429c933d0c41a0e249b58b
      rescue Exception => e # rubocop:disable Lint/RescueException
        rescue_with_handler(e) || raise
        false
      end

      def build_rack_request(env)
        environment = ::Rails.application.env_config.merge(env) if defined?(::Rails.application) && ::Rails.application
        AnyCable::Rails::Rack.app.call(environment) if environment

        ActionDispatch::Request.new(environment || env)
      end

      def action_cable_connection
        conn
      end

      private

      attr_reader :conn

      def reject_request(reason, reconnect = false)
        logger.info finished_request_message("Rejected") if access_logs?
        conn.close(
          reason: reason,
          reconnect: reconnect
        )
      end

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

      def finished_request_message(reason = "Closed")
        format(
          'Finished "%s"%s for %s at %s (%s)',
          request.filtered_path, " [AnyCable]", request.ip, Time.now.to_s, reason
        )
      end

      def verify_origin!
        return true unless socket.env.key?("HTTP_ORIGIN")

        return true if conn.send(:allow_request_origin?)

        reject_request(
          ActionCable::INTERNAL[:disconnect_reasons]&.[](:invalid_request) || "invalid_request"
        )
        false
      end

      def access_logs?
        AnyCable.config.access_logs_disabled == false
      end

      def request
        conn.public_request
      end

      def request_loaded?
        conn.instance_variable_defined?(:@request)
      end

      def rescue_with_handler(e)
        conn.rescue_with_handler(e) if conn.respond_to?(:rescue_with_handler)
      end
    end
  end
end
