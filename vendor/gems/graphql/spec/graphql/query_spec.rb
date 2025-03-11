# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query do
  let(:query_string) { %|
    query getFlavor($cheeseId: Int!) {
      brie: cheese(id: 1)   { ...cheeseFields, taste: flavor },
      cheese(id: $cheeseId)  {
        __typename,
        id,
        ...cheeseFields,
        ... edibleFields,
        ... on Cheese { cheeseKind: flavor },
      }
      fromSource(source: COW) { id }
      fromSheep: fromSource(source: SHEEP) { id }
      firstSheep: searchDairy(product: [{source: SHEEP}]) {
        __typename,
        ... dairyFields,
        ... milkFields
      }
      favoriteEdible { __typename, fatContent }
    }
    fragment cheeseFields on Cheese { flavor }
    fragment edibleFields on Edible { fatContent }
    fragment milkFields on Milk { source }
    fragment dairyFields on AnimalProduct {
       ... on Cheese { flavor }
       ... on Milk   { source }
    }
  |}
  let(:operation_name) { nil }
  let(:query_variables) { {"cheeseId" => 2} }
  let(:schema) { Dummy::Schema }
  let(:document) { GraphQL.parse(query_string) }

  let(:query) { GraphQL::Query.new(
    schema,
    query_string,
    variables: query_variables,
    operation_name: operation_name
  )}
  let(:result) { query.result }

  it "applies the max validation errors config" do
    limited_schema = Class.new(schema) { validate_max_errors(2) }
    res = limited_schema.execute("{ a b c d }")
    assert_equal 2, res["errors"].size
    refute res.key?("data")
  end

  describe "when passed both a query string and a document" do
    it "returns an error to the client when query kwarg is used" do
      assert_raises ArgumentError do
        GraphQL::Query.new(
          schema,
          query: "{ fromSource(source: COW) { id } }",
          document: document
        )
      end
    end

    it "returns an error to the client" do
      assert_raises ArgumentError do
        GraphQL::Query.new(
          schema,
          "{ fromSource(source: COW) { id } }",
          document: document
        )
      end
    end
  end

  describe "when passed no query string or document" do
    it 'returns an error to the client' do
      res = GraphQL::Query.new(
        schema,
        variables: query_variables,
        operation_name: operation_name
      ).result
      assert_equal 1, res["errors"].length
      assert_equal "No query string was present", res["errors"][0]["message"]
    end

    it 'can be assigned later' do
      query = GraphQL::Query.new(
        schema,
        variables: query_variables,
        operation_name: operation_name
      )
      query.query_string = '{ __type(name: """Cheese""") { name } }'
      assert_equal "Cheese", query.result["data"] ["__type"]["name"]
    end
  end

  describe "when passed a query_string with an invalid type" do
    it "returns an error to the client" do
      assert_raises(ArgumentError) {
        GraphQL::Query.new(schema, {"default" => "{ fromSource(source: COW) { id } }"})
      }
    end
  end

  describe "when passed a query with an invalid type" do
    it "returns an error to the client" do
      assert_raises(ArgumentError) {
        GraphQL::Query.new(schema, query: {"default" => "{ fromSource(source: COW) { id } }"})
      }
    end
  end

  describe "#operation_name" do
    describe "when provided" do
      let(:query_string) { <<-GRAPHQL
        query q1 { cheese(id: 1) { flavor } }
        query q2 { cheese(id: 2) { flavor } }
      GRAPHQL
      }
      let(:operation_name) { "q2" }

      it "returns the provided name" do
        assert_equal "q2", query.operation_name
      end
    end

    describe "when inferred" do
      let(:query_string) { <<-GRAPHQL
        query q3 { cheese(id: 3) { flavor } }
      GRAPHQL
      }

      it "returns nil" do
        assert_nil query.operation_name
      end
    end

    describe "#selected_operation_name" do
      describe "when an operation isprovided" do
        let(:query_string) { <<-GRAPHQL
          query q1 { cheese(id: 1) { flavor } }
          query q2 { cheese(id: 2) { flavor } }
        GRAPHQL
        }
        let(:operation_name) { "q2" }

        it "returns the provided name" do
          assert_equal "q2", query.selected_operation_name
        end
      end

      describe "when operation is inferred" do
        let(:query_string) { <<-GRAPHQL
          query q3 { cheese(id: 3) { flavor } }
        GRAPHQL
        }

        it "returns the inferred operation name" do
          assert_equal "q3", query.selected_operation_name
        end
      end

      describe "when there are no operations" do
        let(:query_string) { <<-GRAPHQL
          # Only Comments
          # In this Query
        GRAPHQL
        }

        it "returns the inferred operation name" do
          assert_nil query.selected_operation_name
        end
      end
    end

    describe "assigning operation_name=" do
      let(:query_string) { <<-GRAPHQL
          query q3 { manchego: cheese(id: 3) { flavor } }
          query q2 { gouda: cheese(id: 2) { flavor } }
        GRAPHQL
      }

      it "runs the assigned name" do
        query = GraphQL::Query.new(Dummy::Schema, query_string, operation_name: "q3")
        query.operation_name = "q2"
        res = query.result
        assert_equal "Gouda", res["data"]["gouda"]["flavor"]
      end
    end
  end

  describe "when passed a document instance" do
    let(:query) { GraphQL::Query.new(
      schema,
      document: document,
      variables: query_variables,
      operation_name: operation_name
    )}

    it "runs the query using the already parsed document" do
      expected = {"data"=> {
        "brie" =>   { "flavor" => "Brie", "taste" => "Brie" },
        "cheese" => {
          "__typename" => "Cheese",
          "id" => 2,
          "flavor" => "Gouda",
          "fatContent" => 0.3,
          "cheeseKind" => "Gouda",
        },
        "fromSource" => [{ "id" => 1 }, {"id" => 2}],
        "fromSheep"=>[{"id"=>3}],
        "firstSheep" => { "__typename" => "Cheese", "flavor" => "Manchego" },
        "favoriteEdible"=>{"__typename"=>"Milk", "fatContent"=>0.04},
    }}
    assert_equal(expected, result)
    end
  end

  describe '#result' do
    it "returns fields on objects" do
      expected = {"data"=> {
          "brie" =>   { "flavor" => "Brie", "taste" => "Brie" },
          "cheese" => {
            "__typename" => "Cheese",
            "id" => 2,
            "flavor" => "Gouda",
            "fatContent" => 0.3,
            "cheeseKind" => "Gouda",
          },
          "fromSource" => [{ "id" => 1 }, {"id" => 2}],
          "fromSheep"=>[{"id"=>3}],
          "firstSheep" => { "__typename" => "Cheese", "flavor" => "Manchego" },
          "favoriteEdible"=>{"__typename"=>"Milk", "fatContent"=>0.04},
      }}
      assert_equal(expected, result)
    end

    describe "when it hits null objects" do
      let(:query_string) {%|
        {
          maybeNull {
            cheese {
              flavor,
              similarCheese(source: [SHEEP]) { flavor }
            }
          }
        }
      |}

      it "skips null objects" do
        expected = {"data"=> {
          "maybeNull" => { "cheese" => nil }
        }}
        assert_equal(expected, result)
      end
    end

    describe "queries in execute_mutation hooks" do
      module ErrorLogTrace
        ERROR_LOG = []
        def execute_multiplex(multiplex:)
          super
        ensure
          multiplex.queries.each do |q|
            ERROR_LOG << q.result["errors"]
          end
        end
      end

      let(:schema) {
        Class.new(Dummy::Schema) {
          trace_with(ErrorLogTrace)
        }
      }

      before do
        ErrorLogTrace::ERROR_LOG.clear
      end
      it "can access #result" do
        result
        assert_equal [nil], ErrorLogTrace::ERROR_LOG
      end

      it "can access result from an unhandled error" do
        query = GraphQL::Query.new(schema, "{ error }")
        assert_raises RuntimeError do
          query.result
        end
        assert_equal [nil], ErrorLogTrace::ERROR_LOG
      end

      it "can access result from an handled error" do
        query = GraphQL::Query.new(schema, "{ executionError }")
        query.result
        expected_err = {
          "message" => "There was an execution error",
          "locations" => [{"line"=>1, "column"=>3}],
          "path" => ["executionError"]
        }
        assert_equal [[expected_err]], ErrorLogTrace::ERROR_LOG
      end

      it "can access static validation errors" do
        query = GraphQL::Query.new(schema, "{ noField }")
        query.result
        expected_err = {
          "message" => "Field 'noField' doesn't exist on type 'Query'",
          "locations" => [{"line"=>1, "column"=>3}],
          "path" => ["query", "noField"],
          "extensions" => {"code"=>"undefinedField", "typeName"=>"Query", "fieldName"=>"noField"},
        }
        assert_equal [[expected_err]], ErrorLogTrace::ERROR_LOG
      end
    end

    describe "when an error propagated through execution" do
      module ExtensionsTrace
        LOG = []
        def execute_multiplex(multiplex:)
          super
        ensure
          multiplex.queries.each do |q|
            q.result["extensions"] = { "a" => 1 }
            LOG << :ok
          end
        end
      end

      let(:schema) {
        Class.new(Dummy::Schema) {
          trace_with(ExtensionsTrace)
        }
      }

      it "can add to extensions" do
        ExtensionsTrace::LOG.clear
        assert_raises(RuntimeError) do
          schema.execute "{ error }"
        end
        assert_equal [:ok], ExtensionsTrace::LOG
      end
    end
  end

  describe '#executed?' do
    it "returns false if the query hasn't been executed" do
      refute query.executed?
    end

    it "returns true if the query has been executed" do
      query.result
      assert query.executed?
    end
  end

  it "uses root_value as the object for the root type" do
    result = GraphQL::Query.new(schema, '{ root }', root_value: "I am root").result
    assert_equal 'I am root', result.fetch('data').fetch('root')
  end

  it "exposes fragments" do
    assert_equal(GraphQL::Language::Nodes::FragmentDefinition, query.fragments["cheeseFields"].class)
  end

  it "exposes the original string" do
    assert_equal(query_string, query.query_string)
  end

  describe "merging fragments with different keys" do
    let(:query_string) { %|
      query getCheeseFieldsThroughDairy {
        ... cheeseFrag3
        dairy {
          ...flavorFragment
          ...fatContentFragment
        }
      }
      fragment flavorFragment on Dairy {
        cheese {
          flavor
        }
        milks {
          id
        }
      }
      fragment fatContentFragment on Dairy {
        cheese {
          fatContent
        }
        milks {
          fatContent
        }
      }

      fragment cheeseFrag1 on Query {
        cheese(id: 1) {
          id
        }
      }
      fragment cheeseFrag2 on Query {
        cheese(id: 1) {
          flavor
        }
      }
      fragment cheeseFrag3 on Query {
        ... cheeseFrag2
        ... cheeseFrag1
      }
    |}

    it "should include keys from each fragment" do
      expected = {"data" => {
        "dairy" => {
          "cheese" => {
            "flavor" => "Brie",
            "fatContent" => 0.19
          },
          "milks" => [
            {
              "id" => "1",
              "fatContent" => 0.04,
            }
          ],
        },
        "cheese" => {
          "id" => 1,
          "flavor" => "Brie"
        },
      }}
      assert_equal(expected, result)
    end
  end

  describe "field argument default values" do
    let(:query_string) {%|
      query getCheeses(
        $search: [DairyProductInput]
        $searchWithDefault: [DairyProductInput] = [{source: COW}]
      ){
        noVariable: searchDairy(product: $search) {
          ... cheeseFields
        }
        noArgument: searchDairy {
          ... cheeseFields
        }
        variableDefault: searchDairy(product: $searchWithDefault) {
          ... cheeseFields
        }
        convertedDefault: fromSource {
          ... cheeseFields
        }
      }
      fragment cheeseFields on Cheese { flavor }
    |}

    it "has a default value" do
      default_value = schema.query.fields["searchDairy"].arguments["product"].default_value
      default_source = default_value[0][:source]
      assert_equal("SHEEP", default_source)
    end

    describe "when a variable is used, but not provided" do
      it "uses the default_value" do
        assert_equal("Manchego", result["data"]["noVariable"]["flavor"])
      end
    end

    describe "when the argument isn't passed at all" do
      it "uses the default value" do
        assert_equal("Manchego", result["data"]["noArgument"]["flavor"])
      end
    end

    describe "when the variable has a default" do
      it "uses the variable default" do
        assert_equal("Brie", result["data"]["variableDefault"]["flavor"])
      end
    end

    describe "when the variable has a default needing conversion" do
      it "uses the converted variable default" do
        assert_equal([{"flavor" => "Brie"}, {"flavor" => "Gouda"}], result["data"]["convertedDefault"])
      end
    end
  end

  describe "query variables" do
    let(:query_string) {%|
      query getCheese($cheeseId: Int!){
        cheese(id: $cheeseId) { flavor }
      }
    |}

    describe "when they can't be coerced" do
      let(:query_variables) { {"cheeseId" => "2"} }

      it "raises an error" do
        expected = {
          "errors" => [
            {
              "message" => "Variable $cheeseId of type Int! was provided invalid value",
              "locations"=>[{ "line" => 2, "column" => 23 }],
              "extensions" => {
                "value" => "2",
                "problems" => [{ "path" => [], "explanation" => 'Could not coerce value "2" to Int' }]
              }
            }
          ]
        }
        assert_equal(expected, result)
      end
    end

    describe "when they aren't provided" do
      let(:query_variables) { {} }

      it "raises an error" do
        expected = {
          "errors" => [
            {
              "message" => "Variable $cheeseId of type Int! was provided invalid value",
              "locations" => [{"line" => 2, "column" => 23}],
              "extensions" => {
                "value" => nil,
                "problems" => [{ "path" => [], "explanation" => "Expected value to not be null" }]
              }
            }
          ]
        }
        assert_equal(expected, result)
      end
    end

    describe "when they are non-null and provided a null value" do
      let(:query_variables) { { "cheeseId" => nil } }

      it "raises an error" do
        expected = {
          "errors" => [
            {
              "message" => "Variable $cheeseId of type Int! was provided invalid value",
              "locations" => [{"line" => 2, "column" => 23}],
              "extensions" => {
                "value" => nil,
                "problems" => [{ "path" => [], "explanation" => "Expected value to not be null" }]
              }
            }
          ]
        }
        assert_equal(expected, result)
      end
    end

    describe "when they're a string" do
      let(:query_variables) { '{ "var" : 1 }' }
      it "raises an error" do
        assert_raises(ArgumentError) { result }
      end
    end

    describe "default values" do
      let(:query_string) {%|
        query getCheese($cheeseId: Int = 3){
          cheese(id: $cheeseId) { id, flavor }
        }
      |}

      describe "when no value is provided" do
        let(:query_variables) { {} }

        it "uses the default" do
          assert(3, result["data"]["cheese"]["id"])
          assert("Manchego", result["data"]["cheese"]["flavor"])
        end
      end

      describe "when a value is provided" do
        it "uses the provided variable" do
          assert(2, result["data"]["cheese"]["id"])
          assert("Gouda", result["data"]["cheese"]["flavor"])
        end
      end

      describe "when complex values" do
        let(:query_variables) { {"search" => [{"source" => "COW"}]} }
        let(:query_string) {%|
          query getCheeses($search: [DairyProductInput]!){
            cow: searchDairy(product: $search) {
              ... on Cheese {
                flavor
              }
            }
          }
        |}

        it "coerces recursively" do
          assert_equal("Brie", result["data"]["cow"]["flavor"])
        end
      end
    end

    describe "when given as an object type and accessed in ruby" do
      it "returns an error to the client and is an empty hash" do
        result = schema.execute(<<~GRAPHQL)
        query($ch: Cheese) {
          __typename
        }
        GRAPHQL
        expected_messages = [
          "Cheese isn't a valid input type (on $ch)",
          "Variable $ch is declared by anonymous query but not used",
        ]
        assert_equal expected_messages, result["errors"].map { |err| err["message"] }
        assert_equal({}, result.query.variables.to_h)
      end
    end
  end

  describe "max_depth" do
    let(:query_string) {
      <<-GRAPHQL
      {
        cheese(id: 1) {
          similarCheese(source: SHEEP) {
            similarCheese(source: SHEEP) {
              similarCheese(source: SHEEP) {
                similarCheese(source: SHEEP) {
                  id
                }
              }
            }
          }
        }
      }
      GRAPHQL
    }

    it "defaults to the schema's max_depth" do
      # Constrained by schema's setting of 5
      assert_equal 1, result["errors"].length
    end

    describe "overriding max_depth" do
      let(:query) {
        GraphQL::Query.new(
          schema,
          query_string,
          variables: query_variables,
          operation_name: operation_name,
          max_depth: 12
        )
      }

      it "overrides the schema's max_depth" do
        assert result["data"].key?("cheese")
        assert_nil result["errors"]
      end
    end
  end

  describe "#provided_variables" do
    it "returns the originally-provided object" do
      assert_equal({"cheeseId" => 2}, query.provided_variables)
    end
  end

  describe "parse errors" do
    let(:invalid_query_string) {
      <<-GRAPHQL
        {
          getStuff
          nonsense
          This is broken 1
        }
      GRAPHQL
    }

    it "adds an entry to the errors key" do
      res = schema.execute(" { ")
      assert_equal 1, res["errors"].length
      if USING_C_PARSER
        expected_err = "syntax error, unexpected end of file at [1, 2]"
      else
        expected_err = "Expected NAME, actual: (none) (\" \") at [1, 2]"
      end
      expected_locations = [{"line" => 1, "column" => 2}]
      assert_equal expected_err, res["errors"][0]["message"]
      assert_equal expected_locations, res["errors"][0]["locations"]

      res = schema.execute("{")
      assert_equal 1, res["errors"].length
      if USING_C_PARSER
        expected_err = "syntax error, unexpected end of file at [1, 1]"
      else
        expected_err = "Expected NAME, actual: (none) (\"\") at [1, 1]"
      end
      expected_locations = [{"line" => 1, "column" => 1}]
      assert_equal expected_err, res["errors"][0]["message"]
      assert_equal expected_locations, res["errors"][0]["locations"]

      res = schema.execute(invalid_query_string)
      assert_equal 1, res["errors"].length
      expected_error = if USING_C_PARSER
        "syntax error, unexpected INT (\"1\") at [4, 26]"
      else
        %|Expected NAME, actual: INT ("1") at [4, 26]|
      end
      assert_equal expected_error, res["errors"][0]["message"]
      assert_equal({"line" => 4, "column" => 26}, res["errors"][0]["locations"][0])
    end

    it "can be configured to raise" do
      raise_schema = Class.new(schema) do
        def self.parse_error(err, ctx)
          raise err
        end
      end

      assert_raises(GraphQL::ParseError) {
        raise_schema.execute(invalid_query_string)
      }
    end
  end

  describe "#mutation?" do
    let(:query_string) { <<-GRAPHQL
    query Q { __typename }
    mutation M { pushValue(value: 1) }
    GRAPHQL
    }

    it "returns true if the selected operation is a mutation" do
      query_query = GraphQL::Query.new(schema, query_string, operation_name: "Q")
      assert_equal false, query_query.mutation?
      assert_equal true, query_query.query?

      mutation_query = GraphQL::Query.new(schema, query_string, operation_name: "M")
      assert_equal true, mutation_query.mutation?
      assert_equal false, mutation_query.query?
    end
  end

  describe "validate: false" do
    it "doesn't validate the query" do
      invalid_query_string = "{ nonExistantField }"
      # Can assign attribute
      query = GraphQL::Query.new(schema, invalid_query_string)
      query.validate = false
      assert_equal true, query.valid?
      assert_equal 0, query.static_errors.length

      # Can pass keyword argument
      query = GraphQL::Query.new(schema, invalid_query_string, validate: false)
      assert_equal true, query.valid?
      assert_equal 0, query.static_errors.length

      # Can pass `true`
      query = GraphQL::Query.new(schema, invalid_query_string, validate: true)
      assert_equal false, query.valid?
      assert_equal 1, query.static_errors.length

      # Can assign attribute after calling methods that use the AST
      query = GraphQL::Query.new(schema, invalid_query_string)
      assert query.fingerprint
      query.validate = false
      assert_equal true, query.valid?
      assert_equal 0, query.static_errors.length
    end

    it "can't be reassigned after validating" do
      query = GraphQL::Query.new(schema, "{ nonExistingField }")
      assert query.fingerprint
      query.validate = false
      assert_equal true, query.valid?
      assert_equal 0, query.static_errors.length
      err = assert_raises ArgumentError do
        query.validate = true
      end

      err2 = assert_raises ArgumentError do
        query.validate = false
      end
      expected_message = "Can't reassign Query#validate= after validation has run, remove this assignment."
      assert_equal expected_message, err.message
      assert_equal expected_message, err2.message
    end
  end

  describe "static_validator" do
    module ZebraRule
      def on_field(node, _parent)
        if node.name != "zebra"
          add_error(GraphQL::StaticValidation::Error.new("Invalid field name", nodes: node))
        else
          super
        end
      end
    end

    it "provides a custom validator for the query" do
      validator = GraphQL::StaticValidation::Validator.new(schema: schema, rules: [ZebraRule])

      query = GraphQL::Query.new(schema, "{ zebra }")
      query.static_validator = validator
      assert_equal true, query.valid?
      assert_equal 0, query.static_errors.length

      query = GraphQL::Query.new(schema, "{ zebra }", static_validator: validator)
      assert_equal true, query.valid?
      assert_equal 0, query.static_errors.length

      query = GraphQL::Query.new(schema, "{ arbez }", static_validator: validator)
      assert_equal false, query.valid?
      assert_equal 1, query.static_errors.length
    end

    it "must be a GraphQL::StaticValidation::Validator" do
      invalid_validator = {}

      err1 = assert_raises ArgumentError do
        GraphQL::Query.new(schema, "{ zebra }", static_validator: invalid_validator)
      end

      err2 = assert_raises ArgumentError do
        GraphQL::Query.new(schema, "{ zebra }")
        query.static_validator = invalid_validator
      end

      expected_message = "Expected a `GraphQL::StaticValidation::Validator` instance."
      assert_equal expected_message, err1.message
      assert_equal expected_message, err2.message
    end

    it "can't be reassigned after validating" do
      query = GraphQL::Query.new(schema, "{ zebra }")

      query.static_validator = GraphQL::StaticValidation::Validator.new(schema: schema, rules: [ZebraRule])
      assert_equal true, query.valid?
      assert_equal 0, query.static_errors.length

      err = assert_raises ArgumentError do
        query.static_validator = GraphQL::StaticValidation::Validator.new(schema: schema, rules: [ZebraRule])
      end

      expected_message = "Can't reassign Query#static_validator= after validation has run, remove this assignment."
      assert_equal expected_message, err.message
    end
  end

  describe "validating with optional arguments and variables: nil" do
    it "works" do
      query_str = <<-GRAPHQL
      query($expiresAfter: Time) {
        searchDairy(expiresAfter: $expiresAfter) {
          __typename
        }
      }
      GRAPHQL
      query = GraphQL::Query.new(schema, query_str, variables: nil)
      assert query.valid?
    end
  end

  describe 'NullValue type arguments' do
    let(:schema_definition) {
      <<-GRAPHQL
        type Query {
          foo(id: [ID]): Int
        }
      GRAPHQL
    }
    let(:expected_args) { [] }
    let(:default_resolver) do
      {
        'Query' => { 'foo' => ->(_obj, args, _ctx) { expected_args.push(args); 1 } },
      }
    end
    let(:schema) { GraphQL::Schema.from_definition(schema_definition, default_resolve: default_resolver) }

    it 'sets argument to nil when null is passed' do
      query = <<-GRAPHQL
        {
          foo(id: null)
        }
      GRAPHQL

      schema.execute(query)

      assert(expected_args.first.key?(:id))
      assert_nil(expected_args.first[:id])
    end

    it 'sets argument to nil when nil is passed via variable' do
      query = <<-GRAPHQL
        query baz($id: [ID]) {
          foo(id: $id)
        }
      GRAPHQL

      schema.execute(query, variables: { 'id' => nil })
      assert(expected_args.first.key?(:id))
      assert_nil(expected_args.first[:id])
    end

    it 'sets argument to [nil] when [null] is passed' do
      query = <<-GRAPHQL
        {
          foo(id: [null])
        }
      GRAPHQL

      schema.execute(query)

      assert(expected_args.first.key?(:id))
      assert_equal([nil], expected_args.first[:id])
    end

    it 'sets argument to [nil] when [nil] is passed via variable' do
      query = <<-GRAPHQL
        query baz($id: [ID]) {
          foo(id: $id)
        }
      GRAPHQL

      schema.execute(query, variables: { 'id' => [nil] })

      assert(expected_args.first.key?(:id))
      assert_equal([nil], expected_args.first[:id])
    end
  end

  it "Accepts a passed-in warden" do
    schema_class = Class.new(Jazz::Schema) do
      def self.visible?(member, ctx)
        false
      end
    end

    warden = GraphQL::Schema::Warden.new(schema: schema_class, context: nil)
    res = Jazz::Schema.execute("{ __typename } ", warden: warden)
    assert_equal ["Schema is not configured for queries"], res["errors"].map { |e| e["message"] }
  end

  describe "arguments_for" do
    it "returns symbol-keyed, underscored hashes, regardless of literal or variable values" do
      query_str = "
      query($product: [DairyProductInput!]!) {
        f1: searchDairy(product: [{source: SHEEP}]) {
          __typename
        }
        f2: searchDairy(product: $product) {
          __typename
        }
      }
      "

      query = GraphQL::Query.new(Dummy::Schema, query_str, variables: { "product" => [{"source" => "SHEEP"}]})
      field_defn = Dummy::Schema.get_field("Query", "searchDairy")
      node_1 = query.document.definitions.first.selections.first
      node_2 = query.document.definitions.first.selections.last

      argument_contexts = {
        "literals" => node_1,
        "variables" => node_2,
      }

      argument_contexts.each do |context_name, ast_node|
        detailed_args = query.arguments_for(ast_node, field_defn)
        assert_instance_of GraphQL::Execution::Interpreter::Arguments, detailed_args
        args = detailed_args.keyword_arguments
        assert_instance_of Hash, args, "it makes a hash for #{context_name}"
        assert_equal [:product], args.keys, "it has a single symbol key for #{context_name}"
        product_value = args[:product]
        assert_instance_of Array, product_value
        product_value_item = product_value[0]
        assert_instance_of Dummy::DairyProductInput, product_value_item, "it initializes an input object for #{context_name}"
        assert_equal "SHEEP", product_value_item[:source], "it adds the input value for #{context_name}"

        # Default values are merged in
        expected_h = {
          source: "SHEEP",
          origin_dairy: "Sugar Hollow Dairy",
          fat_content: 0.3,
          organic: false,
          order_by: { direction: "ASC"}
        }
        assert_equal expected_h, product_value_item.to_h, "it makes a hash with defaults for #{context_name}"
      end
    end

    it "returns argument metadata" do
      query_str = <<-GRAPHQL
      query($fatContent: Float, $organic: Boolean = false) {
        searchDairy(product: [{source: SHEEP, fatContent: $fatContent, organic: $organic}]) {
          __typename
        }
      }
      GRAPHQL

      query = GraphQL::Query.new(Dummy::Schema, query_str, variables: { "product" => [{"source" => "SHEEP"}]})
      field_defn = Dummy::Schema.get_field("Query", "searchDairy")
      node_1 = query.document.definitions.first
        .selections.first
        .arguments.first
        .value.first

      input_obj_defn = field_defn.arguments["product"].type.unwrap
      detailed_args = query.arguments_for(node_1, input_obj_defn)

      # Literal value
      source_arg_value = detailed_args.argument_values[:source]
      assert_equal false, source_arg_value.default_used?
      assert_equal "SHEEP", detailed_args[:source]
      assert_equal "SHEEP", detailed_args.fetch(:source)
      assert_equal "SHEEP", source_arg_value.value
      assert_equal "source", source_arg_value.definition.graphql_name

      # Unused optional variable, uses default
      fat_content_arg_value = detailed_args.argument_values[:fat_content]
      assert_equal true, fat_content_arg_value.default_used?
      assert_equal 0.3, detailed_args[:fat_content]
      assert_equal 0.3, fat_content_arg_value.value
      assert_equal "fatContent", fat_content_arg_value.definition.graphql_name

      # Variable value
      organic_arg_value = detailed_args.argument_values[:organic]
      assert_equal false, organic_arg_value.default_used?
      assert_equal false, detailed_args[:organic]
      assert_equal false, organic_arg_value.value
      assert_equal "organic", organic_arg_value.definition.graphql_name

      # Absent value, uses default
      order_by_argument_value = detailed_args.argument_values[:order_by]
      assert_equal true, order_by_argument_value.default_used?
      assert_equal({direction: "ASC"}, detailed_args[:order_by].to_h)
      assert_equal({direction: "ASC"}, order_by_argument_value.value.to_h)
      assert_equal "order_by", order_by_argument_value.definition.graphql_name

      assert_equal [source_arg_value, fat_content_arg_value, organic_arg_value, order_by_argument_value, detailed_args.argument_values[:origin_dairy]].to_set,
                   detailed_args.each_value.to_set
    end

    it "provides access to nested input objects" do
      query_str = <<-GRAPHQL
      query($fatContent: Float, $organic: Boolean = false, $products: [DairyProductInput!]!) {
        searchDairy(product: $products) {
          __typename
        }
      }
      GRAPHQL

      query = GraphQL::Query.new(Dummy::Schema, query_str, variables: { "products" => [{"source" => "SHEEP"}]})
      field_defn = Dummy::Schema.get_field("Query", "searchDairy")
      node = query.document.definitions.first
        .selections.first

      args = query.arguments_for(node, field_defn)
      product_args = args.argument_values[:product].value
      first_product_args = product_args.first.arguments

      source_arg_value = first_product_args.argument_values[:source]
      assert_equal false, source_arg_value.default_used?
      assert_equal "SHEEP", source_arg_value.value
      assert_equal "source", source_arg_value.definition.graphql_name

      order_by_argument_value = first_product_args.argument_values[:order_by]
      assert_equal true, order_by_argument_value.default_used?
      assert_equal({direction: "ASC"}, order_by_argument_value.value.to_h)
      assert_equal "order_by", order_by_argument_value.definition.graphql_name
    end
  end

  describe "when provided input object field names are not unique" do
    let(:variables) { {} }
    let(:result) { Dummy::Schema.execute(query_string, variables: variables) }

    describe "the query is invalid" do
      let(:query_string) {%|
        query getCheeses{
          searchDairy(product: [{ source: COW, source: COW }]) {
            __typename
          }
        }
      |}

      it "returns errors" do
        refute_nil(result["errors"])
      end
    end
  end

  describe "using GraphQL.default_parser" do
    module DummyParser
      DOC = GraphQL::Language::Parser.parse("{ __typename }")
      def self.parse(query_str, trace: nil, filename: nil, max_tokens: nil)
        DOC
      end
    end

    before do
      @previous_parser = GraphQL.default_parser
      GraphQL.default_parser = DummyParser
    end

    after do
      GraphQL.default_parser = @previous_parser
    end

    it "uses it for queries" do
      res = Dummy::Schema.execute("blah blah blah")
      assert_equal "Query", res["data"]["__typename"]
    end
  end

  describe "context[:trace]" do
    class QueryTraceSchema < GraphQL::Schema
      class Query < GraphQL::Schema::Object
        field :int, Integer
        def int; 1; end
      end

      class Trace < GraphQL::Tracing::Trace
        def execute_multiplex(multiplex:)
          @execute_multiplex_count ||= 0
          @execute_multiplex_count += 1
          super
        end

        def execute_query(query:)
          @execute_query_count ||= 0
          @execute_query_count += 1
          super
        end

        def execute_field(**rest)
          @execute_field_count ||= 0
          @execute_field_count += 1
          super
        end

        attr_reader :execute_multiplex_count, :execute_query_count, :execute_field_count
      end

      query(Query)
    end

    it "uses it instead of making a new trace" do
      query_str = "{ int __typename }"
      trace_instance = QueryTraceSchema::Trace.new
      res = QueryTraceSchema.execute(query_str, context: { trace: trace_instance })

      assert_equal 1, res["data"]["int"]

      assert_equal 1, trace_instance.execute_multiplex_count
      assert_equal 1, trace_instance.execute_query_count
      assert_equal 2, trace_instance.execute_field_count
    end
  end
end
