# frozen_string_literal: true
require "action_cable/connection"
require "anycable/rails/refinements/subscriptions"
require "anycable/rails/actioncable/channel"

module ActionCable
  module Connection
    class Base # :nodoc:
      using Anycable::Refinements::Subscriptions

      attr_reader :socket

      class << self
        def create(socket, **options)
          new(socket, **options)
        end

        def identified_by(*identifiers)
          super
          Array(identifiers).each do |identifier|
            define_method(identifier) do
              instance_variable_get(:"@#{identifier}") || fetch_identifier(identifier)
            end
          end
        end
      end

      def initialize(socket, identifiers: '{}', subscriptions: [])
        @ids = ActiveSupport::JSON.decode(identifiers)

        @cached_ids = {}
        @env = socket.env
        @coder = ActiveSupport::JSON
        @socket = socket
        @subscriptions = ActionCable::Connection::Subscriptions.new(self)

        # Initialize channels if any
        subscriptions.each { |id| @subscriptions.fetch(id) }
      end

      def handle_open
        connect if respond_to?(:connect)
        send_welcome_message
      rescue ActionCable::Connection::Authorization::UnauthorizedError
        close
      end

      def handle_close
        subscriptions.unsubscribe_from_all
        disconnect if respond_to?(:disconnect)
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

      def close
        socket.close
      end

      def transmit(cable_message)
        socket.transmit encode(cable_message)
      end

      # Generate identifiers info.
      # Converts GlobalID compatible vars to corresponding global IDs params.
      def identifiers_hash
        identifiers.each_with_object({}) do |id, acc|
          obj = instance_variable_get("@#{id}")
          next unless obj
          acc[id] = obj.try(:to_gid_param) || obj
        end
      end

      def identifiers_json
        identifiers_hash.to_json
      end

      # Fetch identifier and deserialize if neccessary
      def fetch_identifier(name)
        @cached_ids[name] ||= @cached_ids.fetch(name) do
          val = @ids[name.to_s]
          next val unless val.is_a?(String)
          GlobalID::Locator.locate(val) || val
        end
      end

      def logger
        Anycable::Rails.logger
      end
    end
  end
end
