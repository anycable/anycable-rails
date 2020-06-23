# frozen_string_literal: true

# This file contains patches to Action Cable testing modules

# Trigger autoload (if constant is defined)
begin
  ActionCable::Channel::TestCase # rubocop:disable Lint/Void
  ActionCable::Connection::TestCase # rubocop:disable Lint/Void
rescue NameError
  return
end

ActionCable::Channel::ChannelStub.prepend(Module.new do
  def subscribe_to_channel
    # allocate @streams
    streams
    handle_subscribe
  end
end)

ActionCable::Channel::ConnectionStub.prepend(Module.new do
  def socket
    @socket ||= AnyCable::Socket.new(env: {})
  end
end)

ActionCable::Connection::TestConnection.prepend(Module.new do
  def initialize(request)
    @request = request
    @cached_ids = {}
    super
  end
end)
