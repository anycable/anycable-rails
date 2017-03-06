# frozen_string_literal: true
lib = File.expand_path("../../../../anycable/lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "anycable"
require "anycable/rails/version"

module Anycable
  # Rails handler for AnyCable
  module Rails
    require "anycable/rails/engine"
    require "anycable/rails/actioncable/server"
    require "anycable/rails/actioncable/connection"
  end
end
