# frozen_string_literal: true
require "rubocop"

module GraphQL
  module Rubocop
    module GraphQL
      class BaseCop < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        # Return the source of `send_node`, but without the keyword argument represented by `pair_node`
        def source_without_keyword_argument(send_node, pair_node)
          # work back to the preceding comma
          first_pos = pair_node.location.expression.begin_pos
          end_pos = pair_node.location.expression.end_pos
          node_source = send_node.source_range.source
          node_first_pos = send_node.location.expression.begin_pos

          relative_first_pos = first_pos - node_first_pos
          relative_last_pos = end_pos - node_first_pos

          begin_removal_pos = relative_first_pos
          while node_source[begin_removal_pos] != ","
            begin_removal_pos -= 1
            if begin_removal_pos < 1
              raise "Invariant: somehow backtracked to beginning of node looking for a comma (node source: #{node_source.inspect})"
            end
          end

          end_removal_pos = relative_last_pos
          cleaned_node_source = node_source[0...begin_removal_pos] + node_source[end_removal_pos..-1]
          cleaned_node_source
        end
      end
    end
  end
end
