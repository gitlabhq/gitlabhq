# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::ArgumentsAreDefined do
  include StaticValidationHelpers

  let(:query_string) {"
    query getCheese {
      okCheese: cheese(id: 1) { source }
      cheese(silly: false, id: 2) { source }
      searchDairy(product: [{wacky: 1}]) { ...cheeseFields }
    }

    fragment cheeseFields on Cheese {
      similarCheese(source: SHEEP, nonsense: 1) { __typename }
      id @skip(something: 3.4, if: false)
    }
  "}

  describe "finds undefined arguments to fields and directives" do
    it "works" do
      assert_equal(5, errors.length)

      extra_error = {
        "message"=>"Argument 'product' on Field 'searchDairy' has an invalid value. Expected type '[DairyProductInput]'.",
        "locations"=>[{"line"=>5, "column"=>7}],
        "path"=>["query getCheese", "searchDairy", "product"]
      }
      refute_includes(errors, extra_error)
    end
  end

  describe "dynamic fields" do
    let(:query_string) {"
      query {
        __type(somethingInvalid: 1, nme: \"something\") { name }
      }
    "}

    it "finds undefined arguments" do
      assert_includes(errors, {
        "message"=>"Field '__type' doesn't accept argument 'somethingInvalid'",
        "locations"=>[{"line"=>3, "column"=>16}],
        "path"=>["query", "__type", "somethingInvalid"],
        "extensions"=>{"code"=>"argumentNotAccepted", "name"=>"__type", "typeName"=>"Field", "argumentName"=>"somethingInvalid"}
      })
      assert_includes(errors, {
        "message"=>"Field '__type' doesn't accept argument 'nme' (Did you mean `name`?)",
        "locations"=>[{"line"=>3, "column"=>37}],
        "path"=>["query", "__type", "nme"],
        "extensions"=>{"code"=>"argumentNotAccepted", "name"=>"__type", "typeName"=>"Field", "argumentName"=>"nme"}
      })
    end
  end

  describe "error references argument's parent" do
    let(:validator) { GraphQL::StaticValidation::Validator.new(schema: schema) }
    let(:query) { GraphQL::Query.new(schema, query_string) }
    let(:errors) { validator.validate(query)[:errors] }
    let(:query_string) {"
      query {
        cheese(silly: true, id: 1) { source }
        milk(id: 1) { source @skip(something: 3.4, if: false) }
      }
    "}

    it "works with field" do
      query_cheese_field = schema.types['Query'].fields['cheese']
      error = errors.find { |error| error.argument_name == 'silly' }

      assert_equal query_cheese_field, error.parent
    end

    it "works with directive" do
      skip_directive = schema.directives['skip']
      error = errors.find { |error| error.argument_name == 'something' }

      assert_equal skip_directive, error.parent
    end
  end
end
