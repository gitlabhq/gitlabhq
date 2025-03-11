# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # The problem is
    #   - Variable $usage must be determined at the OperationDefinition level
    #   - You can't tell how fragments use variables until you visit FragmentDefinitions (which may be at the end of the document)
    #
    #  So, this validator includes some crazy logic to follow fragment spreads recursively, while avoiding infinite loops.
    #
    # `graphql-js` solves this problem by:
    #   - re-visiting the AST for each validator
    #   - allowing validators to say `followSpreads: true`
    #
    module VariablesAreUsedAndDefined
      class VariableUsage
        attr_accessor :ast_node, :used_by, :declared_by, :path
        def used?
          !!@used_by
        end

        def declared?
          !!@declared_by
        end
      end

      def initialize(*)
        super
        @variable_usages_for_context = Hash.new {|hash, key| hash[key] = Hash.new {|h, k| h[k] = VariableUsage.new } }
        @spreads_for_context = Hash.new {|hash, key| hash[key] = [] }
        @variable_context_stack = []
      end

      def on_operation_definition(node, parent)
        # initialize the hash of vars for this context:
        @variable_usages_for_context[node]
        @variable_context_stack.push(node)
        # mark variables as defined:
        var_hash = @variable_usages_for_context[node]
        node.variables.each { |var|
          var_usage = var_hash[var.name]
          var_usage.declared_by = node
          var_usage.path = context.path
        }
        super
        @variable_context_stack.pop
      end

      def on_fragment_definition(node, parent)
        # initialize the hash of vars for this context:
        @variable_usages_for_context[node]
        @variable_context_stack.push(node)
        super
        @variable_context_stack.pop
      end

      # For FragmentSpreads:
      #  - find the context on the stack
      #  - mark the context as containing this spread
      def on_fragment_spread(node, parent)
        variable_context = @variable_context_stack.last
        @spreads_for_context[variable_context] << node.name
        super
      end

      # For VariableIdentifiers:
      #  - mark the variable as used
      #  - assign its AST node
      def on_variable_identifier(node, parent)
        usage_context = @variable_context_stack.last
        declared_variables = @variable_usages_for_context[usage_context]
        usage = declared_variables[node.name]
        usage.used_by = usage_context
        usage.ast_node = node
        usage.path = context.path
        super
      end

      def on_document(node, parent)
        super
        fragment_definitions = @variable_usages_for_context.select { |key, value| key.is_a?(GraphQL::Language::Nodes::FragmentDefinition) }
        operation_definitions = @variable_usages_for_context.select { |key, value| key.is_a?(GraphQL::Language::Nodes::OperationDefinition) }

        operation_definitions.each do |node, node_variables|
          follow_spreads(node, node_variables, @spreads_for_context, fragment_definitions, [])
          create_errors(node_variables)
        end
      end

      private

      # Follow spreads in `node`, looking them up from `spreads_for_context` and finding their match in `fragment_definitions`.
      # Use those fragments to update {VariableUsage}s in `parent_variables`.
      # Avoid infinite loops by skipping anything in `visited_fragments`.
      def follow_spreads(node, parent_variables, spreads_for_context, fragment_definitions, visited_fragments)
        spreads = spreads_for_context[node] - visited_fragments
        spreads.each do |spread_name|
          def_node = nil
          variables = nil
          # Implement `.find` by hand to avoid Ruby's internal allocations
          fragment_definitions.each do |frag_def_node, vars|
            if frag_def_node.name == spread_name
              def_node = frag_def_node
              variables = vars
              break
            end
          end

          next if !def_node
          visited_fragments << spread_name
          variables.each do |name, child_usage|
            parent_usage = parent_variables[name]
            if child_usage.used?
              parent_usage.ast_node   = child_usage.ast_node
              parent_usage.used_by    = child_usage.used_by
              parent_usage.path       = child_usage.path
            end
          end
          follow_spreads(def_node, parent_variables, spreads_for_context, fragment_definitions, visited_fragments)
        end
      end

      # Determine all the error messages,
      # Then push messages into the validation context
      def create_errors(node_variables)
        # Declared but not used:
        node_variables
          .select { |name, usage| usage.declared? && !usage.used? }
          .each { |var_name, usage|
            declared_by_error_name = usage.declared_by.name || "anonymous #{usage.declared_by.operation_type}"
            add_error(GraphQL::StaticValidation::VariablesAreUsedAndDefinedError.new(
              "Variable $#{var_name} is declared by #{declared_by_error_name} but not used",
              nodes: usage.declared_by,
              path: usage.path,
              name: var_name,
              error_type: VariablesAreUsedAndDefinedError::VIOLATIONS[:VARIABLE_NOT_USED]
            ))
          }

        # Used but not declared:
        node_variables
          .select { |name, usage| usage.used? && !usage.declared? }
          .each { |var_name, usage|
            used_by_error_name = usage.used_by.name || "anonymous #{usage.used_by.operation_type}"
            add_error(GraphQL::StaticValidation::VariablesAreUsedAndDefinedError.new(
              "Variable $#{var_name} is used by #{used_by_error_name} but not declared",
              nodes: usage.ast_node,
              path: usage.path,
              name: var_name,
              error_type: VariablesAreUsedAndDefinedError::VIOLATIONS[:VARIABLE_NOT_DEFINED]
            ))
          }
      end
    end
  end
end
