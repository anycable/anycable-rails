# frozen_string_literal: true

module Anycable
  class CompatibilityError < StandardError; end

  module Rails
    module Compatibility # :nodoc:
      require_relative "compatibility/ext/channel"
      require_relative "compatibility/ext/remote_connection"

      ActionCable::Channel::Base.prepend(Channel)
      ActionCable::RemoteConnections::RemoteConnection.prepend(RemoteConnection)
    end
  end
end
