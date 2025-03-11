# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Multiplex do
  def multiplex(*a, **kw)
    LazyHelpers::LazySchema.multiplex(*a, **kw)
  end

  let(:q1) { <<-GRAPHQL
    query Q1 {
      nestedSum(value: 3) {
        value
        nestedSum(value: 7) {
          value
        }
      }
    }
    GRAPHQL
  }
  let(:q2) { <<-GRAPHQL
    query Q2 {
      nestedSum(value: 2) {
        value
        nestedSum(value: 11) {
          value
        }
      }
    }
    GRAPHQL
  }
  let(:q3) { <<-GRAPHQL
    query Q3 {
      listSum(values: [1,2]) {
        nestedSum(value: 3) {
          value
        }
      }
    }
    GRAPHQL
  }

  let(:queries) { [{query: q1}, {query: q2}, {query: q3}] }

  describe "multiple queries in the same lazy context" do
    it "runs multiple queries in the same lazy context" do
      expected_data = [
        {"data"=>{"nestedSum"=>{"value"=>14, "nestedSum"=>{"value"=>46}}}},
        {"data"=>{"nestedSum"=>{"value"=>14, "nestedSum"=>{"value"=>46}}}},
        {"data"=>{"listSum"=>[{"nestedSum"=>{"value"=>14}}, {"nestedSum"=>{"value"=>14}}]}},
      ]

      res = multiplex(queries)
      assert_equal expected_data, res
    end

    it "returns responses in the same order as their respective requests" do
      queries = 2000.times.map do |index|
        case index % 3
        when 0
          {query: q1}
        when 1
          {query: q2}
        when 2
          {query: q3}
        end
      end

      responses = multiplex(queries)

      responses.each.with_index do |response, index|
        case index % 3
        when 0
          assert_equal "Q1", response.query.operation_name
        when 1
          assert_equal "Q2", response.query.operation_name
        when 2
          assert_equal "Q3", response.query.operation_name
        end
      end
    end
  end

  describe "when some have validation errors or runtime errors" do
    let(:q1) { " { success: nullableNestedSum(value: 1) { value } }" }
    let(:q2) { " { runtimeError: nullableNestedSum(value: 13) { value } }" }
    let(:q3) { "{
      invalidNestedNull: nullableNestedSum(value: 1) {
        value
        nullableNestedSum(value: 2) {
          nestedSum(value: 13) {
            value
          }
          # This field will never get executed
          ns2: nestedSum(value: 13) {
            value
          }
        }
      }
    }" }
    let(:q4) { " { validationError: nullableNestedSum(value: true) }"}

    it "returns a mix of errors and values" do
      expected_res = [
        {
          "data"=>{"success"=>{"value"=>2}}
        },
        {
          "data"=>{"runtimeError"=>nil},
          "errors"=>[{
            "message"=>"13 is unlucky",
            "locations"=>[{"line"=>1, "column"=>4}],
            "path"=>["runtimeError"]
          }]
        },
        {
          "data"=>{"invalidNestedNull"=>{"value" => 2,"nullableNestedSum" => nil}},
          "errors"=>[{
            "message"=>"Cannot return null for non-nullable field LazySum.nestedSum",
            "path"=>["invalidNestedNull", "nullableNestedSum", "nestedSum"],
            "locations"=>[{"line"=>5, "column"=>11}],
          }],
        },
        {
          "errors" => [{
            "message"=>"Field must have selections (field 'nullableNestedSum' returns LazySum but has no selections. Did you mean 'nullableNestedSum { ... }'?)",
            "locations"=>[{"line"=>1, "column"=>4}],
            "path"=>["query", "validationError"],
            "extensions"=>{"code"=>"selectionMismatch", "nodeName"=>"field 'nullableNestedSum'", "typeName"=>"LazySum"}
          }]
        },
      ]

      res = multiplex([
        {query: q1},
        {query: q2},
        {query: q3},
        {query: q4},
      ])
      assert_equal expected_res, res.map(&:to_h)
    end
  end

  describe "context shared by a multiplex run" do
    it "is provided as context:" do
      checks = []
      multiplex(queries, context: { instrumentation_checks: checks })
      assert_equal ["before multiplex 1", "before multiplex 2", "after multiplex 2", "after multiplex 1"], checks
    end
  end

  describe "instrumenting a multiplex run" do
    it "runs query instrumentation for each query and multiplex-level instrumentation" do
      checks = []
      queries_with_context = queries.map { |q| q.merge(context: { instrumentation_checks: checks }) }
      multiplex(queries_with_context, context: { instrumentation_checks: checks })
      assert_equal [
        "before multiplex 1",
        "before multiplex 2",
        "before Q1", "before Q2", "before Q3",
        "after Q3", "after Q2", "after Q1",
        "after multiplex 2",
        "after multiplex 1",
      ], checks
    end
  end

  describe "max_complexity" do
    it "can successfully calculate complexity" do
      message = "Query has complexity of 11, which exceeds max complexity of 10"
      results = multiplex(queries, max_complexity: 10)

      results.each do |res|
        assert_equal message, res["errors"][0]["message"]
      end
    end
  end

  describe "execute_query when errors are raised" do
    module InspectQueryInstrumentation
      def execute_multiplex(multiplex:)
        super
      ensure
        InspectQueryInstrumentation.last_json = multiplex.queries.first.result.to_json
      end

      class << self
        attr_accessor :last_json
      end
    end

    class InspectSchema < GraphQL::Schema
      class Query < GraphQL::Schema::Object
        field :raise_execution_error, String

        def raise_execution_error
          raise GraphQL::ExecutionError, "Whoops"
        end

        field :raise_error, String

        def raise_error
          raise GraphQL::Error, "Crash"
        end

        field :raise_syntax_error, String

        def raise_syntax_error
          raise SyntaxError
        end

        field :raise_exception, String

        def raise_exception
          raise Exception
        end
      end

      query(Query)
      trace_with(InspectQueryInstrumentation)
    end

    unhandled_err_json = '{}'

    it "can access the query results" do
      InspectSchema.execute("{ raiseExecutionError }")
      handled_err_json = '{"errors":[{"message":"Whoops","locations":[{"line":1,"column":3}],"path":["raiseExecutionError"]}],"data":{"raiseExecutionError":null}}'
      assert_equal handled_err_json, InspectQueryInstrumentation.last_json


      assert_raises(GraphQL::Error) do
        InspectSchema.execute("{ raiseError }")
      end

      assert_equal unhandled_err_json, InspectQueryInstrumentation.last_json
    end

    it "can access the query results when the error is not a StandardError" do
      assert_raises(SyntaxError) do
        InspectSchema.execute("{ raiseSyntaxError }")
      end
      assert_equal unhandled_err_json, InspectQueryInstrumentation.last_json

      assert_raises(Exception) do
        InspectSchema.execute("{ raiseException }")
      end
      assert_equal unhandled_err_json, InspectQueryInstrumentation.last_json
    end
  end

  describe "context[:trace]" do
    class MultiplexTraceSchema < GraphQL::Schema
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

        attr_reader :execute_multiplex_count, :execute_query_count
      end

      query(Query)
    end

    it "uses it instead of making a new trace" do
      query_str = "{ int }"
      trace_instance = MultiplexTraceSchema::Trace.new
      res = MultiplexTraceSchema.multiplex([{query: query_str}, {query: query_str}], context: { trace: trace_instance })
      assert_equal [1, 1], res.map { |r| r["data"]["int"]}

      assert_equal 1, trace_instance.execute_multiplex_count
      assert_equal 2, trace_instance.execute_query_count
    end
  end
end
