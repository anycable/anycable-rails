# frozen_string_literal: true

Rails.application.routes.draw do
  resources :sessions, only: [:create]
  resources :broadcasts, only: [:create]
end
