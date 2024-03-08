# frozen_string_literal: true

require "action_cable/remote_connections"

ActionCable::RemoteConnections::RemoteConnection.include(AnyCable::Rails::Connections::SerializableIdentification)

ActionCable::RemoteConnections::RemoteConnection.prepend(Module.new do
  # Rails <7.1 has no `reconnect` argument
  if ActionCable::RemoteConnections::RemoteConnection.instance_method(:disconnect).arity == 0
    def disconnect(reconnect: true)
      # Legacy Action Cable functionality if case we're not fully migrated yet
      super() unless AnyCable::Rails.enabled?
      ::AnyCable.broadcast_adapter.broadcast_command("disconnect", identifier: identifiers_json, reconnect: reconnect)
    end
  else
    def disconnect(reconnect: true)
      # Legacy Action Cable functionality if case we're not fully migrated yet
      super unless AnyCable::Rails.enabled?
      ::AnyCable.broadcast_adapter.broadcast_command("disconnect", identifier: identifiers_json, reconnect: reconnect)
    end
  end
end)
