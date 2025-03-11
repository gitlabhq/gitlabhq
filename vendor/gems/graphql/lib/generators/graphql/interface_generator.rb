# frozen_string_literal: true
require 'generators/graphql/type_generator'

module Graphql
  module Generators
    # Generate an interface type by name,
    # with the specified fields.
    #
    # ```
    # rails g graphql:interface NamedEntityType name:String!
    # ```
    class InterfaceGenerator < TypeGeneratorBase
      desc "Create a GraphQL::InterfaceType with the given name and fields"
      source_root File.expand_path('../templates', __FILE__)

      private

      def graphql_type
        "interface"
      end

      def fields
        custom_fields
      end
    end
  end
end
