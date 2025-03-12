# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::QueryComplexity do
  let(:schema) { Dummy::Schema }
  let(:reduce_result) { GraphQL::Analysis.analyze_query(query, [GraphQL::Analysis::QueryComplexity]) }
  let(:reduce_multiplex_result) {
    GraphQL::Analysis.analyze_multiplex(multiplex, [GraphQL::Analysis::QueryComplexity])
  }
  let(:variables) { {} }
  let(:query_context) { {} }
  let(:query) { GraphQL::Query.new(schema, query_string, context: query_context, variables: variables) }
  let(:multiplex) {
    GraphQL::Execution::Multiplex.new(
      schema: schema,
      queries: [query.dup, query.dup],
      context: {},
      max_complexity: 10
    )
  }

  describe "simple queries" do
    let(:query_string) {%|
      query cheeses {
        # complexity of 3
        cheese1: cheese(id: 1) {
          id
          flavor
          __typename
        }

        # complexity of 4
        cheese2: cheese(id: 2) {
          similarCheese(source: SHEEP) {
            ... on Cheese {
              similarCheese(source: SHEEP) {
                id
              }
            }
          }
        }
      }
    |}

    it "sums the complexity" do
      complexities = reduce_result.first
      assert_equal 8, complexities
    end
  end

  describe "with skip/include" do
    let(:query_string) {%|
      query cheeses($skip: Boolean = false, $include: Boolean = true) {
        fields: cheese(id: 1) {
          flavor
          origin @skip(if: $skip)
          source @include(if: $include)
        }
        inlineFragments: cheese(id: 1) {
          ...on Cheese { flavor }
          ...on Cheese @skip(if: $skip) { origin }
          ...on Cheese @include(if: $include) { source }
        }
        fragmentSpreads: cheese(id: 1) {
          ...Flavorful
          ...Original @skip(if: $skip)
          ...Sourced @include(if: $include)
        }
      }
      fragment Flavorful on Cheese { flavor }
      fragment Original on Cheese { origin }
      fragment Sourced on Cheese { source }
    |}

    it "sums up all included complexities" do
      assert_equal 12, reduce_result.first
    end

    describe "when skipped by directives" do
      let(:variables) { { "skip" => true, "include" => false } }
      it "doesn't include skipped fields and fragments" do
        assert_equal 6, reduce_result.first
      end
    end
  end

  describe "query with fragments" do
    let(:query_string) {%|
      {
        # complexity of 3
        cheese1: cheese(id: 1) {
          id
          flavor
        }

        # complexity of 7
        cheese2: cheese(id: 2) {
          ... cheeseFields1
          ... cheeseFields2
        }
      }

      fragment cheeseFields1 on Cheese {
        similarCow: similarCheese(source: COW) {
          id
          ... cheeseFields2
        }
      }

      fragment cheeseFields2 on Cheese {
        similarSheep: similarCheese(source: SHEEP) {
          id
        }
      }
    |}

    it "counts all fragment usages, not the definitions" do
      complexity = reduce_result.first
      assert_equal 10, complexity
    end

    describe "mutually exclusive types" do
      let(:query_string) {%|
        {
          favoriteEdible {
            # 1 for everybody
            fatContent

            # 1 for everybody
            ... on Edible {
              origin
            }

            # 1 for honey, aspartame
            ... on Sweetener {
              sweetness
            }

            # 2 for milk
            ... milkFields
            # 1 for cheese
            ... cheeseFields
            # 1 for honey
            ... honeyFields
            # 1 for milk + cheese
            ... dairyProductFields
          }
        }

        fragment milkFields on Milk {
          id
          source
        }

        fragment cheeseFields on Cheese {
          source
        }

        fragment honeyFields on Honey {
          flowerType
        }

        fragment dairyProductFields on DairyProduct {
          ... on Cheese {
            flavor
          }

          ... on Milk {
            flavors
          }
        }
      |}

      it "gets the max among options" do
        complexity = reduce_result.first
        assert_equal 6, complexity
      end
    end


    describe "when there are no selections on any object types" do
      let(:query_string) {%|
        {
          # 1 for everybody
          favoriteEdible {
            # 1 for everybody
            fatContent

            # 1 for everybody
            ... on Edible { origin }

            # 1 for honey, aspartame
            ... on Sweetener { sweetness }
          }
        }
      |}

      it "gets the max among interface types" do
        complexity = reduce_result.first
        assert_equal 4, complexity
      end
    end

    describe "redundant fields" do
      let(:query_string) {%|
      {
        favoriteEdible {
          fatContent
          # this is executed separately and counts separately:
          aliasedFatContent: fatContent

          ... on Edible {
            fatContent
          }

          ... edibleFields
        }
      }

      fragment edibleFields on Edible {
        fatContent
      }
      |}

      it "only counts them once" do
        complexity = reduce_result.first
        assert_equal 3, complexity
      end
    end

    describe "redundant fields not within a fragment" do
      let(:query_string) {%|
      {
        cheese {
          id
        }

        cheese {
          id
        }
      }
      |}

      it "only counts them once" do
        complexity = reduce_result.first
        assert_equal 2, complexity
      end
    end
  end

  describe "relay types" do
    let(:query) { GraphQL::Query.new(StarWars::Schema, query_string) }
    let(:query_string) {%|
    {
      rebels {
        ships(first: 1) {
          edges {
            node {
              id
            }
          }
          nodes {
            id
          }
          pageInfo {
            hasNextPage
          }
        }
      }
    }
    |}

    it "gets the complexity" do
      complexity = reduce_result.first
      expected_complexity = 1 + # rebels
        1 + # ships
        1 + # edges
        1 + # nodes
        1 + 1 + # pageInfo, hasNextPage
        1 + 1 + 1 # node, id, id
      assert_equal expected_complexity, complexity
    end

    describe "first/last" do
      let(:query_string) {%|
      {
        rebels {
          s1: ships(first: 5) {
            edges {
              node {
                id
              }
            }
            pageInfo {
              hasNextPage
            }
          }

          s2: ships(last: 3) {
            nodes { id }
          }
        }
      }
      |}

      it "uses first/last for calculating complexity" do
        complexity = reduce_result.first

        expected_complexity = (
          1 + # rebels
          (1 + 1 + (5 * 2) + 2) + # s1
          (1 + 1 + (3 * 1) + 0) # s2
        )
        assert_equal expected_complexity, complexity
      end
    end

    describe "Field-level max_page_size" do
      let(:query_string) {%|
      {
        rebels {
          ships {
            nodes { id }
          }
        }
      }
      |}

      it "uses field max_page_size" do
        complexity = reduce_result.first
        assert_equal 1 + 1 + 1 + (1000 * 1), complexity
      end
    end

    describe "Schema-level default_max_page_size" do
      let(:query_string) {%|
      {
        rebels {
          bases {
            nodes { id }
            totalCount
          }
        }
      }
      |}

      it "uses schema default_max_page_size" do
        complexity = reduce_result.first
        assert_equal 1 + 1 + 1 + (3 * 1) + 1, complexity
      end
    end

    describe "Field-level default_page_size" do
      let(:query_string) {%|
      {
        rebels {
          shipsWithDefaultPageSize {
            nodes { id }
          }
        }
      }
      |}

      it "uses field default_page_size" do
        complexity = reduce_result.first
        assert_equal 1 + 1 + 1 + (500 * 1), complexity
      end
    end

    describe "Schema-level default_page_size" do
      let(:query) { GraphQL::Query.new(StarWars::SchemaWithDefaultPageSize, query_string) }
      let(:query_string) {%|
      {
        rebels {
          bases {
            nodes { id }
            totalCount
          }
        }
      }
      |}

      it "uses schema default_page_size" do
        complexity = reduce_result.first
        assert_equal 1 + 1 + 1 + (2 * 1) + 1, complexity
      end
    end
  end

  describe "calculation complexity for a multiplex" do
    let(:query_string) {%|
      query cheeses {
        cheese(id: 1) {
          id
          flavor
          source
        }
      }
    |}


    it "sums complexity for both queries" do
      complexity = reduce_multiplex_result.first
      assert_equal 8, complexity
    end

    describe "abstract type" do
      let(:query_string) {%|
        query Edible {
          allEdible {
            origin
            fatContent
          }
        }
      |}
      it "sums complexity for both queries" do
        complexity = reduce_multiplex_result.first
        assert_equal 6, complexity
      end
    end
  end

  describe "custom complexities" do
    class CustomComplexitySchema < GraphQL::Schema
      module ComplexityInterface
        include GraphQL::Schema::Interface
        field :value, Int
      end

      class SingleComplexity < GraphQL::Schema::Object
        field :value, Int, complexity: 0.1
        field :complexity, SingleComplexity do
          argument :int_value, Int, required: false
          complexity(->(ctx, args, child_complexity) { args[:int_value] + child_complexity })
        end
        implements ComplexityInterface
      end

      class DoubleComplexity < GraphQL::Schema::Object
        field :value, Int, complexity: 4
        implements ComplexityInterface
      end

      class Query < GraphQL::Schema::Object
        field :complexity, SingleComplexity do
          argument :int_value, Int, required: false, prepare: ->(val, ctx) {
            if ctx[:raise_prepare_error]
              raise GraphQL::ExecutionError, "Boom"
            else
              val
            end
          }
          complexity ->(ctx, args, child_complexity) { args[:int_value] + child_complexity }
        end

        def complexity(int_value:)
          { value: int_value }
        end

        field :inner_complexity, ComplexityInterface do
          argument :value, Int, required: false
        end
      end

      query(Query)
      orphan_types(DoubleComplexity)

      module CustomIntrospection
        class DynamicFields < GraphQL::Introspection::DynamicFields
          field :__typename, String, complexity: 100
        end

        class EntryPoints < GraphQL::Introspection::EntryPoints
          class CustomIntrospectionField < GraphQL::Schema::Field
            def calculate_complexity(query:, nodes:, child_complexity:)
              child_complexity + 0.6
            end
          end
          field_class CustomIntrospectionField
          field :__schema, GraphQL::Schema::LateBoundType.new("__Schema")
        end
      end

      introspection(CustomIntrospection)
    end

    let(:query) { GraphQL::Query.new(complexity_schema, query_string, context: query_context) }
    let(:complexity_schema) { CustomComplexitySchema }
    let(:query_string) {%|
      {
        a: complexity(intValue: 3) { value }
        b: complexity(intValue: 6) {
          value
          complexity(intValue: 1) {
            value
          }
        }
      }
    |}

    it "sums the complexity" do
      complexity = reduce_result.first
      # 10 from `complexity`, `0.3` from `value`
      assert_equal 10.3, complexity
    end

    describe "introspection" do
      let(:query_string) { "{ __typename __schema { queryType } }"}

      it "does custom complexity for introspection" do
        complexity = reduce_result.first
        # 100 + 1 + 0.6
        assert_equal 101.6, complexity
      end
    end

    describe "same field on multiple types" do
      let(:query_string) {%|
      {
        innerComplexity(intValue: 2) {
          ... on SingleComplexity { value }
          ... on DoubleComplexity { value }
        }
      }
      |}

      it "picks them max for those fields" do
        complexity = reduce_result.first
        # 1 for innerComplexity + 4 for DoubleComplexity.value
        assert_equal 5, complexity
      end
    end

    describe "when prepare raises an error" do
      let(:query_string) { "{ complexity(intValue: 3) { value } }"}
      let(:query_context) { { raise_prepare_error: true } }

      it "handles it nicely" do
        result = query.result
        assert_equal ["Boom"], result["errors"].map { |e| e["message"] }
        complexity = reduce_result.first
        assert_equal 0.1, complexity
      end
    end
  end

  describe "custom complexities by complexity_for(...)" do
    class CustomComplexityByMethodSchema < GraphQL::Schema
      module ComplexityInterface
        include GraphQL::Schema::Interface
        field :value, Int
      end

      class SingleComplexity < GraphQL::Schema::Object
        field :value, Int, complexity: 0.1
        field :complexity, SingleComplexity do
          argument :int_value, Int, required: false

          def complexity_for(query:, child_complexity:, lookahead:)
            lookahead.arguments[:int_value] + child_complexity
          end
        end
        implements ComplexityInterface
      end

      class ComplexityFourField < GraphQL::Schema::Field
        def complexity_for(query:, lookahead:, child_complexity:)
          4
        end
      end

      class DoubleComplexity < GraphQL::Schema::Object
        field_class ComplexityFourField
        field :value, Int
        implements ComplexityInterface
      end

      class Thing < GraphQL::Schema::Object
        field :name, String
      end

      class CustomThingConnection < GraphQL::Types::Relay::BaseConnection
        edge_type Thing.edge_type
        field :something_special, String, complexity: 3
      end

      class Query < GraphQL::Schema::Object
        field :complexity, SingleComplexity do
          argument :int_value, Int, required: false
          def complexity_for(query:, child_complexity:, lookahead:)
            lookahead.arguments[:int_value] + child_complexity
          end
        end

        field :inner_complexity, ComplexityInterface do
          argument :value, Int, required: false
        end

        field :things, Thing.connection_type, max_page_size: 100 do
          argument :count, Int, validates: { numericality: { less_than: 50 } }
        end

        def things(count:)
          count.times.map {|t| {name: t.to_s}}
        end

        class ThingsCustom < GraphQL::Schema::Resolver
          type CustomThingConnection, null: false
          complexity 100

          def resolve
            5.times { |t| { name: "Thing #{t}" } }
          end
        end

        field :things_custom, resolver: ThingsCustom
      end

      query(Query)
      orphan_types(DoubleComplexity)
    end

    let(:query) { GraphQL::Query.new(complexity_schema, query_string) }
    let(:complexity_schema) { CustomComplexityByMethodSchema }
    let(:query_string) {%|
      {
        a: complexity(intValue: 3) { value }
        b: complexity(intValue: 6) {
          value
          complexity(intValue: 1) {
            value
          }
        }
      }
    |}

    it "sums the complexity" do
      complexity = reduce_result.first
      # 10 from `complexity`, `0.3` from `value`
      assert_equal 10.3, complexity
    end

    describe "same field on multiple types" do
      let(:query_string) {%|
      {
        innerComplexity(value: 2) {
          ... on SingleComplexity { value }
          ... on DoubleComplexity { value }
        }
      }
      |}

      it "picks them max for those fields" do
        complexity = reduce_result.first
        # 1 for innerComplexity + 4 for DoubleComplexity.value
        assert_equal 5, complexity
      end
    end

    describe "when the query fails validation" do
      let(:query_string) {%|
      {
        things(count: 200, first: 5) {
          nodes { name }
        }
      }
      |}
      it "handles the error" do
        res = GraphQL::Query.new(complexity_schema, query_string).result
        assert_equal ["count must be less than 50"], res["errors"].map { |e| e["message"] }
        assert_equal [], reduce_result, "It doesn't finish calculation"
      end
    end

    describe "when connection fields have custom complexity" do
      let(:query_string) { "{ thingsCustom(first: 2) { somethingSpecial nodes { name } } }"}

      it "uses the custom configured value" do
        complexity = reduce_result.first
        assert_equal 106, complexity
      end
    end
  end

  describe "field_complexity hook" do
    class CustomComplexityAnalyzer < GraphQL::Analysis::QueryComplexity
      def initialize(query)
        super
        @field_complexities_by_query = {}
      end

      def result
        super
        @field_complexities_by_query[@query]
      end

      private

      def field_complexity(scoped_type_complexity, max_complexity:, child_complexity:)
        @field_complexities_by_query[scoped_type_complexity.query] ||= {}
        @field_complexities_by_query[scoped_type_complexity.query][scoped_type_complexity.response_path] = {
          max_complexity: max_complexity,
          child_complexity: child_complexity,
        }
      end
    end

    let(:reduce_result) { GraphQL::Analysis.analyze_query(query, [CustomComplexityAnalyzer]) }

    let(:query_string) {%|
    {
      cheese {
        id
      }

      cheese {
        id
        flavor
      }
    }
    |}
    it "gets called for each field with complexity data" do
      field_complexities = reduce_result.first

      assert_equal({
        ['cheese', 'id'] => { max_complexity: 1, child_complexity: nil },
        ['cheese', 'flavor'] => { max_complexity: 1, child_complexity: nil },
        ['cheese'] => { max_complexity: 3, child_complexity: 2 },
      }, field_complexities)
    end
  end
end
