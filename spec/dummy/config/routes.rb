# frozen_string_literal: true

Rails.application.routes.draw do
  resources :sessions, only: [:create]
end
