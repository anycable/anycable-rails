# frozen_string_literal: true

require "action_cable"

ActionCable::Channel::Base.prepend(Module.new do
  def stream_from(broadcasting, _callback = nil, **opts)
    whispering = opts.delete(:whisper)
    return super# unless anycabled?

    broadcasting = String(broadcasting)

    connection.anycable_socket.subscribe identifier, broadcasting
    if whispering
      connection.anycable_socket.whisper identifier, broadcasting
    end
  end

  # Unsubscribing relies on the channel state (which is not persistent in AnyCable).
  # Thus, we pretend that the stream is registered to make Action Cable do its unsubscribing job.
  def stop_stream_from(broadcasting)
    streams[broadcasting] = true if anycabled?
    super
  end

  # For AnyCable, unsubscribing from all streams is a separate operation,
  # so we use a special constant to indicate it.
  def stop_all_streams
    if anycabled?
      streams.clear
      streams[AnyCable::Rails::Server::PubSub::ALL_STREAMS] = true
    end
    super
  end

  # Make rejected status accessible from outside
  def rejected? = subscription_rejected?

  private

  def anycabled? = connection.anycabled?
end)
