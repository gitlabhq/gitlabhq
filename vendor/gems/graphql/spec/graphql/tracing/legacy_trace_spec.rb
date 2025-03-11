# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::LegacyTrace do
  it "calls tracers on a parent schema class" do
    custom_tracer = Module.new do
      def self.trace(key, data)
        if key == "execute_query"
          data[:query].context[:tracer_ran] = true
        end
        yield
      end
    end

    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name("Query")
      field :int, Integer
      def int
        4
      end
    end

    parent_schema = Class.new(GraphQL::Schema) do
      query(query_type)
      tracer(custom_tracer, silence_deprecation_warning: true)
    end

    child_schema = Class.new(parent_schema)


    res1 = parent_schema.execute("{ int }")
    assert_equal true, res1.context[:tracer_ran]

    res2 = child_schema.execute("{ int }")
    assert_equal true, res2.context[:tracer_ran]
  end

  it "Works with new trace modules in the parent class" do
    custom_tracer = Module.new do
      def self.trace(key, data)
        if key == "execute_query"
          data[:query].context[:tracer_ran] = true
        end
        yield
      end
    end

    custom_trace_module = Module.new do
      def execute_query(query:)
        query.context[:trace_module_ran] = true
        super
      end
    end


    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name("Query")
      field :int, Integer
      def int
        4
      end
    end

    parent_schema = Class.new(GraphQL::Schema) do
      query(query_type)
      trace_with(custom_trace_module)
    end

    child_schema = Class.new(parent_schema) do
      tracer(custom_tracer)
    end

    res1 = parent_schema.execute("{ int }")
    assert_equal true, res1.context[:trace_module_ran]
    assert_nil res1.context[:tracer_ran]

    res2 = child_schema.execute("{ int }")
    assert_equal true, res2.context[:trace_module_ran], "New Trace Ran"
    assert_equal true, res2.context[:tracer_ran], "Legacy Trace Ran"
  end
end
