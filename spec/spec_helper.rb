# frozen_string_literal: true

require "base_spec_helper"

require File.expand_path("spec/dummy/config/environment", PROJECT_ROOT)

require "rspec/rails"

Rails.application.eager_load!

# This code is called from the server callback in Railtie
AnyCable.logger = ActiveSupport::TaggedLogging.new(::ActionCable.server.config.logger)

require "active_support/testing/stream"
require "ammeter/init"
require "anycable/rspec"

Dir["#{__dir__}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  include ActiveSupport::Testing::Stream

  config.after(:each) do
    ApplicationCable::Connection.events_log.clear
    User.delete_all
  end
end
