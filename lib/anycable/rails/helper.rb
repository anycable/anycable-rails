# frozen_string_literal: true

require "uri"

module AnyCable
  module Rails
    module Helper
      def action_cable_with_jwt_meta_tag(**identifiers)
        # From: https://github.com/rails/rails/blob/main/actioncable/lib/action_cable/helpers/action_cable_helper.rb
        base_url = ActionCable.server.config.url ||
          ActionCable.server.config.mount_path ||
          raise("No Action Cable URL configured -- please configure this at config.action_cable.url")

        token = JWT.encode(identifiers)

        parts = [base_url, "#{AnyCable.config.jwt_param}=#{token}"]

        uri = URI.parse(base_url)

        url = parts.join(uri.query ? "&" : "?")

        tag "meta", name: "action-cable-url", content: url
      end

      def any_cable_jwt_meta_tag(**identifiers)
        token = JWT.encode(identifiers)

        tag "meta", name: "any-cable-jwt", content: token
      end

      def signed_stream_name(streamables)
        Rails.signed_stream_name(streamables)
      end
    end
  end
end
