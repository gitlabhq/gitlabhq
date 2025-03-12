# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::Nodes::AbstractNode do
  describe ".visit_method" do
    # `.visit_method` is really helpful for generating methods in
    # custom visitor classes -- make sure this API keeps working.
    it "names a method on the visitor class" do
      node_classes = GraphQL::Language::Nodes.constants
        .map { |c| GraphQL::Language::Nodes.const_get(c) }
        .select { |obj| obj.is_a?(Class) && obj < GraphQL::Language::Nodes::AbstractNode }


      node_classes -= [GraphQL::Language::Nodes::WrapperType, GraphQL::Language::Nodes::NameOnlyNode]
      expected_classes = 35
      assert_equal 35, node_classes.size
      tested_classes = 0
      node_classes.each do |node_class|
        expected_method_name = "on_#{GraphQL::Schema::Member::BuildType.underscore(node_class.name.split("::").last)}"
        assert_equal node_class.visit_method.to_s, expected_method_name, "#{node_class} has #{expected_method_name} for visit_method"
        assert GraphQL::Language::Visitor.method_defined?(expected_method_name), "Visitor has ##{expected_method_name}"
        assert GraphQL::Language::StaticVisitor.method_defined?(expected_method_name), "Visitor has ##{expected_method_name}"
        tested_classes += 1
      end
      assert_equal expected_classes, tested_classes, "All classes were tested"
    end
  end

  describe "Marshal" do
    it "marshals and unmarshals parsed ASTs" do
      str = "query($var: [Int!] = [100001]) {
  f1(arg: {input: $var, nullInput: null}) @stuff {
    ...F2
  }
}

fragment F2 on SomeType {
  ... {
    someField(arg1: true, arg2: THING, arg3: 5.01234) {
      a @someDirective @anotherDirective @yetAnother
      b
      c
    }
  }
}"
      doc = GraphQL.parse(str)
      data = Marshal.dump(doc)
      new_doc = Marshal.load(data)
      assert_equal doc, new_doc
      assert_equal str, doc.to_query_string
      assert_equal str, new_doc.to_query_string

      # also test schema definition nodes:
      str2 = Dummy::Schema.to_definition.strip
      doc2 = GraphQL.parse(str2)
      data2 = Marshal.dump(doc2)
      new_doc2 = Marshal.load(data2)
      assert_equal doc, new_doc
      assert_equal str2, doc2.to_query_string
      assert_equal str2, new_doc2.to_query_string
    end
  end

  describe "#filename" do
    it "is set after .parse_file" do
      filename = "spec/support/parser/filename_example.graphql"
      doc = GraphQL.parse_file(filename)
      op = doc.definitions.first
      field = op.selections.first
      arg = field.arguments.first

      assert_equal filename, doc.filename
      assert_equal filename, op.filename
      assert_equal filename, field.filename
      assert_equal filename, arg.filename
    end

    it "is null when parse from string" do
      doc = GraphQL.parse("{ thing }")
      assert_nil doc.filename
    end
  end

  describe "#to_query_tring" do
    let(:document) {
      GraphQL.parse('type Query { a: String! }')
    }

    let(:custom_printer_class) {
      Class.new(GraphQL::Language::Printer) {
        def print_field_definition(print_field_definition)
          print_string("<Field Hidden>")
        end
      }
    }

    it "accepts a custom printer" do
      expected = <<-SCHEMA
