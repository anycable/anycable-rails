# frozen_string_literal: true

require_relative "boot"
require "action_controller/railtie"
require "action_cable/engine"
require "global_id/railtie"
require "active_record/railtie"

Bundler.require(*Rails.groups)

require "anycable-rails"
require "anycable/rails/compatibility"

module Dummy
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    config.logger = Logger.new(STDOUT)
    config.log_level = :fatal
    config.eager_load = true

    config.active_record.sqlite3.represent_boolean_as_integer = true
  end
end
