# frozen_string_literal: true

class TestChannel < ApplicationCable::Channel
  periodically :refresh, every: 1.second

  def subscribed
    @bad_var = "bad"

    stream_from "all" do |msg|
      transmit msg
    end
  end

  def follow
    @another_var = "not_good"
  end
end
