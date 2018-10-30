# frozen_string_literal: true

module Anycable
  class CompatibilityError < StandardError; end

  module Compatibility # :nodoc:
    require "anycable/rails/compatibility/channel"
    require "anycable/rails/compatibility/remote_connection"

    ActionCable::Channel::Base.prepend(Rails::Compatibility::Channel)
    ActionCable::RemoteConnections::RemoteConnection.prepend(
      Rails::Compatibility::RemoteConnection
    )
  end
end
