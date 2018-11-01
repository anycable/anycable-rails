# frozen_string_literal: true

module Anycable
  module Compatibility
    module Anycable
      # Checks for instance variable usage inside subscriptions.
      #
      # @example
      #   # bad
      #   class MyChannel < ApplicationCable::Channel
      #     def subscribed
      #       @post = Post.first
      #       stream_from @post
      #     end
      #   end
      #
      #   # good
      #   class MyChannel < ApplicationCable::Channel
      #     def subscribed
      #       post = Post.first
      #       stream_from post
      #     end
      #   end
      #
      class InstanceVars < RuboCop::Cop::Cop
        MSG = "Subscription instance variables are not supported in AnyCable"

        def_node_matcher :subscribed_definitions, <<-PATTERN
          (def :subscribed args $...)
        PATTERN

        def on_def(node)
          definitions = subscribed_definitions(node)
          return if definitions.nil?

          find_nested_ivars(definitions) do |nested_ivar|
            add_offense(nested_ivar)
          end
        end

        private

        def find_nested_ivars(nodes, &block)
          nodes.each do |node|
            if node.begin_type? || node.block_type?
              find_nested_ivars(node.child_nodes, &block)
            elsif node.ivasgn_type? || node.ivar_type?
              yield(node)
            end
          end
        end
      end
    end
  end
end
