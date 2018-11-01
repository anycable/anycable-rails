# frozen_string_literal: true

module RuboCop
  module Anycable # :nodoc:
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

RuboCop::Anycable.inject!
