# frozen_string_literal: true

require_relative "boot"
require "action_controller/railtie"
require "action_cable/engine"
require "active_job/railtie"
require "global_id/railtie"
require "active_record/railtie"

require "warden"

require "anycable-rails"
require "anycable/rails/compatibility"

class TestErrorSubscriber
  def self.report(error, handled:, severity:, context:, **_other)
    errors << [error, handled, context]
  end

  def self.errors
    Thread.current[:_test_errors_] ||= []
  end

  def self.reset
    Thread.current[:_test_errors_] = []
  end
end

module Dummy
  class Application < Rails::Application
    config.logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout))
    config.log_level = ENV["ANYCABLE_DEBUG"].in?(%w[1 y t true]) ? :debug : :fatal
    config.eager_load = true

    config.load_defaults [Rails::VERSION::MAJOR, Rails::VERSION::MINOR].join(".").to_f
    # for session tests
    config.action_dispatch.use_authenticated_cookie_encryption = false
    # for request specs
    config.action_controller.default_protect_from_forgery = false
    # for Warden specs
    config.action_dispatch.cookies_serializer = nil

    if Rails::VERSION::MAJOR < 6
      config.active_record.sqlite3.represent_boolean_as_integer = true
    end

    config.session_store :cookie_store, key: "__anycable_dummy"

    config.middleware.use Warden::Manager

    AnyCable::Rails::Rack.middleware.use Warden::Manager

    if ::Rails.version.to_f >= 7.0
      config.after_initialize do |app|
        app.executor.error_reporter.subscribe(TestErrorSubscriber)
      end
    end
  end
end
