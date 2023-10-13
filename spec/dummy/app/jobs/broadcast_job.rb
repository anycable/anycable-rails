# frozen_string_literal: true

class BroadcastJob < ActiveJob::Base
  def perform(stream, data, to_others = false)
    ActionCable.server.broadcast(stream, data, to_others: to_others)
  end
end
