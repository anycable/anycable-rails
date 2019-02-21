# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module AnyCable
      # Checks for instance variable usage inside subscriptions.
      #
      # @example
      #   # bad
      #   class MyChannel < ApplicationCable::Channel
      #     def subscribed
      #       @post = Post.find(params[:id])
      #       stream_from @post
      #     end
      #   end
      #
      #   # good
      #   class MyChannel < ApplicationCable::Channel
      #     def subscribed
      #       post = Post.find(params[:id])
      #       stream_from post
      #     end
      #   end
      #
      class InstanceVars < RuboCop::Cop::Cop
        MSG = "Channel instance variables are not supported in AnyCable"

        def on_class(node)
          find_nested_ivars(node) do |nested_ivar|
            add_offense(nested_ivar)
          end
        end

        private

        def find_nested_ivars(node, &block)
          node.each_child_node do |child|
            if child.ivasgn_type? || child.ivar_type?
              yield(child)
            elsif child.children.any?
              find_nested_ivars(child, &block)
            end
          end
        end
      end
    end
  end
end
