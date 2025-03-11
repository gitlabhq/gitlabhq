# frozen_string_literal: true
require 'rubocop'

module Cop
  module Development
    # A custom Rubocop rule to catch uses of `.none?` without a block.
    #
    # @see https://github.com/rmosolgo/graphql-ruby/pull/2090
    class NoneWithoutBlockCop < RuboCop::Cop::Base
      MSG = <<-MD
Instead of `.none?` or `.any?` without a block:

- Use `.empty?` to check for an empty collection (faster)
- Add a block to explicitly check for `false` (more clear)

Run `-a` to replace this with `%{bang}.empty?`.
      MD
      def on_block(node)
        # Since this method was called with a block, it can't be
        # a case of `.none?` without a block
        ignore_node(node.send_node)
      end

      def on_send(node)
        if !ignored_node?(node) && (node.method_name == :none? || node.method_name == :any?) && node.arguments.size == 0
          add_offense(node, message: MSG % { bang: node.method_name == :none? ? "" : "!.." } )
        end
      end

      def autocorrect(node)
        lambda do |corrector|
          if node.method_name == :none?
            corrector.replace(node.location.selector, "empty?")
          else
            # Backtrack to any chained method calls so we can insert `!` before them
            full_exp = node
            while node.parent.send_type?
              full_exp = node.parent
            end
            new_source = "!" + full_exp.source_range.source.sub("any?", "empty?")
            corrector.replace(full_exp, new_source)
          end
        end
      end
    end
  end
end
