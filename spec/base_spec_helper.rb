# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

begin
  require "debug" unless ENV["CI"] == "true"
rescue LoadError, NoMethodError
end

if ENV["COVERAGE"] == "true"
  require "simplecov"
  SimpleCov.start do
    enable_coverage :branch

    add_filter "/spec/"
  end

  require "simplecov-lcov"
  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.single_report_path = "coverage/lcov.info"
  end

  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ])
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
