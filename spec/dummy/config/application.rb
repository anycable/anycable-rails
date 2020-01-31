# frozen_string_literal: true

require_relative "boot"
require "action_controller/railtie"
require "action_cable/engine"
require "global_id/railtie"
require "active_record/railtie"

require "warden"

require "anycable-rails"
require "anycable/rails/compatibility"

module Dummy
  class Application < Rails::Application
    config.logger = Logger.new(STDOUT)
    config.log_level = :fatal
    config.eager_load = true

    if Rails::VERSION::MAJOR < 6
      config.active_record.sqlite3.represent_boolean_as_integer = true
    end

    config.cache_store = :memory_store
    config.session_store :cache_store, key: "__anycable_dummy"

    config.middleware.use Warden::Manager

    AnyCable::Rails::Rack.middleware.use Warden::Manager
  end
end
