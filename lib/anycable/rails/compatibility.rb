# frozen_string_literal: true

module AnyCable
  class CompatibilityError < StandardError; end

  module Compatibility # :nodoc:
    IGNORE_INSTANCE_VARS = %i[
      @active_periodic_timers
      @_streams
      @parameter_filter
      @whisper_stream
    ]

    ActionCable::Channel::Base.prepend(Module.new do
      def stream_from(broadcasting, callback = nil, coder: nil, **)
        if coder.present? && coder != ActiveSupport::JSON
          raise AnyCable::CompatibilityError, "Custom coders are not supported by AnyCable"
        end

        if callback.present? || block_given?
          raise AnyCable::CompatibilityError,
            "Custom stream callbacks are not supported by AnyCable"
        end

        super
      end

      # Do not prepend `subscribe_to_channel` 'cause we make it no-op
      # when AnyCable is running (see anycable/rails/actioncable/channel.rb)
      %w[run_callbacks perform_action].each do |mid|
        module_eval <<~CODE, __FILE__, __LINE__ + 1
          def #{mid}(*)
            __anycable_check_ivars__ { super }
          end
        CODE
      end

      def __anycable_check_ivars__
        was_ivars = instance_variables
        res = yield
        diff = instance_variables - was_ivars - IGNORE_INSTANCE_VARS

        if self.class.respond_to?(:channel_state_attributes)
          diff.delete(:@__istate__)
          diff.delete_if { |ivar| self.class.channel_state_attributes.include?(:"#{ivar.to_s.sub(/^@/, "")}") }
        end

        unless diff.empty?
          raise AnyCable::CompatibilityError,
            "Channel instance variables are not supported by AnyCable, " \
            "but were set: #{diff.join(", ")}"
        end

        res
      end
    end)

    ActionCable::Channel::Base.singleton_class.prepend(Module.new do
      def periodically(*)
        raise AnyCable::CompatibilityError, "Periodical timers are not supported by AnyCable"
      end
    end)
  end
end
