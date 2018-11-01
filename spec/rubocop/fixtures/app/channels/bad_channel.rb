# frozen_string_literal: true

class TestChannel < ApplicationCable::Channel
  def subscribed
    @bad_var = 'bad'
  end
end
