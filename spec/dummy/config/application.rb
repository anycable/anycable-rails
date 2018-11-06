# frozen_string_literal: true

require_relative "boot"
require "action_controller/railtie"
require "action_cable/engine"
require "global_id/railtie"
require "active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: File.join(PROJECT_ROOT, "tmp", "test_db.sqlite"))

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.string :secret
  end
end

Bundler.require(*Rails.groups)
require "anycable-rails"

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
    config.eager_load = false
  end
end
