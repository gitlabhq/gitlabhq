# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module FragmentNamesAreUnique

      def initialize(*)
        super
        @fragments_by_name = Hash.new { |h, k| h[k] = [] }
      end

      def on_fragment_definition(node, parent)
        @fragments_by_name[node.name] << node
        super
      end

      def on_document(_n, _p)
        super
        @fragments_by_name.each do |name, fragments|
          if fragments.length > 1
            add_error(GraphQL::StaticValidation::FragmentNamesAreUniqueError.new(
              %|Fragment name "#{name}" must be unique|,
              nodes: fragments,
              name: name
            ))
          end
        end
      end
    end
  end
end
