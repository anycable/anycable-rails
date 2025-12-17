# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
# require "action_cable/engine"
require "action_controller/railtie"

module Dummy
  class Application < Rails::Application
    config.load_defaults 8.1
  end
end
