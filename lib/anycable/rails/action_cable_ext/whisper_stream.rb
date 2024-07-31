# frozen_string_literal: true

require "action_cable"

ActionCable::Connection::Subscriptions.prepend(Module.new do
  def execute_command(data)
    return whisper(data) if data["command"] == "whisper"

    super
  end

  def whisper(data)
    subscription = find(data)
    if subscription.whisper_stream
      connection.anycable_socket.whisper data["identifier"], subscription.whisper_stream
    end
  end
end)
