# frozen_string_literal: true

require "action_cable"

ActionCable::Channel::Base.prepend(Module.new do
  attr_accessor :whisper_stream

  def stream_from(broadcasting, _callback = nil, **opts)
    whispering = opts.delete(:whisper)
    whispers_to(broadcasting) if whispering
    super
  end

  def whispers_to(broadcasting)
    logger.debug "#{self.class.name} whispers to #{broadcasting}"
    self.whisper_stream = broadcasting
  end
end)

ActionCable::Connection::Subscriptions.prepend(Module.new do
  def execute_command(data)
    return whisper(data) if data["command"] == "whisper"

    super
  end

  def whisper(data)
    subscription = find(data)
    stream = subscription.whisper_stream
    raise "Whispering stream is not set" unless stream

    ::ActionCable.server.broadcast stream, data["data"]
  end
end)
