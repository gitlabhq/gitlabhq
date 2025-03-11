# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module ArgumentNamesAreUnique
      include GraphQL::StaticValidation::Error::ErrorHelper

      def on_field(node, parent)
        validate_arguments(node)
        super
      end

      def on_directive(node, parent)
        validate_arguments(node)
        super
      end

      def validate_arguments(node)
        argument_defns = node.arguments
        if !argument_defns.empty?
          args_by_name = Hash.new { |h, k| h[k] = [] }
          argument_defns.each { |a| args_by_name[a.name] << a }
          args_by_name.each do |name, defns|
            if defns.size > 1
              add_error(GraphQL::StaticValidation::ArgumentNamesAreUniqueError.new("There can be only one argument named \"#{name}\"", nodes: defns, name: name))
            end
          end
        end
      end
    end
  end
end
