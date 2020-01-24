# frozen_string_literal: true

class SessionsController < ApplicationController
  def create
    # authenticate with Warden
    if params[:user_id]
      request.env["warden"].set_user(User.find(params[:user_id]))
    else
      session[:username] = params[:data][:username]
      session[:token] = params[:data][:token]
    end
    head :created
  end
end
