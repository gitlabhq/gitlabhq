# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module FragmentTypesExist
      def on_fragment_definition(node, _parent)
        if validate_type_exists(node)
          super
        end
      end

      def on_inline_fragment(node, _parent)
        if validate_type_exists(node)
          super
        end
      end

      private

      def validate_type_exists(fragment_node)
        if !fragment_node.type
          true
        else
          type_name = fragment_node.type.name
          type = @types.type(type_name)
          if type.nil?
            @all_possible_fragment_type_names ||= begin
              names = []
              context.types.all_types.each do |type|
                if type.kind.fields?
                  names << type.graphql_name
                end
              end
              names
            end

            add_error(GraphQL::StaticValidation::FragmentTypesExistError.new(
              "No such type #{type_name}, so it can't be a fragment condition#{context.did_you_mean_suggestion(type_name, @all_possible_fragment_type_names)}",
              nodes: fragment_node,
              type: type_name
            ))
            false
          else
            true
          end
        end
      end
    end
  end
end
