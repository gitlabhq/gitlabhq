# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Introspection::TypeType do
  let(:query_string) {%|
     query introspectionQuery {
       cheeseType:    __type(name: "Cheese") { name, kind, fields { name, isDeprecated, type { kind, name, ofType { name } } } }
       milkType:      __type(name: "Milk") { interfaces { name }, fields { type { kind, name, ofType { name } } } }
       dairyAnimal:   __type(name: "DairyAnimal") { name, kind, enumValues(includeDeprecated: false) { name, isDeprecated } }
       dairyProduct:  __type(name: "DairyProduct") { name, kind, possibleTypes { name } }
       animalProduct: __type(name: "AnimalProduct") { name, kind, specifiedByURL, possibleTypes { name }, fields { name } }
       missingType:   __type(name: "NotAType") { name }
       timeType:      __type(name: "Time") { specifiedByURL }
     }
  |}
  let(:result) { Dummy::Schema.execute(query_string, context: {}, variables: {"cheeseId" => 2}) }
  let(:cheese_fields) {[
    {"name"=>"dairyProduct", "isDeprecated" => false, "type"=>{"kind"=>"UNION", "name"=>"DairyProduct", "ofType"=>nil}},
    {"name"=>"deeplyNullableCheese", "isDeprecated" => false, "type"=>{ "kind" => "OBJECT", "name" => "Cheese", "ofType" => nil}},
    {"name"=>"flavor",      "isDeprecated" => false, "type" => { "kind" => "NON_NULL", "name" => nil, "ofType" => { "name" => "String"}}},
    {"name"=>"id",          "isDeprecated" => false, "type" => { "kind" => "NON_NULL", "name" => nil, "ofType" => { "name" => "Int"}}},
    {"name"=>"nullableCheese", "isDeprecated"=>false, "type"=>{ "kind" => "OBJECT",  "name" => "Cheese", "ofType"=>nil}},
    {"name"=>"origin",      "isDeprecated" => false, "type" => { "kind" => "NON_NULL", "name" => nil, "ofType" => { "name" => "String"}}},
    {"name"=>"selfAsEdible", "isDeprecated"=>false, "type"=>{"kind"=>"INTERFACE", "name"=>"Edible", "ofType"=>nil}},
    {"name"=>"similarCheese", "isDeprecated"=>false, "type"=>{ "kind" => "OBJECT", "name"=>"Cheese", "ofType"=>nil}},
    {"name"=>"source",      "isDeprecated" => false, "type" => { "kind" => "NON_NULL", "name" => nil, "ofType" => { "name" => "DairyAnimal"}}},
  ]}

  let(:dairy_animals) {[
    {"name"=>"NONE",       "isDeprecated"=> false },
    {"name"=>"COW",       "isDeprecated"=> false },
    {"name"=>"DONKEY",    "isDeprecated"=> false },
    {"name"=>"GOAT",      "isDeprecated"=> false },
    {"name"=>"REINDEER",  "isDeprecated"=> false },
    {"name"=>"SHEEP",     "isDeprecated"=> false },
  ]}
  it "exposes metadata about types" do
    expected = {"data"=> {
      "cheeseType" => {
        "name"=> "Cheese",
        "kind" => "OBJECT",
        "fields"=> cheese_fields
      },
      "milkType"=>{
        "interfaces"=>[
          {"name"=>"AnimalProduct"},
          {"name"=>"Edible"},
          {"name"=>"EdibleAsMilk"},
          {"name"=>"LocalProduct"},
        ],
        "fields"=>[
          {"type"=>{"kind"=>"LIST","name"=>nil, "ofType"=>{"name"=>"DairyProduct"}}},
          {"type"=>{"kind"=>"SCALAR","name"=>"String", "ofType"=>nil}},
          {"type"=>{"kind"=>"NON_NULL","name"=>nil, "ofType"=>{"name"=>"Float"}}},
          {"type"=>{"kind"=>"LIST","name"=>nil, "ofType"=>{"name"=>"String"}}},
          {"type"=>{"kind"=>"NON_NULL","name"=>nil, "ofType"=>{"name"=>"ID"}}},
          {"type"=>{"kind"=>"NON_NULL","name"=>nil, "ofType"=>{"name"=>"String"}}},
          {"type"=>{"kind"=>"INTERFACE", "name"=>"Edible", "ofType"=>nil}},
          {"type"=>{"kind"=>"NON_NULL","name"=>nil,"ofType"=>{"name"=>"DairyAnimal"}}},
        ]
      },
      "dairyAnimal"=>{
        "name"=>"DairyAnimal",
        "kind"=>"ENUM",
        "enumValues"=> dairy_animals,
      },
      "dairyProduct"=>{
        "name"=>"DairyProduct",
        "kind"=>"UNION",
        "possibleTypes"=>[{"name"=>"Cheese"}, {"name"=>"Milk"}],
      },
      "animalProduct" => {
        "name"=>"AnimalProduct",
        "kind"=>"INTERFACE",
        "specifiedByURL" => nil,
        "possibleTypes"=>[{"name"=>"Cheese"}, {"name"=>"Honey"}, {"name"=>"Milk"}],
        "fields"=>[
          {"name"=>"source"},
        ]
      },
      "missingType" => nil,
      "timeType" => { "specifiedByURL" => "https://time.graphql"}
    }}
    assert_equal(expected, result.to_h)
  end

  describe "deprecated fields" do
    let(:query_string) {%|
       query introspectionQuery {
         cheeseType:    __type(name: "Cheese") { name, kind, fields(includeDeprecated: true) { name, isDeprecated, type { kind, name, ofType { name } } } }
         dairyAnimal:   __type(name: "DairyAnimal") { name, kind, enumValues(includeDeprecated: true) { name, isDeprecated } }
       }
    |}
    let(:deprecated_fields) { {"name"=>"fatContent", "isDeprecated"=>true, "type"=>{"kind"=>"NON_NULL","name"=>nil, "ofType"=>{"name"=>"Float"}}} }

    it "can expose deprecated fields" do
      new_cheese_fields = ([deprecated_fields] + cheese_fields).sort_by { |f| f["name"] }
      expected = { "data" => {
        "cheeseType" => {
          "name"=> "Cheese",
          "kind" => "OBJECT",
          "fields"=> new_cheese_fields
        },
        "dairyAnimal"=>{
          "name"=>"DairyAnimal",
          "kind"=>"ENUM",
          "enumValues"=> dairy_animals + [{"name" => "YAK", "isDeprecated" => true}],
        },
      }}
      assert_equal(expected, result)
    end

    it "hides deprecated field arguments by default" do
      result = Dummy::Schema.execute <<-GRAPHQL
      {
        __type(name: "Query") {
          fields {
            name
            args {
              name
            }
          }
        }
      }
      GRAPHQL

      from_source_field = result['data']['__type']['fields'].find { |f| f['name'] == 'fromSource' }
      expected = [
        {"name" => "source"}
      ]
      assert_equal(expected, from_source_field['args'])
    end

    it "can expose deprecated field arguments" do
      result = Dummy::Schema.execute <<-GRAPHQL
      {
        __type(name: "Query") {
          fields {
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

      from_source_field = result['data']['__type']['fields'].find { |f| f['name'] == 'fromSource' }
      expected = [
        {"name" => "source", "isDeprecated" => false, "deprecationReason" => nil},
        {"name" => "oldSource", "isDeprecated" => true, "deprecationReason" => "No longer supported"}
      ]
      assert_equal(expected, from_source_field['args'])
    end
  end

  describe "input objects" do
    let(:query_string) {%|
       query introspectionQuery {
         __type(name: "DairyProductInput") { name, description, kind, inputFields { name, type { kind, name }, defaultValue } }
       }
    |}

    it "exposes metadata about input objects" do
      expected = { "data" => {
          "__type" => {
            "name"=>"DairyProductInput",
            "description"=>"Properties for finding a dairy product",
            "kind"=>"INPUT_OBJECT",
            "inputFields"=>[
              {"name"=>"source", "type"=>{"kind"=>"NON_NULL","name"=>nil, }, "defaultValue"=>nil},
              {"name"=>"originDairy", "type"=>{"kind"=>"SCALAR","name"=>"String"}, "defaultValue"=>"\"Sugar Hollow Dairy\""},
              {"name"=>"fatContent", "type"=>{"kind"=>"SCALAR","name" => "Float"}, "defaultValue"=>"0.3"},
              {"name"=>"organic", "type"=>{"kind"=>"SCALAR","name" => "Boolean"}, "defaultValue"=>"false"},
              {"name"=>"order_by", "type"=>{"kind"=>"INPUT_OBJECT", "name"=>"ResourceOrderType"}, "defaultValue"=>"{direction: \"ASC\"}"},
            ]
          }
        }}
      assert_equal(expected, result)
    end

    it "can expose deprecated input fields" do
      result = Dummy::Schema.execute <<-GRAPHQL
      {
        __type(name: "DairyProductInput") {
          inputFields(includeDeprecated: true) {
            name
            isDeprecated
            deprecationReason
          }
        }
      }
      GRAPHQL

      expected = {
        "data" => {
          "__type" => {
            "inputFields" => [
              {"name" => "source", "isDeprecated" => false, "deprecationReason" => nil},
              {"name" => "originDairy", "isDeprecated" => false, "deprecationReason" => nil},
              {"name" => "fatContent", "isDeprecated" => false, "deprecationReason" => nil},
              {"name" => "organic", "isDeprecated" => false, "deprecationReason" => nil},
              {"name" => "order_by", "isDeprecated" => false, "deprecationReason" => nil},
              {"name" => "oldSource", "isDeprecated" => true, "deprecationReason" => "No longer supported"},
            ]
          }
        }
      }
      assert_equal(expected, result)
    end

    it "includes Relay fields" do
      res = StarWars::Schema.execute <<-GRAPHQL
      {
        __schema {
          types {
            name
            fields {
              name
              args { name }
            }
          }
        }
      }
      GRAPHQL
      type_result = res["data"]["__schema"]["types"].find { |t| t["name"] == "Faction" }
      field_result = type_result["fields"].find { |f| f["name"] == "bases" }
      all_arg_names = ["after", "before", "first", "last", "nameIncludes", "complexOrder"]
      returned_arg_names = field_result["args"].map { |a| a["name"] }
      assert_equal all_arg_names.sort, returned_arg_names.sort
    end
  end
end
