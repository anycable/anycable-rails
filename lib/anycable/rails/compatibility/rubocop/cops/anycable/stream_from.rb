# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module AnyCable
      # Checks for #stream_from calls with custom callbacks or coders.
      #
      # @example
      #   # bad
      #   class MyChannel < ApplicationCable::Channel
      #     def follow
      #       stream_for(room) {}
      #     end
      #   end
      #
      #   class MyChannel < ApplicationCable::Channel
      #     def follow
      #       stream_from("all", -> {})
      #     end
      #   end
      #
      #   class MyChannel < ApplicationCable::Channel
      #     def follow
      #       stream_from("all", coder: SomeCoder)
      #     end
      #   end
      #
      #  # good
      #   class MyChannel < ApplicationCable::Channel
      #     def follow
      #       stream_from "all"
      #     end
      #   end
      #
      class StreamFrom < RuboCop::Cop::Cop
        def_node_matcher :stream_from_with_block?, <<-PATTERN
          (block {(send _ :stream_from ...) (send _ :stream_for ...)} ...)
        PATTERN

        def_node_matcher :stream_from_with_callback?, <<-PATTERN
          {(send _ :stream_from str_type? (block (send nil? :lambda) ...)) (send _ :stream_for ... (block (send nil? :lambda) ...))}
        PATTERN

        def_node_matcher :args_of_stream_from, <<-PATTERN
          {(send _ :stream_from str_type? $...)  (send _ :stream_for $...)}
        PATTERN

        def_node_matcher :coder_symbol?, "(pair (sym :coder) ...)"

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
