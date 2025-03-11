# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module VariablesAreInputTypes
      def on_variable_definition(node, parent)
        type_name = get_type_name(node.type)
        type = context.query.types.type(type_name)

        if type.nil?
          @all_possible_input_type_names ||= begin
            names = []
            context.types.all_types.each { |(t)|
              if t.kind.input?
                names << t.graphql_name
              end
            }
            names
          end
          add_error(GraphQL::StaticValidation::VariablesAreInputTypesError.new(
            "#{type_name} isn't a defined input type (on $#{node.name})#{context.did_you_mean_suggestion(type_name, @all_possible_input_type_names)}",
            nodes: node,
            name: node.name,
            type: type_name
          ))
        elsif !type.kind.input?
          add_error(GraphQL::StaticValidation::VariablesAreInputTypesError.new(
            "#{type.graphql_name} isn't a valid input type (on $#{node.name})",
            nodes: node,
            name: node.name,
            type: type_name
          ))
        end

        super
      end

      private

      def get_type_name(ast_type)
        if ast_type.respond_to?(:of_type)
          get_type_name(ast_type.of_type)
        else
          ast_type.name
        end
      end
    end
  end
end
