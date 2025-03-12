# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Introspection::SchemaType do
  let(:schema) { Class.new(Dummy::Schema) { description("Cool schema") }}
  let(:query_string) {%|
    query getSchema {
      __schema {
        description
        types { name }
        queryType { fields { name }}
        mutationType { fields { name }}
      }
    }
  |}
  let(:result) { schema.execute(query_string) }

  it "exposes the schema" do
    expected = { "data" => {
      "__schema" => {
        "description" => "Cool schema",
        "types" => schema.types.values.sort_by(&:graphql_name).map { |t| t.graphql_name.nil? ? (p t; raise("no name for #{t}")) : {"name" => t.graphql_name} },
        "queryType"=>{
          "fields"=>[
            {"name"=>"allAnimal"},
            {"name"=>"allAnimalAsCow"},
            {"name"=>"allDairy"},
            {"name"=>"allEdible"},
            {"name"=>"allEdibleAsMilk"},
            {"name"=>"cheese"},
            {"name"=>"cow"},
            {"name"=>"dairy"},
            {"name"=>"deepNonNull"},
            {"name"=>"error"},
            {"name"=>"exampleBeverage"},
            {"name"=>"executionError"},
            {"name"=>"executionErrorWithExtensions"},
            {"name"=>"executionErrorWithOptions"},
            {"name"=>"favoriteEdible"},
            {"name"=>"fromSource"},
            {"name"=>"hugeInteger"},
            {"name"=>"maybeNull"},
            {"name"=>"milk"},
            {"name"=>"multipleErrorsOnNonNullableField"},
            {"name"=>"multipleErrorsOnNonNullableListField"},
            {"name"=>"root"},
            {"name"=>"searchDairy"},
            {"name"=>"tracingScalar"},
            {"name"=>"valueWithExecutionError"},
          ]
        },
        "mutationType"=> {
          "fields"=>[
            {"name"=>"pushValue"},
            {"name"=>"replaceValues"},
          ]
        },
      }
    }}
    assert_equal(expected, result.to_h)
  end

  describe "when the schema has types that are only reachable through hidden types" do
    let(:schema) do
      nested_invisible_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'NestedInvisible'
        field :foo, String, null: false
      end

      invisible_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Invisible'
        field :foo, String, null: false
        field :nested_invisible, nested_invisible_type, null: false

        def self.visible?(context)
          false
        end
      end

      invisible_input_type = Class.new(GraphQL::Schema::InputObject) do
        graphql_name 'InvisibleInput'
        argument :foo, String, required: false

        def self.visible?(context)
          false
        end
      end

      visible_input_type = Class.new(GraphQL::Schema::InputObject) do
        graphql_name 'VisibleInput'
        argument :foo, String, required: false
      end

      visible_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Visible'
        field :foo, String, null: false
      end

      invisible_orphan_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'InvisibleOrphan'
        field :foo, String, null: false

        def self.visible?(context)
          false
        end
      end

      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'
        field :foo, String, null: false
        field :invisible, invisible_type, null: false
        field :visible, visible_type, null: false
        field :with_invisible_args, String, null: false do
          argument :invisible, invisible_input_type, required: false
          argument :visible, visible_input_type
        end
      end

      Class.new(GraphQL::Schema) do
        query query_type
        orphan_types invisible_orphan_type
        use GraphQL::Schema::Warden if ADD_WARDEN
      end
    end

    let(:query_string) {%|
      query getSchema {
        __schema {
          types { name }
        }
      }
    |}

    it "only returns reachable types" do
      expected_types = [
        'Boolean',
        'Query',
        'String',
        'Visible',
        'VisibleInput',
        '__Directive',
        '__DirectiveLocation',
        '__EnumValue',
        '__Field',
        '__InputValue',
        '__Schema',
        '__Type',
        '__TypeKind'
      ]
      types = result['data']['__schema']['types'].map { |type| type.fetch('name') }
      assert_equal(expected_types, types)
    end
  end

  describe "when the schema has hidden directives" do
    let(:schema) do
      invisible_directive = Class.new(GraphQL::Schema::Directive) do
        graphql_name 'invisibleDirective'
        locations(GraphQL::Schema::Directive::QUERY)
        argument(:val, Integer, "Initial integer value.", required: false)

        def self.visible?(context)
          false
        end
      end

      visible_directive = Class.new(GraphQL::Schema::Directive) do
        graphql_name 'visibleDirective'
        locations(GraphQL::Schema::Directive::QUERY)
        argument(:val, Integer, "Initial integer value.", required: false)

        def self.visible?(context)
          true
        end
      end

      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'
        field :foo, String, null: false
      end

      Class.new(GraphQL::Schema) do
        use GraphQL::Schema::Visibility
        query query_type
        directives invisible_directive, visible_directive
      end
    end

    let(:query_string) {%|
      query getSchema {
        __schema {
          directives { name }
        }
      }
    |}

    it "only returns visible directives" do
      expected_dirs = ['deprecated', 'include', 'skip', 'oneOf', 'specifiedBy', 'visibleDirective']
      directives = result['data']['__schema']['directives'].map { |dir| dir.fetch('name') }
      assert_equal(expected_dirs.sort, directives.sort)
    end
  end
end
