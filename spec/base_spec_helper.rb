# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "pry-byebug"

if ENV["COVER"]
  require "simplecov"
  SimpleCov.root File.join(File.dirname(__FILE__), "..")
  SimpleCov.add_filter "/spec/"
  SimpleCov.start
end

PROJECT_ROOT = File.expand_path("../", __dir__)

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random
  Kernel.srand config.seed
end
