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

        def on_class(node)
          find_nested_ivars(node) do |nested_ivar|
            add_offense(nested_ivar)
          end
        end

        private

        def find_nested_ivars(node, &block)
          node.each_child_node do |child|
            if child.begin_type? || child.block_type? || child.def_type?
              find_nested_ivars(child, &block)
            elsif child.ivasgn_type? || child.ivar_type?
              yield(child)
            end
          end
        end
      end
    end
  end
end
