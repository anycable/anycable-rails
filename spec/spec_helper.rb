# frozen_string_literal: true

require "base_spec_helper"

require File.expand_path("spec/dummy/config/environment", PROJECT_ROOT)
require "ammeter/init"

require "anycable-rails"
require "anycable/rails/actioncable/connection"
require "anycable/rails/compatibility/cops"

Anycable.connection_factory = ApplicationCable::Connection

Rails.application.eager_load!

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.after(:each) { ApplicationCable::Connection.events_log.clear }
end
