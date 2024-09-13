# frozen_string_literal: true

module AnyCable
  module Rails
    module SocketIdTrackingController
      extend ActiveSupport::Concern

      included do
        around_action :anycable_tracking_socket_id
      end

      private

      def anycable_tracking_socket_id(&)
        Rails.with_socket_id(request.headers[AnyCable.config.socket_id_header], &)
      end
    end

    module SocketIdTrackingJob
      extend ActiveSupport::Concern

      attr_accessor :cable_socket_id

      def serialize
        return super unless Rails.current_socket_id

        super.merge("cable_socket_id" => Rails.current_socket_id)
      end

      def deserialize(job_data)
        super
        self.cable_socket_id = job_data["cable_socket_id"]
      end

      included do
        around_perform do |job, block|
          Rails.with_socket_id(job.cable_socket_id, &block)
        end
      end
    end
  end
end
