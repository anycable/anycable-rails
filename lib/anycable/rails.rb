# frozen_string_literal: true

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
