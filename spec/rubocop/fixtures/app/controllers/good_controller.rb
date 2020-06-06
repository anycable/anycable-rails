# frozen_string_literal: true

class GoodController < ActionController::Base # :nodoc:
  periodically :refresh, every: 1.second

  def subscribed
    @good_var = 'good'

    stream_from 'all' do |msg|
      transmit msg
    end
  end
end
