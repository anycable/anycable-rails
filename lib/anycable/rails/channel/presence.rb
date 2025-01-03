# frozen_string_literal: true

module AnyCable
  module Rails
    module Channel
      # Presence API for Action Cable channels (backed by AnyCable)
      module Presence
        extend ActiveSupport::Concern

        def join_presence(stream = nil, id: user_presence_id, info: user_presence_info)
          return unless anycabled?

          stream ||= connection.anycable_socket.streams[:start].first || raise(ArgumentError, "Provide a stream name for presence updates")

          connection.anycable_socket.presence_join(stream, id, info)
        end

        def leave_presence(id = user_presence_id)
          return unless anycabled?

          connection.anycable_socket.presence_leave(id)
        end

        private

        def user_presence_id
          connection.connection_identifier
        end

        def user_presence_info
          # nothing
        end
      end
    end
  end
end
