# frozen_string_literal: true

module Anycable
  module Compatibility
    module Anycable
      # Checks for #stream_from calls with custom callbacks and coders.
      #
      # @example
      #   # bad
      #   class MyChannel < ApplicationCable::Channel
      #     def follow
      #       stream_from("all") {}
      #     end
      #   end
      #
      #   class MyChannel < ApplicationCable::Channel
      #     def follow
      #       stream_from("all", -> {})
      #     end
      #   end
      #
      #   end
      #
      #   class MyChannel < ApplicationCable::Channel
      #     def follow
      #       stream_from("all", coder: SomeCoder)
      #     end
      #   end
      #
      class StreamCallbacks < RuboCop::Cop::Cop
        def_node_matcher :stream_from_with_block?, <<-PATTERN
          (block (send _ :stream_from ...) ...)
        PATTERN

        def_node_matcher :stream_from_with_callback?, <<-PATTERN
          (send _ :stream_from str_type? (block (send nil? :lambda) ...))
        PATTERN

        def_node_matcher :args_of_stream_from, <<-PATTERN
          (send _ :stream_from str_type? $...)
        PATTERN

        def_node_matcher :coder_symbol?, '(pair (sym :coder) ...)'

        def_node_matcher :active_support_json?, <<-PATTERN
          (pair _ (const (const nil? :ActiveSupport) :JSON))
        PATTERN

        def on_block(node)
          add_callback_offense(node) if stream_from_with_block?(node)
        end

        def on_send(node)
          if stream_from_with_callback?(node)
            add_callback_offense(node)
            return
          end

          args = args_of_stream_from(node)
          find_coders(args) { |coder| add_custom_coder_offense(coder) }
        end

        private

        def find_coders(args)
          return if args.nil?

          args.select(&:hash_type?).each do |arg|
            arg.each_child_node do |pair|
              yield(pair) if coder_symbol?(pair) && !active_support_json?(pair)
            end
          end
        end

        def add_callback_offense(node)
          add_offense(
            node,
            location: :expression,
            message: "Custom stream callbacks are not supported in AnyCable"
          )
        end

        def add_custom_coder_offense(node)
          add_offense(
            node,
            location: :expression,
            message: "Custom coders are not supported in AnyCable"
          )
        end
      end
    end
  end
end
