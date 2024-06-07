# frozen_string_literal: true

require "action_cable"

ActionCable::Connection::Subscriptions.prepend(Module.new do
  def execute_command(data)
    return whisper(data) if data["command"] == "whisper"

    super
  end

  def whisper(data)
    find(data).whisper(ActiveSupport::JSON.decode(data["data"]))
  end
end)
