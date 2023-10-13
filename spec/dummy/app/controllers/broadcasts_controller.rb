# frozen_string_literal: true

class BroadcastsController < ApplicationController
  around_action :maybe_disable_auto_batching

  def create
    params[:count].to_i.times do |num|
      ActionCable.server.broadcast "test", {count: num + 1}
    end

    head :created
  end

  private

  def maybe_disable_auto_batching(&block)
    return yield unless params[:disable_auto_batching]
    AnyCable.broadcast_adapter.batching(false, &block)
  end
end
