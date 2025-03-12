# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::Generation do
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
  a: String!
}
      SCHEMA

      assert_equal expected.chomp, GraphQL::Language::Generation.generate(document)
    end

    it "accepts a custom printer" do
      expected = <<-SCHEMA
type Query {
  <Field Hidden>
}
      SCHEMA

      assert_equal expected.chomp, GraphQL::Language::Generation.generate(document, printer: custom_printer_class.new)
    end
  end
end
