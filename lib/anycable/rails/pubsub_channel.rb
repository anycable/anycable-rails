# frozen_string_literal: true

module AnyCable
  module Rails
    class PubSubChannel < ActionCable::Channel::Base
      def subscribed
        stream_name =
          if params[:stream_name] && connection.allow_public_streams?
            params[:stream_name]
          elsif params[:signed_stream_name]
            AnyCable::Streams.verified(params[:signed_stream_name])
          end

        if stream_name
          stream_from stream_name
        else
          reject
        end
      end
    end
  end
end
