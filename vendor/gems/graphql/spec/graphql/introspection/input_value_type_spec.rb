# frozen_string_literal: true
require "spec_helper"


describe GraphQL::Introspection::InputValueType do
  let(:query_string) {%|
     {
       __type(name: "DairyProductInput") {
         name
         description
         kind
         inputFields {
           name
           type { kind, name }
           defaultValue
           description
         }
       }
     }
  |}
  let(:result) { Dummy::Schema.execute(query_string) }

  it "exposes metadata about input objects, giving extra quotes for strings" do
    expected = { "data" => {
        "__type" => {
          "name"=>"DairyProductInput",
          "description"=>"Properties for finding a dairy product",
          "kind"=>"INPUT_OBJECT",
          "inputFields"=>[
            {"name"=>"source", "type"=>{"kind"=>"NON_NULL", "name" => nil}, "defaultValue"=>nil,
             "description" => "Where it came from"},
            {"name"=>"originDairy", "type"=>{"kind"=>"SCALAR", "name" => "String"}, "defaultValue"=>"\"Sugar Hollow Dairy\"",
             "description" => "Dairy which produced it"},
            {"name"=>"fatContent", "type"=>{"kind"=>"SCALAR",  "name" => "Float"}, "defaultValue"=>"0.3",
             "description" => "How much fat it has"},
            {"name"=>"organic", "type"=>{"kind"=>"SCALAR",  "name" => "Boolean"}, "defaultValue"=>"false",
             "description" => nil},
            {"name"=>"order_by", "type"=>{"kind"=>"INPUT_OBJECT", "name"=>"ResourceOrderType"}, "defaultValue"=>"{direction: \"ASC\"}",
             "description" => nil},
          ]
        }
      }}
    assert_equal(expected, result.to_h)
  end

  let(:cheese_type) {
    Dummy::Schema.execute(%|
      {
        __type(name: "Cheese") {
          fields {
            name
            args {
              name
              defaultValue
            }
          }
        }
      }
    |)
  }

  it "converts default values to GraphQL values" do
    field = cheese_type['data']['__type']['fields'].detect { |f| f['name'] == 'similarCheese' }
    arg = field['args'].detect { |a| a['name'] == 'nullableSource' }

    assert_equal('[COW]', arg['defaultValue'])
  end

  it "supports list of enum default values" do
    schema = GraphQL::Schema.from_definition(%|
      type Query {
        hello(enums: [MyEnum] = [A, B]): String
      }

      enum MyEnum {
        A
        B
      }
    |)

    result = schema.execute(%|
      {
        __type(name: "Query") {
          fields {
            args {
              defaultValue
            }
          }
        }
      }
    |)

    expected = {
      "data" => {
        "__type" => {
          "fields" => [{
            "args" => [{
              "defaultValue" => "[A, B]"
            }]
          }]
        }
      }
    }

    assert_equal expected, result
  end

  it "supports null default values" do
    schema = GraphQL::Schema.from_definition(%|
      type Query {
        hello(person: Person): String
      }

      input Person {
        firstName: String!
        lastName: String = null
      }
    |)

    result = schema.execute(%|
      {
        __type(name: "Person") {
          inputFields {
            name
            defaultValue
          }
        }
      }
    |)

    expected = {
      "data" => {
        "__type" => {
          "inputFields" => [
            { "name" => "firstName", "defaultValue" => nil},
            { "name" => "lastName", "defaultValue" => "null"}
          ]
        }
      }
    }

    assert_equal expected, result
  end
end
