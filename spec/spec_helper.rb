# frozen_string_literal: true

require "base_spec_helper"

require File.expand_path("spec/dummy/config/environment", PROJECT_ROOT)

Rails.application.eager_load!

require "active_support/testing/stream"
require "ammeter/init"

Dir["#{__dir__}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  include ActiveSupport::Testing::Stream

  config.after(:each) do
    ApplicationCable::Connection.events_log.clear
    User.delete_all
  end
end
