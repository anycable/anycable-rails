# frozen_string_literal: true

require "rubocop"
require "pathname"

require_relative "rubocop/cops/anycable/stream_callbacks"
require_relative "rubocop/cops/anycable/remote_disconnect"
require_relative "rubocop/cops/anycable/periodical_timers"
require_relative "rubocop/cops/anycable/instance_vars"

module RuboCop
  module AnyCable # :nodoc:
    CONFIG_DEFAULT = Pathname.new(__dir__).join("rubocop", "config", "default.yml").freeze

    # Merge anycable config into default configuration
    # See https://github.com/backus/rubocop-rspec/blob/master/lib/rubocop/rspec/inject.rb
    def self.inject!
      path = CONFIG_DEFAULT.to_s
      puts "configuration from #{path}" if ConfigLoader.debug?
      hash = ConfigLoader.send(:load_yaml_configuration, path)
      config = Config.new(hash, path)
      config = ConfigLoader.merge_with_default(config, path)
      ConfigLoader.instance_variable_set(:@default_configuration, config)
    end
  end
end

RuboCop::AnyCable.inject!
