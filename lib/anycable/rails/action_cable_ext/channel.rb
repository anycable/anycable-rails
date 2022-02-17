# frozen_string_literal: true

require "action_cable/channel"

ActionCable::Channel::Base.prepend(Module.new do
  def subscribe_to_channel(force: false)
    return if anycabled? && !force
    super()
  end

  def handle_subscribe
    subscribe_to_channel(force: true)
  end

  def start_periodic_timers
    super unless anycabled?
  end

  def stop_periodic_timers
    super unless anycabled?
  end

  def stream_from(broadcasting, _callback = nil, _options = {})
    return super unless anycabled?

    connection.anycable_socket.subscribe identifier, broadcasting
  end

  def stop_stream_from(broadcasting)
    return super unless anycabled?

    connection.anycable_socket.unsubscribe identifier, broadcasting
  end

  def stop_all_streams
    return super unless anycabled?

    connection.anycable_socket.unsubscribe_from_all identifier
  end

  private

  def anycabled?
    # Use instance variable check here for testing compatibility
    connection.instance_variable_defined?(:@anycable_socket)
  end
end)
