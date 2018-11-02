# frozen_string_literal: true

module Anycable
  module Rails
    module Compatibility
      module Channel # :nodoc:
        def self.prepended(base)
          def base.periodically(_method, _options)
            raise Anycable::CompatibilityError, "Periodical Timers are not supported in AnyCable!"
          end

          base.before_subscribe :save_instance_variables
          base.after_subscribe :check_instance_variables
        end

        def stream_from(broadcasting, callback = nil, coder: nil)
          if coder.present? && coder != ActiveSupport::JSON
            raise Anycable::CompatibilityError, "Custom coders are not supported in AnyCable!"
          end

          if callback.present? || block_given?
            raise Anycable::CompatibilityError,
                  "Custom stream callbacks are not supported in AnyCable!"
          end

          super
        end

        def perform_action(args)
          vars_before_action = instance_variables
          super(args)
          raise_subscription_variables_exception if instance_variables != vars_before_action
        end

        private

        def save_instance_variables
          @vars_before_subscribe = instance_variables
        end

        def check_instance_variables
          return if instance_variables == remove_instance_variable(:@vars_before_subscribe)

          raise_subscription_variables_exception
        end

        def raise_subscription_variables_exception
          raise Anycable::CompatibilityError,
                "Channel instance variables are not supported in AnyCable!"
        end
      end
    end
  end
end
