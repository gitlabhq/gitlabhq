# frozen_string_literal: true
require "graphql"
ADD_WARDEN = false
require "jazz"
require "benchmark/ips"
require "stackprof"
require "memory_profiler"
require "graphql/batch"
require "securerandom"

module GraphQLBenchmark
  QUERY_STRING = GraphQL::Introspection::INTROSPECTION_QUERY
  DOCUMENT = GraphQL.parse(QUERY_STRING)
  SCHEMA = Jazz::Schema

  BENCHMARK_PATH = File.expand_path("../", __FILE__)
  CARD_SCHEMA = GraphQL::Schema.from_definition(File.read(File.join(BENCHMARK_PATH, "schema.graphql")))
  ABSTRACT_FRAGMENTS = GraphQL.parse(File.read(File.join(BENCHMARK_PATH, "abstract_fragments.graphql")))
  ABSTRACT_FRAGMENTS_2_QUERY_STRING = File.read(File.join(BENCHMARK_PATH, "abstract_fragments_2.graphql"))
  ABSTRACT_FRAGMENTS_2 = GraphQL.parse(ABSTRACT_FRAGMENTS_2_QUERY_STRING)

  BIG_SCHEMA = GraphQL::Schema.from_definition(File.join(BENCHMARK_PATH, "big_schema.graphql"))
  BIG_QUERY_STRING = File.read(File.join(BENCHMARK_PATH, "big_query.graphql"))
  BIG_QUERY = GraphQL.parse(BIG_QUERY_STRING)

  FIELDS_WILL_MERGE_SCHEMA = GraphQL::Schema.from_definition("type Query { hello: String }")
  FIELDS_WILL_MERGE_QUERY = GraphQL.parse("{ #{Array.new(5000, "hello").join(" ")} }")

  module_function
  def self.run(task)
    Benchmark.ips do |x|
      case task
      when "query"
        x.report("query") { SCHEMA.execute(document: DOCUMENT) }
      when "validate"
        x.report("validate - introspection ") { CARD_SCHEMA.validate(DOCUMENT) }
        x.report("validate - abstract fragments") { CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS) }
        x.report("validate - abstract fragments 2") { CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS_2) }
        x.report("validate - big query") { BIG_SCHEMA.validate(BIG_QUERY) }
        x.report("validate - fields will merge") { FIELDS_WILL_MERGE_SCHEMA.validate(FIELDS_WILL_MERGE_QUERY) }
      when "scan"
        require "graphql/c_parser"
        x.report("scan c - introspection") { GraphQL.scan_with_c(QUERY_STRING) }
        x.report("scan - introspection") { GraphQL.scan_with_ruby(QUERY_STRING) }
        x.report("scan c - fragments") { GraphQL.scan_with_c(ABSTRACT_FRAGMENTS_2_QUERY_STRING) }
        x.report("scan - fragments") { GraphQL.scan_with_ruby(ABSTRACT_FRAGMENTS_2_QUERY_STRING) }
        x.report("scan c - big query") { GraphQL.scan_with_c(BIG_QUERY_STRING) }
        x.report("scan - big query") { GraphQL.scan_with_ruby(BIG_QUERY_STRING) }
      when "parse"
        # Uncomment this to use the C parser:
        # require "graphql/c_parser"
        x.report("parse - introspection") { GraphQL.parse(QUERY_STRING) }
        x.report("parse - fragments") { GraphQL.parse(ABSTRACT_FRAGMENTS_2_QUERY_STRING) }
        x.report("parse - big query") { GraphQL.parse(BIG_QUERY_STRING) }
      else
        raise("Unexpected task #{task}")
      end
    end
  end

  def self.profile_parse
    # To profile the C parser instead:
    # require "graphql/c_parser"

    report = MemoryProfiler.report do
      GraphQL.parse(BIG_QUERY_STRING)
      GraphQL.parse(QUERY_STRING)
      GraphQL.parse(ABSTRACT_FRAGMENTS_2_QUERY_STRING)
    end
    report.pretty_print
  end

  def self.validate_memory
    FIELDS_WILL_MERGE_SCHEMA.validate(FIELDS_WILL_MERGE_QUERY)

    report = MemoryProfiler.report do
      FIELDS_WILL_MERGE_SCHEMA.validate(FIELDS_WILL_MERGE_QUERY)
      nil
    end

    report.pretty_print
  end

  def self.profile
    # Warm up any caches:
    SCHEMA.execute(document: DOCUMENT)
    # CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS)
    res = nil
    result = StackProf.run(mode: :wall) do
      # CARD_SCHEMA.validate(ABSTRACT_FRAGMENTS)
      res = SCHEMA.execute(document: DOCUMENT)
    end
    StackProf::Report.new(result).print_text
  end

  def self.build_large_schema
    Class.new(GraphQL::Schema) do
      query_t = Class.new(GraphQL::Schema::Object) do
        graphql_name("Query")
        int_ts = 5.times.map do |i|
          int_t = Module.new do
            include GraphQL::Schema::Interface
            graphql_name "Interface#{i}"
            5.times do |n2|
              field :"field#{n2}", String do
                argument :arg, String
              end
            end
          end
          field :"int_field_#{i}", int_t
          int_t
        end

        obj_ts = 100.times.map do |n|
          input_obj_t = Class.new(GraphQL::Schema::InputObject) do
            graphql_name("Input#{n}")
            argument :arg, String
          end
          obj_t = Class.new(GraphQL::Schema::Object) do
            graphql_name("Object#{n}")
            implements(*int_ts)
            20.times do |n2|
              field :"field#{n2}", String do
                argument :input, input_obj_t
              end

            end
            field :self_field, self
            field :int_0_field, int_ts[0]
          end

          field :"rootfield#{n}", obj_t
          obj_t
        end

        10.times do |n|
          union_t = Class.new(GraphQL::Schema::Union) do
            graphql_name "Union#{n}"
            possible_types(*obj_ts.sample(10))
          end
          field :"unionfield#{n}", union_t
        end
      end
      query(query_t)
    end
  end

  def self.profile_boot
    Benchmark.ips do |x|
      x.config(time: 10)
      x.report("Booting large schema") {
        build_large_schema
      }
    end

    result = StackProf.run(mode: :wall, interval: 1) do
      build_large_schema
    end
    StackProf::Report.new(result).print_text

    retained_schema = nil
    report = MemoryProfiler.report do
      retained_schema = build_large_schema
    end

    report.pretty_print
  end

  SILLY_LARGE_SCHEMA = build_large_schema

  def self.profile_small_query_on_large_schema
    schema = Class.new(SILLY_LARGE_SCHEMA)
    Benchmark.ips do |x|
      x.report("Run small query") {
        schema.execute("{ __typename }")
      }
    end

    result = StackProf.run(mode: :wall, interval: 1) do
      schema.execute("{ __typename }")
    end
    StackProf::Report.new(result).print_text

    StackProf.run(mode: :wall, out: "tmp/small_query.dump", interval: 1) do
      schema.execute("{ __typename }")
    end

    report = MemoryProfiler.report do
      schema.execute("{ __typename }")
    end
    puts "\n\n"
    report.pretty_print
  end

  def self.profile_large_introspection
    schema = SILLY_LARGE_SCHEMA
    Benchmark.ips do |x|
      x.config(time: 10)
      x.report("Run large introspection") {
        schema.to_json
      }
    end

    result = StackProf.run(mode: :wall) do
      schema.to_json
    end
    StackProf::Report.new(result).print_text

    retained_schema = nil
    report = MemoryProfiler.report do
      schema.to_json
    end
    puts "\n\n"
    report.pretty_print
  end

  def self.profile_large_analysis
    query_str = "query {\n".dup
    5.times do |n|
      query_str << "  intField#{n} { "
      20.times do |o|
        query_str << "...Obj#{o}Fields "
      end
      query_str << "}\n"
    end
    query_str << "}"

    20.times do |o|
      query_str << "fragment Obj#{o}Fields on Object#{o} { "
      20.times do |f|
        query_str << "  field#{f}(arg: \"a\")\n"
      end
      query_str << "  selfField { selfField { selfField { __typename } } }\n"
      # query_str << "  int0Field { ...Int0Fields }"
      query_str << "}\n"
    end
    # query_str << "fragment Int0Fields on Interface0 { __typename }"
    query = GraphQL::Query.new(SILLY_LARGE_SCHEMA, query_str)
    analyzers = [
      GraphQL::Analysis::AST::FieldUsage,
      GraphQL::Analysis::AST::QueryDepth,
      GraphQL::Analysis::AST::QueryComplexity
    ]
    Benchmark.ips do |x|
      x.report("Running introspection") {
        GraphQL::Analysis::AST.analyze_query(query, analyzers)
      }
    end

    StackProf.run(mode: :wall, out: "last-stackprof.dump", interval: 1) do
      GraphQL::Analysis::AST.analyze_query(query, analyzers)
    end

    result = StackProf.run(mode: :wall, interval: 1) do
      GraphQL::Analysis::AST.analyze_query(query, analyzers)
    end

    StackProf::Report.new(result).print_text

    report = MemoryProfiler.report do
      GraphQL::Analysis::AST.analyze_query(query, analyzers)
    end
    puts "\n\n"
    report.pretty_print
  end

  # Adapted from https://github.com/rmosolgo/graphql-ruby/issues/861
  def self.profile_large_result
    schema = ProfileLargeResult::Schema
    document = ProfileLargeResult::ALL_FIELDS
    Benchmark.ips do |x|
      x.config(time: 10)
      x.report("Querying for #{ProfileLargeResult::DATA.size} objects") {
        schema.execute(document: document)
      }
    end

    result = StackProf.run(mode: :wall, interval: 1) do
      schema.execute(document: document)
    end
    StackProf::Report.new(result).print_text

    report = MemoryProfiler.report do
      schema.execute(document: document)
    end

    report.pretty_print
  end

  def self.profile_small_result
    schema = ProfileLargeResult::Schema
    document = GraphQL.parse <<-GRAPHQL
      query {
        foos(first: 5) {
          __typename
          id
          int1
          int2
          string1
          string2
          foos(first: 5) {
            __typename
            string1
            string2
            foo {
              __typename
              int1
            }
          }
        }
      }
    GRAPHQL

    Benchmark.ips do |x|
      x.config(time: 10)
      x.report("Querying for #{ProfileLargeResult::DATA.size} objects") {
        schema.execute(document: document)
      }
    end

    StackProf.run(mode: :wall, interval: 1, out: "tmp/small.dump") do
      schema.execute(document: document)
    end

    result = StackProf.run(mode: :wall, interval: 1) do
      schema.execute(document: document)
    end
    StackProf::Report.new(result).print_text

    report = MemoryProfiler.report do
      schema.execute(document: document)
    end

    report.pretty_print
  end

  def self.profile_small_introspection
    schema = ProfileLargeResult::Schema
    document = GraphQL.parse(GraphQL::Introspection::INTROSPECTION_QUERY)

    Benchmark.ips do |x|
      x.config(time: 5)
      x.report("Introspection") {
        schema.execute(document: document)
      }
    end

    result = StackProf.run(mode: :wall, interval: 1) do
      schema.execute(document: document)
    end

    StackProf::Report.new(result).print_text

    report = MemoryProfiler.report do
      schema.execute(document: document)
    end

    report.pretty_print
  end

  module ProfileLargeResult
    def self.eager_or_proc(value)
      ENV["EAGER"] ? value : -> { value }
    end
    DATA_SIZE = 1000
    DATA = DATA_SIZE.times.map {
      eager_or_proc({
          id:             SecureRandom.uuid,
          int1:           SecureRandom.random_number(100000),
          int2:           SecureRandom.random_number(100000),
          string1:        eager_or_proc(SecureRandom.base64),
          string2:        SecureRandom.base64,
          boolean1:       SecureRandom.random_number(1) == 0,
          boolean2:       SecureRandom.random_number(1) == 0,
          int_array:      eager_or_proc(10.times.map { eager_or_proc(SecureRandom.random_number(100000)) } ),
          string_array:   10.times.map { SecureRandom.base64 },
          boolean_array:  10.times.map { SecureRandom.random_number(1) == 0 },
      })
    }

    module Bar
      include GraphQL::Schema::Interface
      field :string_array, [String], null: false
    end

    module Baz
      include GraphQL::Schema::Interface
      implements Bar
      field :int_array, [Integer], null: false
      field :boolean_array, [Boolean], null: false
    end


    class ExampleExtension < GraphQL::Schema::FieldExtension
    end

    class FooType < GraphQL::Schema::Object
      implements Baz
      field :id, ID, null: false, extensions: [ExampleExtension]
      field :int1, Integer, null: false, extensions: [ExampleExtension]
      field :int2, Integer, null: false, extensions: [ExampleExtension]
      field :string1, String, null: false do
        argument :arg1, String, required: false
        argument :arg2, String, required: false
        argument :arg3, String, required: false
        argument :arg4, String, required: false
      end

      field :string2, String, null: false do
        argument :arg1, String, required: false
        argument :arg2, String, required: false
        argument :arg3, String, required: false
        argument :arg4, String, required: false
      end

      field :boolean1, Boolean, null: false do
        argument :arg1, String, required: false
        argument :arg2, String, required: false
        argument :arg3, String, required: false
        argument :arg4, String, required: false
      end
      field :boolean2, Boolean, null: false do
        argument :arg1, String, required: false
        argument :arg2, String, required: false
        argument :arg3, String, required: false
        argument :arg4, String, required: false
      end

      field :foos, [FooType], null: false, description: "Return a list of Foo objects" do
        argument :first, Integer, default_value: DATA_SIZE
      end

      def foos(first:)
        DATA.first(first)
      end

      field :foo, FooType
      def foo
        DATA.sample
      end
    end

    class QueryType < GraphQL::Schema::Object
      description "Query root of the system"
      field :foos, [FooType], null: false, description: "Return a list of Foo objects" do
        argument :first, Integer, default_value: DATA_SIZE
      end
      def foos(first:)
        DATA.first(first)
      end
    end

    class Schema < GraphQL::Schema
      query QueryType
      # use GraphQL::Dataloader
      lazy_resolve Proc, :call
    end

    ALL_FIELDS = GraphQL.parse <<-GRAPHQL
      query($skip: Boolean = false) {
        foos {
          id @skip(if: $skip)
          int1
          int2
          string1
          string2
          boolean1
          boolean2
          stringArray
          intArray
          booleanArray
        }
      }
    GRAPHQL
  end

  def self.profile_to_definition
    require_relative "./batch_loading"
    schema = ProfileLargeResult::Schema
    schema.to_definition

    Benchmark.ips do |x|
      x.report("to_definition") { schema.to_definition }
    end

    result = StackProf.run(mode: :wall, interval: 1) do
      schema.to_definition
    end
    StackProf::Report.new(result).print_text

    report = MemoryProfiler.report do
      schema.to_definition
    end

    report.pretty_print
  end

  def self.profile_from_definition
    # require "graphql/c_parser"
    schema_str = SILLY_LARGE_SCHEMA.to_definition

    Benchmark.ips do |x|
      x.report("from_definition") { GraphQL::Schema.from_definition(schema_str) }
    end

    result = StackProf.run(mode: :wall, interval: 1) do
      GraphQL::Schema.from_definition(schema_str)
    end
    StackProf::Report.new(result).print_text

    report = MemoryProfiler.report do
      GraphQL::Schema.from_definition(schema_str)
    end

    report.pretty_print
  end

  def self.profile_batch_loaders
    require_relative "./batch_loading"
    include BatchLoading

    document = GraphQL.parse <<-GRAPHQL
    {
      braves: team(name: "Braves") { ...TeamFields }
      bulls: team(name: "Bulls") { ...TeamFields }
    }

    fragment TeamFields on Team {
      players {
        team {
          players {
            team {
              name
            }
          }
        }
      }
    }
    GRAPHQL
    batch_result = GraphQLBatchSchema.execute(document: document).to_h
    dataloader_result = GraphQLDataloaderSchema.execute(document: document).to_h
    no_batch_result = GraphQLNoBatchingSchema.execute(document: document).to_h

    results = [batch_result, dataloader_result, no_batch_result].uniq
    if results.size > 1
      puts "Batch result:"
      pp batch_result
      puts "Dataloader result:"
      pp dataloader_result
      puts "No-batch result:"
      pp no_batch_result
      raise "Got different results -- fix implementation before benchmarking."
    end

    Benchmark.ips do |x|
      x.report("GraphQL::Batch") { GraphQLBatchSchema.execute(document: document) }
      x.report("GraphQL::Dataloader") { GraphQLDataloaderSchema.execute(document: document) }
      x.report("No Batching") { GraphQLNoBatchingSchema.execute(document: document) }

      x.compare!
    end

    puts "========== GraphQL-Batch Memory =============="
    report = MemoryProfiler.report do
      GraphQLBatchSchema.execute(document: document)
    end

    report.pretty_print

    puts "========== Dataloader Memory ================="
    report = MemoryProfiler.report do
      GraphQLDataloaderSchema.execute(document: document)
    end

    report.pretty_print

    puts "========== No Batch Memory =============="
    report = MemoryProfiler.report do
      GraphQLNoBatchingSchema.execute(document: document)
    end

    report.pretty_print
  end

  def self.profile_schema_memory_footprint
    schema = nil
    report = MemoryProfiler.report do
      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"
        100.times do |i|
          type = Class.new(GraphQL::Schema::Object) do
            graphql_name "Object#{i}"
            field :f, Integer
          end
          field "f#{i}", type
        end
      end

      thing_type = Class.new(GraphQL::Schema::Object) do
        graphql_name "Thing"
        field :name, String
      end

      mutation_type = Class.new(GraphQL::Schema::Object) do
        graphql_name "Mutation"
        100.times do |i|
          mutation_class = Class.new(GraphQL::Schema::RelayClassicMutation) do
            graphql_name "Do#{i}"
            argument :id, "ID"
            field :thing, thing_type
            field :things, thing_type.connection_type
          end
          field "f#{i}", mutation: mutation_class
        end
      end

      schema = Class.new(GraphQL::Schema) do
        query(query_type)
        mutation(mutation_type)
      end
    end

    report.pretty_print
  end

  class StackDepthSchema < GraphQL::Schema
    class Thing < GraphQL::Schema::Object
      field :thing, self do
        argument :lazy, Boolean, default_value: false
      end

      def thing(lazy:)
        if lazy
          -> { :something }
        else
          :something
        end
      end

      field :stack_trace_depth, Integer do
        argument :lazy, Boolean, default_value: false
      end

      def stack_trace_depth(lazy:)
        get_depth = -> {
          graphql_caller = caller.select { |c| c.include?("graphql") }
          graphql_caller.size
        }

        if lazy
          get_depth
        else
          get_depth.call
        end
      end
    end

    class Query < GraphQL::Schema::Object
      field :thing, Thing

      def thing
        :something
      end
    end

    query(Query)
    lazy_resolve(Proc, :call)
  end

  def self.profile_stack_depth
    query_str = <<-GRAPHQL
    query($lazyThing: Boolean!, $lazyStackTrace: Boolean!) {
      thing {
        thing(lazy: $lazyThing) {
          thing(lazy: $lazyThing) {
            thing(lazy: $lazyThing) {
              thing(lazy: $lazyThing) {
                stackTraceDepth(lazy: $lazyStackTrace)
              }
            }
          }
        }
      }
    }
    GRAPHQL

    eager_res = StackDepthSchema.execute(query_str, variables: { lazyThing: false, lazyStackTrace: false })
    lazy_res = StackDepthSchema.execute(query_str, variables: { lazyThing: true, lazyStackTrace: false })
    very_lazy_res = StackDepthSchema.execute(query_str, variables: { lazyThing: true, lazyStackTrace: true })
    get_depth = ->(result) { result["data"]["thing"]["thing"]["thing"]["thing"]["thing"]["stackTraceDepth"] }

    puts <<~RESULT
    Result         Depth
    ---------------------
    Eager          #{get_depth.call(eager_res)}
    Lazy           #{get_depth.call(lazy_res)}
    Very Lazy      #{get_depth.call(very_lazy_res)}
    RESULT
  end
end
