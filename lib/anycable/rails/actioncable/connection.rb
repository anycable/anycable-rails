# frozen_string_literal: true

require "action_cable/connection"
require "anycable/rails/actioncable/connection/serializable_identification"
require "anycable/rails/refinements/subscriptions"
require "anycable/rails/actioncable/channel"
require "anycable/rails/actioncable/remote_connections"
require "anycable/rails/session_proxy"

module ActionCable
  module Connection
    # rubocop: disable Metrics/ClassLength
    class Base # :nodoc:
      # We store logger tags in the connection state to be able
      # to re-use them in the subsequent calls
      LOG_TAGS_IDENTIFIER = "__ltags__"

      using AnyCable::Refinements::Subscriptions

      include SerializableIdentification

      attr_reader :socket

      alias anycable_socket socket

      delegate :env, :session, to: :request

      class << self
        def call(socket, **options)
          new(socket, nil, options)
        end
      end

      def initialize(socket, env, identifiers: "{}", subscriptions: nil)
        if env
          # If env is set, then somehow we're in the context of Action Cable
          # Return and print a warning in #process
          @request = ActionDispatch::Request.new(env)
          return
        end

        @ids = ActiveSupport::JSON.decode(identifiers)

        @ltags = socket.cstate.read(LOG_TAGS_IDENTIFIER).yield_self do |raw_tags|
          next unless raw_tags
          ActiveSupport::JSON.decode(raw_tags)
        end

        @cached_ids = {}
        @coder = ActiveSupport::JSON
        @socket = socket
        @subscriptions = ActionCable::Connection::Subscriptions.new(self)

        return unless subscriptions

        # Initialize channels (for disconnect)
        subscriptions.each do |id|
          channel = @subscriptions.fetch(id)
          next unless socket.istate[id]

          channel.__istate__ = ActiveSupport::JSON.decode(socket.istate[id])
        end
      end

      def process
        # Use Rails logger here to print to stdout in development
        logger.error invalid_request_message
        logger.info finished_request_message
        [404, {"Content-Type" => "text/plain"}, ["Page not found"]]
      end

      def invalid_request_message
        "You're trying to connect to Action Cable server while using AnyCable. " \
        "See https://docs.anycable.io/#/troubleshooting?id=server-raises-an-argumenterror-exception-when-client-tries-to-connect"
      end

      def handle_open
        logger.info started_request_message if access_logs?

        verify_origin! || return

        connect if respond_to?(:connect)

        socket.cstate.write(LOG_TAGS_IDENTIFIER, fetch_ltags.to_json)

        send_welcome_message
      rescue ActionCable::Connection::Authorization::UnauthorizedError
        reject_request(
          ActionCable::INTERNAL[:disconnect_reasons]&.[](:unauthorized) || "unauthorized"
        )
      end

      def handle_close
        logger.info finished_request_message if access_logs?

        subscriptions.unsubscribe_from_all
        disconnect if respond_to?(:disconnect)
        true
      end

      # rubocop:disable Metrics/MethodLength
      def handle_channel_command(identifier, command, data)
        channel = subscriptions.fetch(identifier)
        case command
        when "subscribe"
          channel.handle_subscribe
          !channel.subscription_rejected?
        when "unsubscribe"
          subscriptions.remove_subscription(channel)
          true
        when "message"
          channel.perform_action ActiveSupport::JSON.decode(data)
          true
        else
          false
        end
      end
      # rubocop:enable Metrics/MethodLength

      def close(reason: nil, reconnect: nil)
        transmit(
          type: ActionCable::INTERNAL[:message_types].fetch(:disconnect, "disconnect"),
          reason: reason,
          reconnect: reconnect
        )
        socket.close
      end

      def transmit(cable_message)
        socket.transmit encode(cable_message)
      end

      def logger
        @logger ||= TaggedLoggerProxy.new(AnyCable.logger, tags: ltags || [])
      end

      def request
        @request ||= build_rack_request
      end

      private

      attr_reader :ids, :ltags

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

      def access_logs?
        AnyCable.config.access_logs_disabled == false
      end

      def fetch_ltags
        if instance_variable_defined?(:@logger)
          logger.tags
        else
          ltags
        end
      end

      def server
        ActionCable.server
      end

      def verify_origin!
        return true unless socket.env.key?("HTTP_ORIGIN")

        return true if allow_request_origin?

        reject_request(
          ActionCable::INTERNAL[:disconnect_reasons]&.[](:invalid_request) || "invalid_request"
        )
        false
      end

      def reject_request(reason, reconnect = false)
        logger.info finished_request_message("Rejected") if access_logs?
        close(
          reason: reason,
          reconnect: reconnect
        )
      end

      def build_rack_request
        environment = Rails.application.env_config.merge(socket.env)
        AnyCable::Rails::Rack.app.call(environment)

        ActionDispatch::Request.new(environment)
      end

      def request_loaded?
        instance_variable_defined?(:@request)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end

# Support rescue_from
# https://github.com/rails/rails/commit/d2571e560c62116f60429c933d0c41a0e249b58b
if ActionCable::Connection::Base.respond_to?(:rescue_from)
  ActionCable::Connection::Base.prepend(Module.new do
    def handle_channel_command(*)
      super
    rescue Exception => e # rubocop:disable Lint/RescueException
      rescue_with_handler(e) || raise
      false
    end
  end)
end

require "anycable/rails/actioncable/testing" if ::Rails.env.test?
