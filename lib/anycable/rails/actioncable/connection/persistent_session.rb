# frozen_string_literal: true

module ActionCable
  module Connection
    # Commits the request session after each command execution.
    module PersistentSession
      def handle_channel_command(*)
        super.tap { commit_session! }
      end

      def commit_session!
        return unless request_loaded?
        return unless request.session&.loaded?

        request.session.instance_variable_get(:@by).then do |store|
          store.commit_session(request, nil)
        end
      end
    end
  end
end
