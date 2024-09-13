# frozen_string_literal: true

require "action_cable"

ActionCable::Channel::Base.prepend(Module.new do
  # TODO: Move to custom executor
  def start_periodic_timers
    super unless anycabled?
  end

  # TODO: Move to custom executor
  def stop_periodic_timers
    super unless anycabled?
  end

  # TODO: Move to custom pub/sub
  def stream_from(broadcasting, _callback = nil, **opts)
    whispering = opts.delete(:whisper)
    return super unless anycabled?

    broadcasting = String(broadcasting)

    connection.anycable_socket.subscribe identifier, broadcasting
    if whispering
      connection.anycable_socket.whisper identifier, broadcasting
    end
  end

  # TODO: Move to custom pub/sub
  def stream_for(model, callback = nil, **opts, &block)
    stream_from(broadcasting_for(model), callback || block, **opts)
  end

  # TODO: Move to custom pub/sub
  def stop_stream_from(broadcasting)
    return super unless anycabled?

    connection.anycable_socket.unsubscribe identifier, broadcasting
  end

  # TODO: Move to custom pub/sub
  def stop_all_streams
    return super unless anycabled?

    connection.anycable_socket.unsubscribe_from_all identifier
  end

  # Make rejected status accessible from outside
  def rejected?
    subscription_rejected?
  end

  private

  def anycabled?
    connection.anycabled?
  end
end)
