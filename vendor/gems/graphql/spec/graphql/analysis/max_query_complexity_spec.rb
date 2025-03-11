# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::MaxQueryComplexity do
  let(:schema) { Class.new(Dummy::Schema) }
  let(:query_string) {%|
    {
      a: cheese(id: 1) { id }
      b: cheese(id: 1) { id }
      c: cheese(id: 1) { id }
      d: cheese(id: 1) { id }
      e: cheese(id: 1) { id }
    }
  |}
  let(:query) { GraphQL::Query.new(schema, query_string, variables: {}, max_complexity: max_complexity) }
  let(:result) {
    GraphQL::Analysis.analyze_query(query, [GraphQL::Analysis::MaxQueryComplexity]).first
  }


  describe "when a query goes over max complexity" do
    let(:max_complexity) { 9 }

    it "returns an error" do
      assert_equal GraphQL::AnalysisError, result.class
      assert_equal "Query has complexity of 10, which exceeds max complexity of 9", result.message
    end
  end

  describe "when there is no max complexity" do
    let(:max_complexity) { nil }

    it "doesn't error" do
      assert_nil result
    end
  end

  describe "when the query is less than the max complexity" do
    let(:max_complexity) { 99 }

    it "doesn't error" do
      assert_nil result
    end
  end

  describe "when max_complexity is decreased at query-level" do
    before do
      schema.max_complexity(100)
    end

    let(:max_complexity) { 7 }

    it "is applied" do
      assert_equal GraphQL::AnalysisError, result.class
      assert_equal "Query has complexity of 10, which exceeds max complexity of 7", result.message
    end
  end

  describe "when max_complexity is increased at query-level" do
    before do
      schema.max_complexity(1)
    end

    let(:max_complexity) { 10 }

    it "doesn't error" do
      assert_nil result
    end
  end

  describe "when max_complexity is nil at query-level" do
    let(:max_complexity) { nil }

    before do
      schema.max_complexity(1)
    end

    it "is applied" do
      assert_nil result
    end
  end

  describe "when used with the max_depth plugin" do
    let(:schema) do
      Class.new(GraphQL::Schema) do
        query Dummy::DairyAppQuery

        max_depth 3
        max_complexity 1
      end
    end

    let(:query_string) {%|
      {
        a: cheese(id: 1) { ...cheeseFields }
        b: cheese(id: 1) { ...cheeseFields }
        c: cheese(id: 1) { ...cheeseFields }
        d: cheese(id: 1) { ...cheeseFields }
        e: cheese(id: 1) { ...cheeseFields }
      }

      fragment cheeseFields on Cheese { id }
    |}
    let(:result) { schema.execute(query_string) }

    it "returns a complexity error" do
      assert_equal "Query has complexity of 10, which exceeds max complexity of 1", result["errors"].first["message"]
    end
  end

  describe "count_introspection_fields: false" do
    let(:schema) { Class.new(Dummy::Schema) { max_complexity(5) } }
    let(:skip_introspection_schema) { Class.new(Dummy::Schema) do
      max_complexity 5, count_introspection_fields: false
    end
    }

    it "skips introspection fields when configured" do
      query_string = "{ c1: cheese(id: 1) { id __typename } c2: cheese(id: 2) { id __typename } }"
      res = schema.execute(query_string)
      expected_msg = "Query has complexity of 6, which exceeds max complexity of 5"
      assert_equal [expected_msg], res["errors"].map { |e| e["message"]}

      res2 = skip_introspection_schema.execute(query_string)
      assert_equal 2, res2["data"].size
      refute res2.key?("errors")
    end
  end

  describe "across a multiplex" do
    before do
      schema.analysis_engine = GraphQL::Analysis::AST
    end

    let(:queries) {
      5.times.map { |n|
        GraphQL::Query.new(schema, "{ cheese(id: #{n}) { id } }", variables: {})
      }
    }

    let(:max_complexity) { 9 }
    let(:multiplex) { GraphQL::Execution::Multiplex.new(schema: schema, queries: queries, context: {}, max_complexity: max_complexity) }
    let(:analyze_multiplex) {
      GraphQL::Analysis.analyze_multiplex(multiplex, [GraphQL::Analysis::MaxQueryComplexity])
    }

    it "returns errors for all queries" do
      analyze_multiplex
      err_msg = "Query has complexity of 10, which exceeds max complexity of 9"
      queries.each do |query|
        assert_equal err_msg, query.analysis_errors[0].message
      end
    end

    describe "with a local override" do
      let(:max_complexity) { 10 }

      it "uses the override" do
        analyze_multiplex

        queries.each do |query|
          assert query.analysis_errors.empty?
        end
      end
    end
  end

  describe "when an argument is unauthorized by type" do
    class AuthorizedTypeSchema < GraphQL::Schema
      class Thing < GraphQL::Schema::Object
        def self.authorized?(obj, ctx)
          !!ctx[:authorized] && super
        end
        field :name, String
      end

      class Query < GraphQL::Schema::Object
        field :things, Thing.connection_type do
          argument :thing_id, ID, loads: Thing
        end

        def things(thing:)
          [thing]
        end
      end

      query(Query)
      def self.resolve_type(abs_type, object, ctx)
        Thing
      end

      def self.object_from_id(id, ctx)
        if id == "13"
          raise GraphQL::ExecutionError, "No Thing ##{id}"
        else
          { name: "Loaded thing #{id}" }
        end
      end

      def self.unauthorized_object(err)
        raise GraphQL::ExecutionError, "Unauthorized Object: #{err.object[:name].inspect}"
      end

      default_max_page_size 30
      max_complexity 10
    end

    it "when the arg is unauthorized, returns an authorization error, not a complexity error" do
      query_str = "{ things(thingId: \"123\", first: 1) { nodes { name } } }"
      res = AuthorizedTypeSchema.execute(query_str, context: { authorized: true })
      assert_equal "Loaded thing 123", res["data"]["things"]["nodes"].first["name"]

      res2 = AuthorizedTypeSchema.execute(query_str)
      assert_equal ["Unauthorized Object: \"Loaded thing 123\""], res2["errors"].map { |e| e["message"] }
    end

    it "returns the right error when the loaded object raises an error" do
      query_str = "{ things(thingId: \"13\", first: 1) { nodes { name } } }"
      res = AuthorizedTypeSchema.execute(query_str, context: { authorized: true })
      assert_equal ["No Thing #13"], res["errors"].map { |e| e["message"] }
    end
  end
end
