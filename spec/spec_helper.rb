# frozen_string_literal: true

require "base_spec_helper"

begin
  require File.expand_path("spec/dummy/config/environment", PROJECT_ROOT)
rescue => e
  $stdout.puts "Failed to load Rails app: #{e.message}\n#{e.backtrace.take(5).join("\n")}"
  exit(1)
end

require "rspec/rails"

Rails.application.eager_load!

# This code is called from the server callback in Railtie
AnyCable.logger = ActiveSupport::TaggedLogging.new(::ActionCable.server.config.logger)

if ENV["DEBUG_RPC_EXCEPTIONS"]
  AnyCable.capture_exception do |ex, method, _|
    $stdout.puts "Debugging RPC exception for ##{method}: #{ex.message}"
    debugger # rubocop:disable Lint/Debugger
  end
end

require "active_support/testing/stream"
require "ammeter/init"
require "anycable/rspec"

Dir["#{__dir__}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  include ActiveSupport::Testing::Stream

  config.after do
    ApplicationCable::Connection.events_log.clear
    TestErrorSubscriber.reset
    User.delete_all
  end
end
