# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    class << self
      def events_log
        @events_log ||= []
      end

      def log_event(source, data)
        events_log << {source: source, data: data}
      end
    end

    if respond_to?(:rescue_from)
      rescue_from ActiveRecord::RecordNotFound, with: :track_error
    end

    identified_by :current_user
    identified_by :url

    def connect
      self.current_user = verify_user
      self.url = request.url if current_user
      logger.add_tags "ActionCable", current_user.name
    end

    def disconnect
      self.class.log_event("disconnect", name: current_user.name, url: url)
    end

    private

    def verify_user
      return env["warden"]&.user if env["warden"]&.user

      username = session[:username] || cookies[:username]
      return reject_unauthorized_connection unless username

      token = session[:token] || request.params[:token]

      User.find_by!(name: username, secret: token)
    end

    def track_error(e)
      self.class.log_event("error", message: e.message)
    end
  end
end
