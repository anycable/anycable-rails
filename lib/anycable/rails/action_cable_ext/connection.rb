# frozen_string_literal: true

require "action_cable"
require "anycable/rails/connections/serializable_identification"

ActionCable::Connection::Base.include(AnyCable::Rails::Connections::SerializableIdentification)
ActionCable::Connection::Base.prepend(Module.new do
  def anycabled?
    anycable_socket
  end

  # Allow overriding #subscriptions to use a custom implementation
  attr_writer :subscriptions

  # FIXME: Access AnyCable socket
  attr_accessor :anycable_socket

  # Enhance #send_welcome_message to include sid if present
  def send_welcome_message
    transmit({
      type: ActionCable::INTERNAL[:message_types][:welcome],
      sid: env["anycable.sid"]
    }.compact)
  end

  # TODO: Allow turning off internal channel?
  def subscribe_to_internal_channel
    super unless anycabled?
  end
end)
