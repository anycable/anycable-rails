# frozen_string_literal: true

module AnyCable
  module Rails
    module Ext
      autoload :JWT, "anycable/rails/ext/jwt"
      autoload :SignedStreams, "anycable/rails/ext/signed_streams"
    end
  end
end
