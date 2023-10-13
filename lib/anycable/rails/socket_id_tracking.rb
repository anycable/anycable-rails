# frozen_string_literal: true

module AnyCable
  module Rails
    module SocketIdTracking
      extend ActiveSupport::Concern

      included do
        around_action :anycable_tracking_socket_id
      end

      private

      def anycable_tracking_socket_id(&block)
        Rails.with_socket_id(request.headers[AnyCable.config.socket_id_header], &block)
      end
    end
  end
end
