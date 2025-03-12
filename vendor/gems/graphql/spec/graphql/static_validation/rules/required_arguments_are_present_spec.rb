# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::RequiredArgumentsArePresent do
  include StaticValidationHelpers
  let(:query_string) {"
    query getCheese {
      okCheese: cheese(id: 1) { ...cheeseFields }
      cheese { source }
    }

    fragment cheeseFields on Cheese {
      similarCheese { __typename }
      flavor @include(if: true)
      id @skip
    }
  "}

  it "finds undefined arguments to fields and directives" do
    assert_equal(3, errors.length)

    query_root_error = {
      "message"=>"Field 'cheese' is missing required arguments: id",
      "locations"=>[{"line"=>4, "column"=>7}],
      "path"=>["query getCheese", "cheese"],
      "extensions"=>{"code"=>"missingRequiredArguments", "className"=>"Field", "name"=>"cheese", "arguments"=>"id"}
    }
    assert_includes(errors, query_root_error)

    fragment_error = {
      "message"=>"Field 'similarCheese' is missing required arguments: source",
      "locations"=>[{"line"=>8, "column"=>7}],
      "path"=>["fragment cheeseFields", "similarCheese"],
      "extensions"=>{"code"=>"missingRequiredArguments", "className"=>"Field", "name"=>"similarCheese", "arguments"=>"source"}
    }
    assert_includes(errors, fragment_error)

    directive_error = {
      "message"=>"Directive 'skip' is missing required arguments: if",
      "locations"=>[{"line"=>10, "column"=>10}],
      "path"=>["fragment cheeseFields", "id"],
      "extensions"=>{"code"=>"missingRequiredArguments", "className"=>"Directive", "name"=>"skip", "arguments"=>"if"}
    }
    assert_includes(errors, directive_error)
  end

  describe "dynamic fields" do
    let(:query_string) {"
      query {
        __type { name }
      }
    "}

    it "finds undefined required arguments" do
      expected_errors = [
        {
          "message"=>"Field '__type' is missing required arguments: name",
          "locations"=>[
            {"line"=>3, "column"=>9}
          ],
          "path"=>["query", "__type"],
          "extensions"=>{
            "code"=>"missingRequiredArguments",
            "className"=>"Field",
            "name"=>"__type",
            "arguments"=>"name"
          }
        }
      ]
      assert_equal(expected_errors, errors)
    end
  end

  describe "when a required arg is hidden" do
    class Query < GraphQL::Schema::Object
      field :int, Integer do
        argument :input, Integer do
          def visible?(*)
            false
          end
        end
      end

      def int(input: -1)
        input
      end
    end

    class HiddenArgSchema < GraphQL::Schema
      use GraphQL::Schema::Warden if ADD_WARDEN
      query(Query)
    end

    it "Doesn't require a hidden input" do
      res = HiddenArgSchema.execute("{ int }")
      assert_equal(-1, res["data"]["int"])
    end
  end
end
