# frozen_string_literal: true

require "action_cable"

ActionCable::Channel::Base.prepend(Module.new do
  def start_periodic_timers
    super unless anycabled?
  end

  def stop_periodic_timers
    super unless anycabled?
  end

  def stream_from(broadcasting, _callback = nil, **opts)
    whispering = opts.delete(:whisper)
    return super unless anycabled?

    broadcasting = String(broadcasting)

    connection.anycable_socket.subscribe identifier, broadcasting
    if whispering
      connection.anycable_socket.whisper identifier, broadcasting
    end
  end

  def stream_for(model, callback = nil, **opts, &block)
    stream_from(broadcasting_for(model), callback || block, **opts)
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

# Handle $pubsub channel in Subscriptions
ActionCable::Connection::Subscriptions.prepend(Module.new do
  # The contents are mostly copied from the original,
  # there is no good way to configure channels mapping due to #safe_constantize
  # and the layers of JSON
  # https://github.com/rails/rails/blob/main/actioncable/lib/action_cable/connection/subscriptions.rb
  def add(data)
    id_key = data["identifier"]
    id_options = ActiveSupport::JSON.decode(id_key).with_indifferent_access

    return if subscriptions.key?(id_key)

    return super unless id_options[:channel] == "$pubsub"

    subscription = AnyCable::Rails::PubSubChannel.new(connection, id_key, id_options)
    subscriptions[id_key] = subscription
    subscription.subscribe_to_channel
  end
end)
