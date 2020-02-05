# frozen_string_literal: true

module AnyCable
  module Refinements
    module Subscriptions # :nodoc:
      refine ActionCable::Connection::Subscriptions do
        # Find or add a subscription to the list
        def fetch(identifier)
          add("identifier" => identifier) unless subscriptions[identifier]

          unless subscriptions[identifier]
            raise "Channel not found: #{ActiveSupport::JSON.decode(identifier).fetch('channel')}"
          end

          subscriptions[identifier]
        end
      end
    end
  end
end
