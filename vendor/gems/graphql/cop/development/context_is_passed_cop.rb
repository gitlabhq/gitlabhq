# frozen_string_literal: true
require 'rubocop'

module Cop
  module Development
    class ContextIsPassedCop < RuboCop::Cop::Base
      MSG = <<-MSG
This method also accepts `context` as an argument. Pass it so that the returned value will reflect the current query, or use another method that isn't context-dependent.
MSG

      # These are already context-aware or else not query-related
      def_node_matcher :likely_query_specific_receiver?, "
        {
          (send _ {:ast_node :query :context :warden :ctx :query_ctx :query_context})
          (lvar {:ast_node :query :context :warden :ctx :query_ctx :query_context})
          (ivar {:@query :@context :@warden})
          (send _ {:introspection_system})
        }
      "

      def_node_matcher :method_doesnt_receive_second_context_argument?, <<-MATCHER
        (send _ {:get_field :get_argument :get_type} _)
      MATCHER

      def_node_matcher :method_doesnt_receive_first_context_argument?, <<-MATCHER
        (send _ {:fields :arguments :types :enum_values})
      MATCHER

      def_node_matcher :is_enum_values_call_without_arguments?, "
        (send (send _ {:enum :enum_type (ivar {:@enum :@enum_type})}) {:values})
      "

      def on_send(node)
        if (
            method_doesnt_receive_second_context_argument?(node) ||
              method_doesnt_receive_first_context_argument?(node) ||
              is_enum_values_call_without_arguments?(node)
            ) && !likely_query_specific_receiver?(node.to_a[0])
          add_offense(node)
        end
      end
    end
  end
end
