# frozen_string_literal: true

class ChatChannel < ApplicationCable::Channel
  def find(data)
    transmit({name: User.find_by(id: data["id"])&.name})
  end
end
