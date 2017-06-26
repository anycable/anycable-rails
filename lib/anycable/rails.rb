# frozen_string_literal: true
lib = File.expand_path("../../../../anycable/lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "anycable"
require "anycable/rails/version"

module Anycable
  # Rails handler for AnyCable
  module Rails
    # Use this proxy to quack like a TaggedLoggerProxy
    class LoggerProxy
      def initialize(logger)
        @logger = logger
      end

      def add_tags(*_tags)
        @logger.warn "Tagged logger is not supported by AnyCable. Skip"
      end

      %i( debug info warn error fatal unknown ).each do |severity|
        define_method(severity) do |message|
          @logger.send severity, message
        end
      end
    end

    require "anycable/rails/engine"
    require "anycable/rails/actioncable/server"
    require "anycable/rails/actioncable/connection"

    def self.logger
      @logger ||= LoggerProxy.new(::Rails.logger)
    end
  end
end