type Query {
  <Field Hidden>
}
      SCHEMA
      assert_equal expected.chomp, document.to_query_string(printer: custom_printer_class.new)
    end
  end

  describe "#dup" do
    it "works with adding selections" do
      f = GraphQL::Language::Nodes::Field.new(name: "f")
      # Calling `.children` may populate an internal cache
      assert_equal "f", f.to_query_string, "the original is unchanged"
      assert_equal 0, f.children.size
      assert_equal 0, f.selections.size

      f2 = f.merge(selections: [GraphQL::Language::Nodes::Field.new(name: "__typename")])

      assert_equal "f", f.to_query_string, "the original is unchanged"
      assert_equal 0, f.children.size
      assert_equal 0, f.selections.size

      assert_equal "f {\n  __typename\n}", f2.to_query_string, "the duplicate is updated"
      assert_equal 1, f2.children.size
      assert_equal 1, f2.selections.size
    end
  end

  describe "merge_methods" do
    it "generates merge methods" do
      classes_to_test = {
        GraphQL::Language::Nodes::Argument => [],
        GraphQL::Language::Nodes::Directive => [:merge_argument],
        GraphQL::Language::Nodes::DirectiveDefinition => [:merge_argument, :merge_location],
        GraphQL::Language::Nodes::DirectiveLocation => [],
        GraphQL::Language::Nodes::Document => [],
        GraphQL::Language::Nodes::Enum => [],
        GraphQL::Language::Nodes::EnumTypeDefinition => [:merge_directive, :merge_value],
        GraphQL::Language::Nodes::EnumTypeExtension => [:merge_directive, :merge_value],
        GraphQL::Language::Nodes::EnumValueDefinition => [:merge_directive],
        GraphQL::Language::Nodes::Field => [:merge_argument, :merge_directive, :merge_selection],
        GraphQL::Language::Nodes::FieldDefinition => [:merge_argument, :merge_directive],
        GraphQL::Language::Nodes::FragmentDefinition => [:merge_directive, :merge_selection],
        GraphQL::Language::Nodes::FragmentSpread => [:merge_directive],
        GraphQL::Language::Nodes::InlineFragment => [:merge_directive, :merge_selection],
        GraphQL::Language::Nodes::InputObject => [:merge_argument],
        GraphQL::Language::Nodes::InputObjectTypeDefinition => [:merge_directive, :merge_field],
        GraphQL::Language::Nodes::InputObjectTypeExtension => [:merge_directive, :merge_field],
        GraphQL::Language::Nodes::InputValueDefinition => [:merge_directive],
        GraphQL::Language::Nodes::InterfaceTypeDefinition => [:merge_directive, :merge_field, :merge_interface],
        GraphQL::Language::Nodes::InterfaceTypeExtension => [:merge_directive, :merge_field, :merge_interface],
        GraphQL::Language::Nodes::ListType => [],
        GraphQL::Language::Nodes::NonNullType => [],
        GraphQL::Language::Nodes::NullValue => [],
        GraphQL::Language::Nodes::ObjectTypeDefinition => [:merge_directive, :merge_field],
        GraphQL::Language::Nodes::ObjectTypeExtension => [:merge_directive, :merge_field],
        GraphQL::Language::Nodes::OperationDefinition => [:merge_directive, :merge_selection, :merge_variable],
        GraphQL::Language::Nodes::ScalarTypeDefinition => [:merge_directive],
        GraphQL::Language::Nodes::ScalarTypeExtension => [:merge_directive],
        GraphQL::Language::Nodes::SchemaDefinition => [:merge_directive],
        GraphQL::Language::Nodes::SchemaExtension => [:merge_directive],
        GraphQL::Language::Nodes::TypeName => [],
        GraphQL::Language::Nodes::UnionTypeDefinition => [:merge_directive],
        GraphQL::Language::Nodes::UnionTypeExtension => [:merge_directive],
        GraphQL::Language::Nodes::VariableDefinition => [:merge_directive],
        GraphQL::Language::Nodes::VariableIdentifier => []
      }

      classes_to_test.each do |cls, expected_methods|
        assert cls.instance_methods.include?(:merge), "#{cls} has a merge method"
        assert cls.instance_methods.include?(:merge!), "#{cls} has a merge! method"
        assert_equal expected_methods, cls.instance_methods.select { |m| m.start_with?("merge_")}.sort, "#{cls} has the expected merge children methods"
      end
    end

    it "makes copies with merged children" do
      node_1 = GraphQL::Language::Nodes::Field.new(
        name: "f1",
        field_alias: "myField"
      )

      node_2 = node_1
        .merge_argument(name: "arg1", value: 5)
        .merge_directive(name: "topSecret")
        .merge_argument(name: "arg2", value: GraphQL::Language::Nodes::Enum.new(name: "HELLO"))
        .merge_selection(name: "f2", field_alias: "myOtherField")

      assert_equal "myField: f1", node_1.to_query_string
      assert_equal "myField: f1(arg1: 5, arg2: HELLO) @topSecret {\n  myOtherField: f2\n}", node_2.to_query_string
    end
  end

  describe "manually-created AST nodes" do
    it "works with line and column" do
      node = GraphQL::Language::Nodes::Document.new(
        definitions: [
          GraphQL::Language::Nodes::OperationDefinition.new(
            operation_type: "query",
            selections: [
              GraphQL::Language::Nodes::Field.new(name: "f1"),
              GraphQL::Language::Nodes::FragmentSpread.new(name: "DoesntExist")
            ]
          )
        ]
      )

      assert_equal "query {\n  f1\n  ...DoesntExist\n}", node.to_query_string

      schema = GraphQL::Schema.from_definition <<-GRAPHQL
        type Query {
          f1: String
        }
      GRAPHQL
      result = GraphQL::StaticValidation::Validator.new(schema: schema).validate(GraphQL::Query.new(schema, nil, document: node))
      expected_errs = [
        {
          "message"=>"Fragment DoesntExist was used, but not defined",
          "locations"=>[{"line"=>nil, "column"=>nil}],
          "path"=>["query", "... DoesntExist"],
          "extensions"=> {
            "code"=>"useAndDefineFragment",
            "fragmentName"=>"DoesntExist"
          }
        }
      ]
      assert_equal expected_errs, result[:errors].map(&:to_h)
    end
  end
end
