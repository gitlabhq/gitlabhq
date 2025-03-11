# frozen_string_literal: true
require 'rails/generators/base'

module Graphql
  module Generators
    module FieldExtractor
      def fields
        columns = []
        columns += (klass&.columns&.map { |c| generate_column_string(c) }  || [])
        columns + custom_fields
      end

      def generate_column_string(column)
        name = column.name
        required = column.null ? "" : "!"
        type = column_type_string(column)
        "#{name}:#{required}#{type}"
      end

      def column_type_string(column)
        column.name == "id" ? "ID" : column.type.to_s.camelize
      end

      def klass
        @klass ||= Module.const_get(name.camelize)
      rescue NameError
        @klass = nil
      end
    end
  end
end
