# frozen_string_literal: true

require "rubocop"
require "pathname"

require_relative "anycable/stream_callbacks"
require_relative "anycable/remote_disconnect"
require_relative "anycable/periodical_timers"
require_relative "anycable/instance_vars"

module RuboCop
  module Anycable # :nodoc:
    PROJECT_ROOT = Pathname.new(__dir__).parent.parent.expand_path.freeze
    CONFIG_DEFAULT = PROJECT_ROOT.join("rails", "compatibility", "config", "default.yml").freeze

    require_relative "rubocop_ext"
  end
end
