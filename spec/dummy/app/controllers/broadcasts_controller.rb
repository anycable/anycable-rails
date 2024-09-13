# frozen_string_literal: true

class BroadcastsController < ApplicationController
  around_action :maybe_disable_auto_batching

  def create
    options = params[:to_others] ? {to_others: true} : {}
    params[:count].to_i.times do |num|
      ActionCable.server.broadcast "test", {count: num + 1}, **options
    end

    head :created
  end

  private

  def maybe_disable_auto_batching(&)
    return yield unless params[:disable_auto_batching]
    AnyCable.broadcast_adapter.batching(false, &)
  end
end
