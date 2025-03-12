# frozen_string_literal: true
require 'rails/generators'
require 'rails/generators/base'
require 'graphql'
require 'active_support'
require 'active_support/core_ext/string/inflections'
require_relative 'core'

module Graphql
  module Generators
    class TypeGeneratorBase < Rails::Generators::NamedBase
      include Core

      class_option :namespaced_types,
        type: :boolean,
        required: false,
        default: false,
        banner: "Namespaced",
        desc: "If the generated types will be namespaced"

      argument :custom_fields,
                type: :array,
                default: [],
                banner: "name:type name:type ...",
                desc: "Fields for this object (type may be expressed as Ruby or GraphQL)"

      
      attr_accessor :graphql_type

      def create_type_file
        template "#{graphql_type}.erb", "#{options[:directory]}/types#{subdirectory}/#{type_file_name}.rb"
      end

      # Take a type expression in any combination of GraphQL or Ruby styles
      # and return it in a specified output style
      # TODO: nullability / list with `mode: :graphql` doesn't work
      # @param type_expresson [String]
      # @param mode [Symbol]
      # @param null [Boolean]
      # @return [(String, Boolean)] The type expression, followed by `null:` value
      def self.normalize_type_expression(type_expression, mode:, null: true)
        if type_expression.start_with?("!")
          normalize_type_expression(type_expression[1..-1], mode: mode, null: false)
        elsif type_expression.end_with?("!")
          normalize_type_expression(type_expression[0..-2], mode: mode, null: false)
        elsif type_expression.start_with?("[") && type_expression.end_with?("]")
          name, is_null = normalize_type_expression(type_expression[1..-2], mode: mode, null: null)
          ["[#{name}]", is_null]
        elsif type_expression.end_with?("Type")
          normalize_type_expression(type_expression[0..-5], mode: mode, null: null)
        elsif type_expression.start_with?("Types::")
          normalize_type_expression(type_expression[7..-1], mode: mode, null: null)
        elsif type_expression.start_with?("types.")
          normalize_type_expression(type_expression[6..-1], mode: mode, null: null)
        else
          case mode
          when :ruby
            case type_expression
            when "Int"
              ["Integer", null]
            when "Integer", "Float", "Boolean", "String", "ID"
              [type_expression, null]
            else
              ["Types::#{type_expression.camelize}Type", null]
            end
          when :graphql
            [type_expression.camelize, null]
          else
            raise "Unexpected normalize mode: #{mode}"
          end
        end
      end

      private

      # @return [String] The user-provided type name, normalized to Ruby code
      def type_ruby_name
        @type_ruby_name ||= self.class.normalize_type_expression(name, mode: :ruby)[0]
      end

      # @return [String] The user-provided type name, as a GraphQL name
      def type_graphql_name
        @type_graphql_name ||= self.class.normalize_type_expression(name, mode: :graphql)[0]
      end

      # @return [String] The user-provided type name, as a file name (without extension)
      def type_file_name
        @type_file_name ||= "#{type_graphql_name}Type".underscore
      end

      # @return [Array<NormalizedField>] User-provided fields, in `(name, Ruby type name)` pairs
      def normalized_fields
        @normalized_fields ||= fields.map { |f|
          name, raw_type = f.split(":", 2)
          type_expr, null = self.class.normalize_type_expression(raw_type, mode: :ruby)
          NormalizedField.new(name, type_expr, null)
        }
      end

      def ruby_class_name
        class_prefix = 
          if options[:namespaced_types]
            "#{graphql_type.pluralize.camelize}::"
          else
            ""
          end
        @ruby_class_name || class_prefix + type_ruby_name.sub(/^Types::/, "")
      end

      def subdirectory
        if options[:namespaced_types]
          "/#{graphql_type.pluralize}"
        else
          ""
        end
      end

      class NormalizedField
        def initialize(name, type_expr, null)
          @name = name
          @type_expr = type_expr
          @null = null
        end

        def to_object_field
          "field :#{@name}, #{@type_expr}#{@null ? '' : ', null: false'}"
        end

        def to_input_argument
          "argument :#{@name}, #{@type_expr}, required: false"
        end
      end
    end
  end
end
