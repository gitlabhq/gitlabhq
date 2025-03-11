# frozen_string_literal: true
require 'generators/graphql/type_generator'

module Graphql
  module Generators
    # Generate a union type by name
    # with the specified member types.
    #
    # ```
    # rails g graphql:union SearchResultType ImageType AudioType
    # ```
    class UnionGenerator < TypeGeneratorBase
      desc "Create a GraphQL::UnionType with the given name and possible types"
      source_root File.expand_path('../templates', __FILE__)

      argument :possible_types,
        type: :array,
        default: [],
        banner: "type type ...",
        desc: "Possible types for this union (expressed as Ruby or GraphQL)"

      private

      def graphql_type
        "union"
      end

      def normalized_possible_types
        custom_fields.map { |t| self.class.normalize_type_expression(t, mode: :ruby)[0] }
      end
    end
  end
end
