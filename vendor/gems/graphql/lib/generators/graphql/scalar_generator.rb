# frozen_string_literal: true
require 'generators/graphql/type_generator'

module Graphql
  module Generators
    # Generate a scalar type by given name.
    #
    # ```
    # rails g graphql:scalar Date
    # ```
    class ScalarGenerator < TypeGeneratorBase
      desc "Create a GraphQL::ScalarType with the given name"
      source_root File.expand_path('../templates', __FILE__)

      private

      def graphql_type
        "scalar"
      end
    end
  end
end
