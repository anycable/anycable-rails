# frozen_string_literal: true

module AnyCable
  module Rails
    module Ext
      autoload :JWT, "anycable/rails/ext/jwt"

      # These features are included by default
      require "anycable/rails/ext/signed_streams"
      require "anycable/rails/ext/whisper"
    end
  end
end
