# frozen_string_literal: true

require "action_cable"

ActionCable::Connection::Base.include(Module.new do
  # This method is assumed to be overriden in the connection class to enable public
  # streams
  def allow_public_streams?
    false
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
