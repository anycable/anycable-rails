# frozen_string_literal: true

require "action_cable/remote_connections"

ActionCable::RemoteConnections::RemoteConnection.include(AnyCable::Rails::Connections::SerializableIdentification)

ActionCable::RemoteConnections::RemoteConnection.prepend(Module.new do
  def disconnect(reconnect: true)
    ::AnyCable.broadcast_adapter.broadcast_command("disconnect", identifier: identifiers_json, reconnect: reconnect)
  end
end)
