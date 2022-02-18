# frozen_string_literal: true

module ApplicationCable
  class Channel < ActionCable::Channel::Base
    delegate :session, to: :request

    after_subscribe -> { log_event("subscribed") }

    after_unsubscribe -> { log_event("unsubscribed") }

    def request
      connection.send(:request)
    end

    private

    def log_event(type)
      ApplicationCable::Connection.log_event(
        identifier, type: type, user: current_user.name, **unsubscribed_params.compact
      )
    end

    def unsubscribed_params
      {}
    end
  end
end
