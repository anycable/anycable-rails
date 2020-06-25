# frozen_string_literal: true

module ActionCable
  module Connection
    module PersistentSession
      def handle_open
        super.tap { commit_session! }
      end

      def handle_channel_command(*)
        super.tap { commit_session! }
      end

      def build_rack_request
        return super unless socket.session

        super.tap do |req|
          req.env[::Rack::RACK_SESSION] =
            AnyCable::Rails::SessionProxy.new(req.env[::Rack::RACK_SESSION], socket.session)
        end
      end

      def commit_session!
        return unless request_loaded? && request.session.respond_to?(:loaded?) && request.session.loaded?

        socket.session = request.session.to_json
      end
    end
  end
end

::ActionCable::Connection::Base.prepend(
  ::ActionCable::Connection::PersistentSession
)
