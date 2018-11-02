# frozen_string_literal: true

module Anycable
  module Rails
    module Compatibility
      module RemoteConnection # :nodoc:
        def disconnect
          raise Anycable::CompatibilityError,
                "Disconnecting remote clients is not supported in AnyCable!"
        end
      end
    end
  end
end
