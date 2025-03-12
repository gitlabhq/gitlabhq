# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::FieldExtension do
  module FilterTestSchema
    class DoubleFilter < GraphQL::Schema::FieldExtension
      def after_resolve(object:, value:, arguments:, context:, memo:)
        value * 2
      end
    end

    class PowerOfFilter < GraphQL::Schema::FieldExtension
      def after_resolve(object:, value:, arguments:, context:, memo:)
        value**options.fetch(:power, 2)
      end
    end

    class MultiplyByOption < GraphQL::Schema::FieldExtension
      def after_resolve(object:, value:, arguments:, context:, memo:)
        value * options[:factor]
      end
    end

    class MultiplyByArgument < GraphQL::Schema::FieldExtension
      def apply
        field.argument(:factor, Integer)
      end

      def resolve(object:, arguments:, context:)
        factor = arguments[:factor]
        yield(object, arguments, factor)
      end

      def after_resolve(object:, value:, arguments:, context:, memo:)
        value * memo
      end
    end

    class MultiplyByArgumentUsingResolve < GraphQL::Schema::FieldExtension
      def apply
        field.argument(:factor, Integer)
      end

      # `yield` returns the user-returned value
      # This method's return value is passed along
      def resolve(object:, arguments:, context:)
        factor = arguments[:factor]
        yield(object, arguments) * factor
      end
    end

    class MultiplyByArgumentUsingAfterResolve < GraphQL::Schema::FieldExtension
      def apply
        field.argument(:factor, Integer)
      end

      def resolve(object:, arguments:, context:)
        new_arguments = arguments.dup
        new_arguments.delete(:factor)
        yield(object, new_arguments, { original_arguments: arguments})
      end

      def after_resolve(object:, value:, arguments:, context:, memo:)
        value * memo[:original_arguments][:factor]
      end
    end

    class ExtendsArguments < GraphQL::Schema::FieldExtension
      def resolve(object:, arguments:, **_rest)
        new_args = arguments.dup
        new_args[:extended] = true
        yield(object, new_args)
      end

      def after_resolve(arguments:, context:, value:, **_rest)
        context[:extended_args] = arguments[:extended]
        value
      end
    end

    class ShortcutsResolve < GraphQL::Schema::FieldExtension
      def resolve(**_args)
        options[:shortcut_value]
      end
    end

    class ObjectClassExtension < GraphQL::Schema::FieldExtension
      def resolve(object:, **_args)
        object.class.name
      end

      def after_resolve(value:, object:, **_args)
        [object.class.name, value]
      end
    end

    class AddNestedExtensionExtension < GraphQL::Schema::FieldExtension
      def apply
        field.extension(NestedExtension)
      end

      class NestedExtension < GraphQL::Schema::FieldExtension
        def resolve(**_args)
          1
        end
      end
    end

    class BaseObject < GraphQL::Schema::Object
    end

    class Query < BaseObject
      field :doubled, Integer, null: false, resolver_method: :pass_thru do
        extension(DoubleFilter)
        argument :input, Integer
      end

      field :square, Integer, null: false, resolver_method: :pass_thru, extensions: [PowerOfFilter] do
        argument :input, Integer
      end

      field :cube, Integer, null: false, resolver_method: :pass_thru do
        extension(PowerOfFilter, power: 3)
        argument :input, Integer
      end

      field :tripled_by_option, Integer, null: false, resolver_method: :pass_thru do
        extension(MultiplyByOption, factor: 3)
        argument :input, Integer
      end

      field :tripled_by_option2, Integer, null: false, resolver_method: :pass_thru,
        extensions: [{ MultiplyByOption => { factor: 3 } }] do
          argument :input, Integer
        end

      field :multiply_input, Integer, null: false, resolver_method: :pass_thru, extensions: [MultiplyByArgument] do
        argument :input, Integer
      end

      field :multiply_input2, Integer, null: false, resolver_method: :pass_thru, extensions: [MultiplyByArgumentUsingResolve] do
        argument :input, Integer
      end

      def pass_thru(input:, **args)
        input # return it as-is, it will be modified by extensions
      end

      field :multiply_input3, Integer, null: false, resolver_method: :pass_thru_without_splat, extensions: [MultiplyByArgumentUsingAfterResolve] do
        argument :input, Integer
      end

      # lack of kwargs splat demonstrates the extended arguments are passed to the resolver method
      def pass_thru_without_splat(input:)
        input
      end

      field :multiple_extensions, Integer, null: false, resolver_method: :pass_thru,
        extensions: [DoubleFilter, { MultiplyByOption => { factor: 3 } }] do
          argument :input, Integer
        end

      field :extended_then_shortcut, Integer do
        extension ExtendsArguments
        extension ShortcutsResolve, shortcut_value: 3
      end

      field :object_class_test, [String], null: false, extensions: [ObjectClassExtension]

      field :nested_extension, Integer, null: false, extensions: [AddNestedExtensionExtension]
    end

    class Schema < GraphQL::Schema
      query(Query)
    end
  end

  def exec_query(query_str, **kwargs)
    FilterTestSchema::Schema.execute(query_str, **kwargs)
  end

  describe "object" do
    it "is the schema type object" do
      res = exec_query("{ objectClassTest }")
      assert_equal ["FilterTestSchema::Query", "FilterTestSchema::Query"], res["data"]["objectClassTest"]
    end
  end

  describe "reading" do
    it "has a reader method" do
      field = FilterTestSchema::Query.fields["multiplyInput"]
      assert_equal 1, field.extensions.size
      assert_instance_of FilterTestSchema::MultiplyByArgument, field.extensions.first
    end
  end

  describe "passing along extended arguments" do
    it "works even when shortcut" do
      ctx = {}
      res =  exec_query("{ extendedThenShortcut }", context: ctx)
      assert_equal 3, res["data"]["extendedThenShortcut"]
      assert_equal true, ctx[:extended_args]
    end
  end

  describe "modifying return values" do
    it "returns the modified value" do
      res = exec_query("{ doubled(input: 5) }")
      assert_equal 10, res["data"]["doubled"]
    end

    it "returns the modified value from `yield`" do
      res = exec_query("{ multiplyInput2(input: 5, factor: 5) }")
      assert_equal 25, res["data"]["multiplyInput2"]
    end

    it "has access to config options" do
      # The factor of three came from an option
      res = exec_query("{ tripledByOption(input: 4) }")
      assert_equal 12, res["data"]["tripledByOption"]
    end

    it "supports extension with options via extensions kwarg" do
      # The factor of three came from an option
      res = exec_query("{ tripledByOption2(input: 4) }")
      assert_equal 12, res["data"]["tripledByOption2"]
    end

    it "provides an empty hash as default options" do
      res = exec_query("{ square(input: 4) }")
      assert_equal 16, res["data"]["square"]
      res = exec_query("{ cube(input: 4) }")
      assert_equal 64, res["data"]["cube"]
    end

    it "can hide arguments from resolve methods" do
      res = exec_query("{ multiplyInput(input: 3, factor: 5) }")
      assert_equal 15, res["data"]["multiplyInput"]
    end

    it "calls the resolver method with the extended arguments" do
      res = exec_query("{ multiplyInput3(input: 3, factor: 5) }")
      assert_equal 15, res["data"]["multiplyInput3"]
    end

    it "supports multiple extensions via extensions kwarg" do
      # doubled then multiplied by 3 specified via option
      res = exec_query("{ multipleExtensions(input: 3) }")
      assert_equal 18, res["data"]["multipleExtensions"]
    end
  end

  describe "nested extension in apply method" do
    it "applies the nested extension" do
      res = exec_query("{ nestedExtension }")
      assert_equal 1, res["data"]["nestedExtension"]
    end
  end

  describe "after_define" do
    class AfterDefineThing < GraphQL::Schema::Object
      class AfterDefineExtension < GraphQL::Schema::FieldExtension
        attr_reader :apply_arguments_count, :after_define_arguments_count

        def apply
          @apply_arguments_count = field.all_argument_definitions.count
        end

        def after_define
          @after_define_arguments_count = field.all_argument_definitions.count
        end
      end

      field :with_extension, String, extensions: [AfterDefineExtension] do
        argument :something, ID
      end

      field :with_extension_2, String do
        extension(AfterDefineExtension)
        argument :something, ID
      end

      field :with_extension_3, String do
        argument :something, ID
        extension(AfterDefineExtension)
      end

      field :without_extension, String do
        argument :something, ID
      end
    end

    it "is applied after the define block when using `extensions: [...]`" do
      with_extension = AfterDefineThing.get_field("withExtension")
      ext = with_extension.extensions.first
      assert_equal 0, ext.apply_arguments_count
      assert_equal 1, ext.after_define_arguments_count
      assert ext.frozen?
    end

    it "applies in Ruby order when added in the define block" do
      with_extension_2_ext = AfterDefineThing.get_field("withExtension2").extensions.first
      assert_equal 0, with_extension_2_ext.apply_arguments_count
      assert_equal 1, with_extension_2_ext.after_define_arguments_count
      assert with_extension_2_ext.frozen?

      with_extension_3_ext = AfterDefineThing.get_field("withExtension3").extensions.first
      assert_equal 1, with_extension_3_ext.apply_arguments_count
      assert_equal 1, with_extension_3_ext.after_define_arguments_count
      assert with_extension_3_ext.frozen?
    end

    it "is called immediately when using `field.extension(...)`" do
      without_extension = AfterDefineThing.get_field("withoutExtension")
      without_extension.extension(AfterDefineThing::AfterDefineExtension)
      ext = without_extension.extensions.first
      assert_equal 1, ext.apply_arguments_count
      assert_equal 1, ext.after_define_arguments_count
      assert ext.frozen?
    end
  end

  describe ".default_argument" do
    class DefaultArgumentThing < GraphQL::Schema::Object
      class DefaultArgumentExtension < GraphQL::Schema::FieldExtension
        default_argument :query, String, required: false
      end

      field :search_1, String, extensions: [DefaultArgumentExtension]

      field :search_2, String, extensions: [DefaultArgumentExtension] do
        argument :query, String
      end
    end

    it "adds an argument if one wasn't given in the definition block" do
      search_1 = DefaultArgumentThing.get_field("search1")
      assert_equal [:query], search_1.extensions.first.added_default_arguments
      assert_equal GraphQL::Types::String, search_1.get_argument("query").type

      search_2 = DefaultArgumentThing.get_field("search2")
      assert_equal [], search_2.extensions.first.added_default_arguments
      assert_equal GraphQL::Types::String.to_non_null_type, search_2.get_argument("query").type
    end
  end

  describe ".extras" do
    class ExtensionExtrasSchema < GraphQL::Schema
      class AstNodeExtension < GraphQL::Schema::FieldExtension
        extras [:ast_node]
        def resolve(object:, arguments:, context:, **rest)
          context[:last_ast_node] = arguments[:ast_node]
          yield(object, arguments)
        end
      end

      class AnotherAstNodeExtension < AstNodeExtension
        def resolve(object:, arguments:, context:, **rest)
          context[:other_last_ast_node] = arguments[:ast_node]
          yield(object, arguments)
        end
      end

      class Query < GraphQL::Schema::Object
        field :f1, Int, extensions: [AstNodeExtension] do
          argument :i1, Int
        end

        def f1(i1:)
          i1
        end

        field :f2, Int, extensions: [AstNodeExtension], extras: [:ast_node]

        def f2(ast_node:)
          (ast_node.alias || "").size
        end

        field :f3, Int, extensions: [AstNodeExtension, AnotherAstNodeExtension] do
          argument :i1, Int
        end

        def f3(i1:)
          i1
        end
      end
      query(Query)
    end

    it "appends to the field's extras, but removes them when resolving" do
      assert_equal [:ast_node], ExtensionExtrasSchema::Query.get_field("f1").extras
      res = ExtensionExtrasSchema.execute("{ f1(i1: 1) }")
      assert_equal 1, res["data"]["f1"]
      assert_instance_of GraphQL::Language::Nodes::Field, res.context[:last_ast_node]
      assert_equal "f1", res.context[:last_ast_node].name
    end

    it "allows already-defined extras to pass thru" do
      res = ExtensionExtrasSchema.execute("{ something: f2 }")
      assert_equal 9, res["data"]["something"]
      assert_instance_of GraphQL::Language::Nodes::Field, res.context[:last_ast_node]
      assert_equal "f2", res.context[:last_ast_node].name
    end

    it "works with multiple extensions" do
      res = ExtensionExtrasSchema.execute("{ f3(i1: 3) }")
      assert_equal 3, res["data"]["f3"]
      assert_instance_of GraphQL::Language::Nodes::Field, res.context[:last_ast_node]
      assert_equal "f3", res.context[:last_ast_node].name
      assert_instance_of GraphQL::Language::Nodes::Field, res.context[:other_last_ast_node]
      assert_equal "f3", res.context[:other_last_ast_node].name
    end
  end
end
