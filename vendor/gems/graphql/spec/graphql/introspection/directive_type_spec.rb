# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Introspection::DirectiveType do
  let(:query_string) {%|
    query getDirectives {
      __schema {
        directives {
          name,
          args { name, type { kind, name, ofType { name } } },
          locations
          isRepeatable
          # Deprecated fields:
          onField
          onFragment
          onOperation
        }
      }
    }
  |}

  let(:directive_with_deprecated_arg) do
    Class.new(GraphQL::Schema::Directive) do
      graphql_name "customTransform"
      locations GraphQL::Schema::Directive::FIELD
      argument :old_way, String, required: false, deprecation_reason: "Use the newWay"
      argument :new_way, String, required: false
    end
  end

  let(:schema) { Class.new(Dummy::Schema) { directive(Class.new(GraphQL::Schema::Directive) { graphql_name("doStuff"); repeatable(true) })}}
  let(:result) { schema.execute(query_string) }
  before do
    schema.max_depth(100)
  end

  it "shows directive info " do
    expected = { "data" => {
      "__schema" => {
        "directives" => [
          {
            "name" => "deprecated",
            "args" => [
              {"name"=>"reason", "type"=>{"kind"=>"SCALAR", "name"=>"String", "ofType"=>nil}}
            ],
            "locations"=>["FIELD_DEFINITION", "ENUM_VALUE", "ARGUMENT_DEFINITION", "INPUT_FIELD_DEFINITION"],
            "isRepeatable" => false,
            "onField" => false,
            "onFragment" => false,
            "onOperation" => false,
          },
          {
            "name"=>"directiveForVariableDefinition",
            "args"=>[],
            "locations"=>["VARIABLE_DEFINITION"],
            "isRepeatable"=>false,
            "onField"=>false,
            "onFragment"=>false,
            "onOperation"=>false,
          },
          {
            "name"=>"doStuff",
            "args"=>[],
            "locations"=>[],
            "isRepeatable"=>true,
            "onField"=>false,
            "onFragment"=>false,
            "onOperation"=>false,
          },
          {
            "name" => "include",
            "args" => [
              {"name"=>"if", "type"=>{"kind"=>"NON_NULL", "name"=>nil, "ofType"=>{"name"=>"Boolean"}}}
            ],
            "locations"=>["FIELD", "FRAGMENT_SPREAD", "INLINE_FRAGMENT"],
            "isRepeatable" => false,
            "onField" => true,
            "onFragment" => true,
            "onOperation" => false,
          },
          {
            "name" => "oneOf",
            "args" => [],
            "locations"=>["INPUT_OBJECT"],
            "isRepeatable" => false,
            "onField" => false,
            "onFragment" => false,
            "onOperation" => false,
          },
          {
            "name" => "skip",
            "args" => [
              {"name"=>"if", "type"=>{"kind"=>"NON_NULL", "name"=>nil, "ofType"=>{"name"=>"Boolean"}}}
            ],
            "locations"=>["FIELD", "FRAGMENT_SPREAD", "INLINE_FRAGMENT"],
            "isRepeatable" => false,
            "onField" => true,
            "onFragment" => true,
            "onOperation" => false,
          },
          {
            "name" => "specifiedBy",
            "args" => [
              {"name"=>"url", "type"=>{"kind"=>"NON_NULL", "name"=>nil, "ofType"=>{"name"=>"String"}}}
            ],
            "locations"=>["SCALAR"],
            "isRepeatable" => false,
            "onField" => false,
            "onFragment" => false,
            "onOperation" => false,
          },
        ]
      }
    }}
    assert_equal(expected, result.to_h)
  end

  it "hides deprecated arguments by default" do
    schema.directive(directive_with_deprecated_arg)
    result = schema.execute <<-GRAPHQL
      {
        __schema {
          directives {
            name
            args {
              name
            }
          }
        }
      }
    GRAPHQL

    directive_result = result["data"]["__schema"]["directives"].find { |d| d["name"] == "customTransform" }
    expected = [
      {"name" => "newWay"}
    ]
    assert_equal(expected, directive_result["args"])
  end

  it "can expose deprecated arguments" do
    schema.directive(directive_with_deprecated_arg)
    result = schema.execute <<-GRAPHQL
      {
        __schema {
          directives {
            name
            args(includeDeprecated: true) {
              name
              isDeprecated
              deprecationReason
            }
          }
        }
      }
    GRAPHQL

    directive_result = result["data"]["__schema"]["directives"].find { |d| d["name"] == "customTransform" }
    expected = [
      {"name" => "oldWay", "isDeprecated" => true, "deprecationReason" => "Use the newWay"},
      {"name" => "newWay", "isDeprecated" => false, "deprecationReason" => nil}
    ]
    assert_equal(expected, directive_result["args"])
  end
end
