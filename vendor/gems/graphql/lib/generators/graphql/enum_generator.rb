# frozen_string_literal: true
require 'generators/graphql/type_generator'

module Graphql
  module Generators
    # Generate an enum type by name, with the given values.
    # To add a `value:` option, add another value after a `:`.
    #
    # ```
    # rails g graphql:enum ProgrammingLanguage RUBY PYTHON PERL PERL6:"PERL"
    # ```
    class EnumGenerator < TypeGeneratorBase
      desc "Create a GraphQL::EnumType with the given name and values"
      source_root File.expand_path('../templates', __FILE__)

      private

      def graphql_type
        "enum"
      end

      def prepared_values
        custom_fields.map { |v| v.split(":", 2) }
      end
    end
  end
end
