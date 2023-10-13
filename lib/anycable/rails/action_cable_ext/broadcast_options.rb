# frozen_string_literal: true

require "action_cable"

ActionCable::Server::Base.prepend(Module.new do
  def broadcast(channel, payload, **options)
    return super if options.empty?

    AnyCable::Rails.with_broadcast_options(**options) do
      super(channel, payload)
    end
  end
end)

ActionCable::Channel::Base.singleton_class.prepend(Module.new do
  def broadcast_to(target, payload, **options)
    return super if options.empty?

    AnyCable::Rails.with_broadcast_options(**options) do
      super(target, payload)
    end
  end
end)
