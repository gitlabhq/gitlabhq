# frozen_string_literal: true
require 'rubocop'

module Cop
  module Development
    class TraceMethodsCop < RuboCop::Cop::Base
      extend RuboCop::Cop::AutoCorrector

      TRACE_HOOKS = [
        :analyze_multiplex,
        :analyze_query,
        :authorized,
        :authorized_lazy,
        :begin_analyze_multiplex,
        :begin_authorized,
        :begin_dataloader,
        :begin_dataloader_source,
        :begin_execute_field,
        :begin_execute_multiplex,
        :begin_parse,
        :begin_resolve_type,
        :begin_validate,
        :dataloader_fiber_exit,
        :dataloader_fiber_resume,
        :dataloader_fiber_yield,
        :dataloader_spawn_execution_fiber,
        :dataloader_spawn_source_fiber,
        :end_analyze_multiplex,
        :end_authorized,
        :end_dataloader,
        :end_dataloader_source,
        :end_execute_field,
        :end_execute_multiplex,
        :end_parse,
        :end_resolve_type,
        :end_validate,
        :execute_field,
        :execute_field_lazy,
        :execute_multiplex,
        :execute_query,
        :execute_query_lazy,
        :lex,
        :parse,
        :resolve_type,
        :resolve_type_lazy,
        :validate,
      ]

      MSG = "Trace methods should call `super` to pass control to other traces"

      def on_def(node)
        if TRACE_HOOKS.include?(node.method_name) && !node.each_descendant(:super, :zsuper).any?
          add_offense(node) do |corrector|
            if node.body
              offset = node.loc.column + 2
              corrector.insert_after(node.body.loc.expression, "\n#{' ' * offset}super")
            end
          end
        end
      end

      def on_module(node)
        if node.defined_module_name.to_s.end_with?("Trace")
          all_defs = []
          node.body.each_child_node do |body_node|
            if body_node.def_type?
              all_defs << body_node.method_name
            end
          end

          missing_defs = TRACE_HOOKS - all_defs
          redundant_defs = [
            # Not really necessary for making a good trace:
            :lex, :analyze_query, :execute_query, :execute_query_lazy,
            # Only useful for isolated event tracking:
            :dataloader_fiber_exit, :dataloader_spawn_execution_fiber, :dataloader_spawn_source_fiber
          ]
          missing_defs.each do |missing_def|
            if all_defs.include?(:"begin_#{missing_def}") && all_defs.include?(:"end_#{missing_def}")
              redundant_defs << missing_def
              redundant_defs << :"#{missing_def}_lazy"
            end
          end

          missing_defs -= redundant_defs
          if missing_defs.any?
            add_offense(node, message: "Missing some trace hook methods:\n\n- #{missing_defs.join("\n- ")}")
          end
        end
      end
    end
  end
end
