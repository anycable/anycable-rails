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
  def subscription_from_identifier(id_key)
    id_options = ActiveSupport::JSON.decode(id_key).with_indifferent_access
    return super unless id_options[:channel] == "$pubsub"

    AnyCable::Rails::PubSubChannel.new(connection, id_key, id_options)
  end
end)
