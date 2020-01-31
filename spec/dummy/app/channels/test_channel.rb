# frozen_string_literal: true

class TestChannel < ApplicationCable::Channel
  def subscribed
    if current_user.secret != "123"
      reject
    else
      stream_from "test"
    end
  end

  def follow
    stream_from "user_#{current_user.name}"
    stream_from "all"
  end

  def add(data)
    transmit result: (data["a"].to_i + data["b"].to_i)
  end

  def fail
    non_existent_method(1)
  end

  def tick
    session[:count] ||= 0
    session[:count] += 1
    transmit result: session[:count]
  end
end
