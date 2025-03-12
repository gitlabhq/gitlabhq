# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module FragmentsAreUsed
      def on_document(node, parent)
        super
        dependency_map = context.dependencies
        dependency_map.unmet_dependencies.each do |op_defn, spreads|
          spreads.each do |fragment_spread|
            add_error(GraphQL::StaticValidation::FragmentsAreUsedError.new(
              "Fragment #{fragment_spread.name} was used, but not defined",
              nodes: fragment_spread.node,
              path: fragment_spread.path,
              fragment: fragment_spread.name
            ))
          end
        end

        dependency_map.unused_dependencies.each do |fragment|
          if fragment && !fragment.name.nil?
            add_error(GraphQL::StaticValidation::FragmentsAreUsedError.new(
              "Fragment #{fragment.name} was defined, but not used",
              nodes: fragment.node,
              path: fragment.path,
              fragment: fragment.name
            ))
          end
        end
      end
    end
  end
end
