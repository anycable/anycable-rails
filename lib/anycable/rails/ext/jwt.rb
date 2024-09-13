# frozen_string_literal: true

module AnyCable
  module Rails
    module Ext
      # This module adds AnyCable JWT helpers to Action Cable
      module JWT
        # Handle expired tokens here to respond with a different disconnect reason
        def handle_open
          super
        rescue AnyCable::JWT::ExpiredSignature
          logger.error "An expired JWT token was rejected"
          close(reason: "token_expired", reconnect: false)
        end

        def anycable_jwt_present?
          request.params[AnyCable.config.jwt_param].present? ||
            request.headers["x-#{AnyCable.config.jwt_param}"].present?
        end

        def identify_from_anycable_jwt!
          token = request.params[AnyCable.config.jwt_param].presence ||
            request.headers["x-#{AnyCable.config.jwt_param}"].presence

          identifiers = AnyCable::JWT.decode(token)
          identifiers.each do |k, v|
            public_send("#{k}=", v)
          end
        rescue AnyCable::JWT::VerificationError
          reject_unauthorized_connection
        end
      end
    end
  end
end
