# frozen_string_literal: true
require "spec_helper"
describe GraphQL::Schema::Field do
  describe "graphql definition" do
    let(:object_class) { Jazz::Query }
    let(:field) { object_class.fields["inspectInput"] }

    describe "path" do
      it "is the object/interface and field name" do
        assert_equal "Query.inspectInput", field.path
        assert_equal "GloballyIdentifiable.id", Jazz::GloballyIdentifiableType.fields["id"].path
      end
    end

    describe "inspect" do
      it "includes the path and return type" do
        assert_equal "#<Jazz::BaseField Query.inspectInput(...): [String!]!>", field.inspect
      end
    end

    it "can add argument directly with add_argument" do
      argument = Jazz::Query.fields["instruments"].arguments["family"]

      field.add_argument(argument)

      assert_equal "family", field.arguments["family"].name
      assert_equal Jazz::Family, field.arguments["family"].type
    end

    it "camelizes the field name, unless camelize: false" do
      assert_equal 'inspectInput', field.name

      underscored_field = GraphQL::Schema::Field.from_options(:underscored_field, String, null: false, camelize: false, owner: nil) do
        argument :underscored_arg, String, camelize: false
      end.ensure_loaded

      arg_name, arg_defn = underscored_field.arguments.first
      assert_equal 'underscored_arg', arg_name
      assert_equal 'underscored_arg', arg_defn.name
    end

    it "works with arbitrary hash keys" do
      result = Jazz::Schema.execute "{ complexHashKey }", root_value: { :'foo bar/fizz-buzz' => "OK!"}
      hash_val = result["data"]["complexHashKey"]
      assert_equal "OK!", hash_val, "It looked up the hash key"
    end

    it "exposes the method override" do
      object = Class.new(Jazz::BaseObject) do
        field :t, String, method: :tt, null: true
      end
      assert_equal :tt, object.fields["t"].method_sym
      assert_equal "tt", object.fields["t"].method_str
    end

    it "accepts a block for definition" do
      field_defn = nil
      object = Class.new(Jazz::BaseObject) do
        graphql_name "JustAName"

        field_defn = field :test do
          argument :test, String
          description "A Description."
          comment "A Comment."
          type String
        end
      end

      assert_nil field_defn.description, "The block isn't called right away"
      assert_nil field_defn.type, "The block isn't called right away"
      field_defn.ensure_loaded
      assert_equal "String", field_defn.type.graphql_name

      assert_equal "test", object.fields["test"].arguments["test"].name
      assert_equal "A Description.", object.fields["test"].description
      assert_equal "A Comment.", object.fields["test"].comment
    end

    it "sets connection? when type is given in a block" do
      field_defn = nil
      Class.new(Jazz::BaseObject) do
        graphql_name "JustAName"

        field_defn = field :instruments do
          type Jazz::InstrumentType.connection_type
        end
      end

      assert_equal false, field_defn.connection?
      assert_equal false, field_defn.scoped?
      assert_equal [], field_defn.extensions
      field_defn.ensure_loaded
      assert_equal true, field_defn.scoped?
      assert_equal true, field_defn.connection?
      assert_equal [GraphQL::Schema::Field::ScopeExtension, GraphQL::Schema::Field::ConnectionExtension], field_defn.extensions.map(&:class)
    end

    it "accepts a block for definition and yields the field if the block has an arity of one" do
      object = Class.new(Jazz::BaseObject) do
        graphql_name "JustAName"

        field :test, String do |field|
          field.argument :test, String
          field.description "A Description."
          field.comment "A Comment."
        end
      end

      assert_equal "test", object.fields["test"].arguments["test"].name
      assert_equal "A Description.", object.fields["test"].description
      assert_equal "A Comment.", object.fields["test"].comment
    end

    it "accepts anonymous classes as type" do
      type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'MyType'
      end
      field = GraphQL::Schema::Field.from_options(:my_field, type, owner: nil, null: true)
      assert_equal type, field.type
    end

    describe "introspection?" do
      it "returns false on regular fields" do
        assert_equal false, field.introspection?
      end

      it "returns true on predefined introspection fields" do
        assert_equal true, GraphQL::Schema.types['__Type'].fields.values.first.introspection?
      end
    end

    describe "extras" do
      it "can get errors, which adds path" do
        query_str = <<-GRAPHQL
        query {
          find(id: "Musician/Herbie Hancock") {
            ... on Musician {
              addError
            }
          }
        }
        GRAPHQL

        res = Jazz::Schema.execute(query_str)
        err = res["errors"].first
        assert_equal "this has a path", err["message"]
        assert_equal ["find", "addError"], err["path"]
        assert_equal [{"line"=>4, "column"=>15}], err["locations"]
      end

      it "can get methods from the field instance" do
        query_str = <<-GRAPHQL
        {
          upcaseCheck1
          upcaseCheck2
          upcaseCheck3
          upcaseCheck4
        }
        GRAPHQL
        res = Jazz::Schema.execute(query_str)
        assert_equal "nil", res["data"].fetch("upcaseCheck1")
        assert_equal "false", res["data"]["upcaseCheck2"]
        assert_equal "TRUE", res["data"]["upcaseCheck3"]
        assert_equal "\"WHY NOT?\"", res["data"]["upcaseCheck4"]
      end

      it "can be read via #extras" do
        field = Jazz::Musician.fields["addError"]
        assert_equal [:execution_errors], field.extras
      end

      it "can be added by passing an array of symbols to #extras" do
        object = Class.new(Jazz::BaseObject) do
          graphql_name "JustAName"

          field :test, String, extras: [:lookahead]
        end

        field = object.fields['test']

        field.extras([:ast_node])
        assert_equal [:lookahead, :ast_node], field.extras
      end

      describe "ruby argument error" do
        class ArgumentErrorSchema < GraphQL::Schema
          class Query < GraphQL::Schema::Object

            def inspect
              "#<#{self.class}>"
            end

            field :f1, String do
              argument :something, Int, required: false
            end

            def f1
              "OK"
            end

            field :f2, String, resolver_method: :field_2 do
              argument :something, Int, required: false
            end

            def field_2(something_else: nil)
              "ALSO OK"
            end

            field :f3, String do
              argument :something, Int, required: false
            end

            def f3(always_missing:)
              "NEVER OK"
            end

            field :f4, String

            def f4(never_positional, ok_optional = :ok, *ok_rest)
              "NEVER OK"
            end

            field :f5, String do
              argument :something, Int, required: false
            end

            def f5(**ok_keyrest)
              "OK"
            end
          end
          query(Query)
        end

        it "raises a nice error when missing" do
          assert_equal "OK", ArgumentErrorSchema.execute("{ f1 }")["data"]["f1"]
          assert_equal "ALSO OK", ArgumentErrorSchema.execute("{ f2 }")["data"]["f2"]
          err = assert_raises GraphQL::Schema::Field::FieldImplementationFailed do
            ArgumentErrorSchema.execute("{ f1(something: 12) }")
          end
          assert_equal "Failed to call `:f1` on #<ArgumentErrorSchema::Query> because the Ruby method params were incompatible with the GraphQL arguments:

- `something: 12` was given by GraphQL but not defined in the Ruby method. Add `something:` to the method parameters.
", err.message

          assert_instance_of ArgumentError, err.cause

          err = assert_raises GraphQL::Schema::Field::FieldImplementationFailed do
            ArgumentErrorSchema.execute("{ f2(something: 12) }")
          end
          assert_equal "Failed to call `:field_2` on #<ArgumentErrorSchema::Query> because the Ruby method params were incompatible with the GraphQL arguments:

- `something: 12` was given by GraphQL but not defined in the Ruby method. Add `something:` to the method parameters.
", err.message


          err = assert_raises GraphQL::Schema::Field::FieldImplementationFailed do
            ArgumentErrorSchema.execute("{ f3(something: 1) }")
          end
          assert_equal "Failed to call `:f3` on #<ArgumentErrorSchema::Query> because the Ruby method params were incompatible with the GraphQL arguments:

- `something: 1` was given by GraphQL but not defined in the Ruby method. Add `something:` to the method parameters.
- `always_missing:` is required by Ruby, but not by GraphQL. Consider `always_missing: nil` instead, or making this argument required in GraphQL.
", err.message

          err = assert_raises GraphQL::Schema::Field::FieldImplementationFailed do
            ArgumentErrorSchema.execute("{ f4 }")
          end
          assert_equal "Failed to call `:f4` on #<ArgumentErrorSchema::Query> because the Ruby method params were incompatible with the GraphQL arguments:

- `never_positional` is required by Ruby, but GraphQL doesn't pass positional arguments. If it's meant to be a GraphQL argument, use `never_positional:` instead. Otherwise, remove it.
", err.message

          assert_equal "OK", ArgumentErrorSchema.execute("{ f5(something: 2) }")["data"]["f5"]
        end
      end

      describe "argument_details" do
        class ArgumentDetailsSchema < GraphQL::Schema
          class Query < GraphQL::Schema::Object
            field :argument_details, [String], null: false, extras: [:argument_details] do
              argument :arg1, Int, required: false
              argument :arg2, Int, required: false, default_value: 2
            end

            def argument_details(argument_details:, arg1: nil, arg2:)
              [
                argument_details.class.name,
                argument_details.argument_values.values.first.class.name,
                # `.keyword_arguments` includes extras:
                argument_details.keyword_arguments.keys.join("|"),
                # `.argument_values` includes only defined GraphQL arguments:
                argument_details.argument_values.keys.join("|"),
                argument_details.argument_values[:arg2].default_used?.inspect
              ]
            end
          end

          query(Query)
        end

        it "provides metadata about arguments" do
          res = ArgumentDetailsSchema.execute("{ argumentDetails }")
          expected_strs = [
            "GraphQL::Execution::Interpreter::Arguments",
            "GraphQL::Execution::Interpreter::ArgumentValue",
            "arg2|argument_details",
            "arg2",
            "true",
          ]
          assert_equal expected_strs, res["data"]["argumentDetails"]
        end
      end
    end

    it "is the #owner of its arguments" do
      field = Jazz::Query.fields["find"]
      argument = field.arguments["id"]
      assert_equal field, argument.owner
    end

    it "has a reference to the object that owns it with #owner" do
      assert_equal Jazz::Query, field.owner
    end

    describe "type" do
      it "tells the return type" do
        assert_equal "[String!]!", field.type.to_type_signature
      end

      it "returns the type class" do
        field = Jazz::Query.fields["nowPlaying"]
        assert_equal Jazz::PerformingAct, field.type.of_type
      end
    end

    describe "complexity" do
      it "accepts a keyword argument" do
        object = Class.new(Jazz::BaseObject) do
          graphql_name "complexityKeyword"

          field :complexityTest, String, complexity: 25
        end

        assert_equal 25, object.fields["complexityTest"].complexity
      end

      it "accepts a proc in the definition block" do
        object = Class.new(Jazz::BaseObject) do
          graphql_name "complexityKeyword"

          field :complexityTest, String do
            complexity ->(_ctx, _args, _child_complexity) { 52 }
          end
        end

        assert_equal 52, object.fields["complexityTest"].complexity.call(nil, nil, nil)
      end

      it "accepts an integer in the definition block" do
        object = Class.new(Jazz::BaseObject) do
          graphql_name "complexityKeyword"

          field :complexityTest, String do
            complexity 38
          end
        end

        assert_equal 38, object.fields["complexityTest"].complexity
      end

      it 'fails if the complexity is not numeric and not a proc' do
        err = assert_raises(RuntimeError) do
          Class.new(Jazz::BaseObject) do
            graphql_name "complexityKeyword"

            field :complexityTest, String do
              complexity 'One hundred and eighty'
            end.ensure_loaded
          end
        end

        assert_match(/^Invalid complexity:/, err.message)
      end

      it 'fails if the proc does not accept 3 parameters' do
        err = assert_raises(RuntimeError) do
          Class.new(Jazz::BaseObject) do
            graphql_name "complexityKeyword"

            field :complexityTest, String do
              complexity ->(one, two) { 52 }
            end.ensure_loaded
          end
        end

        assert_match(/^A complexity proc should always accept 3 parameters/, err.message)
      end

      it 'fails if second argument is a mutation instead of a type' do
        mutation_class = Class.new(GraphQL::Schema::Mutation) do
          graphql_name "Thing"
          field :stuff, String, null: false
        end

        err = assert_raises(ArgumentError) do
          Class.new(Jazz::BaseObject) do
            graphql_name "complexityKeyword"

            field :complexityTest, mutation_class
          end
        end

        assert_match(/^Use `field :complexityTest, mutation: Mutation, ...` to provide a mutation to this field instead/, err.message)
      end
    end
  end

  describe "build type errors" do
    it "includes the full name" do
      thing = Class.new(GraphQL::Schema::Object) do
        graphql_name "Thing"
        # `Set` is a class but not a GraphQL type
        field :stuff, Set, null: false
      end

      err = assert_raises GraphQL::Schema::Field::MissingReturnTypeError do
        thing.fields["stuff"].type
      end

      assert_includes err.message, "Thing.stuff"
      assert_includes err.message, "Unexpected class/module"
    end

    it "makes a suggestion when the type is false" do
      err = assert_raises GraphQL::Schema::Field::MissingReturnTypeError do
        Class.new(GraphQL::Schema::Object) do
          graphql_name "Thing"
          # False might come from an invalid `!`
          field :stuff, false, null: false
        end
      end

      assert_includes err.message, "Thing.stuff"
      assert_includes err.message, "Received `false` instead of a type, maybe a `!` should be replaced with `null: true` (for fields) or `required: true` (for arguments)"
    end
  end

  describe "mutation" do
    it "passes when not including extra arguments" do
      mutation_class = Class.new(GraphQL::Schema::Mutation) do
        graphql_name "Thing"
        field :stuff, String, null: false
      end

      obj = Class.new(GraphQL::Schema::Object) do
        field(:my_field, mutation: mutation_class, null: true)
      end
      assert_equal obj.fields["myField"].mutation, mutation_class
    end
  end

  describe '#deprecation_reason' do
    it "reads and writes" do
      object_class = Class.new(GraphQL::Schema::Object) do
        graphql_name "Thing"
        field :stuff, String, null: false, deprecation_reason: "Broken"
      end
      field = object_class.fields["stuff"]
      assert_equal "Broken", field.deprecation_reason
      field.deprecation_reason += "!!"
      assert_equal "Broken!!", field.deprecation_reason
    end
  end

  describe "#original_name" do
    it "is exactly the same as the passed in name" do
      field = GraphQL::Schema::Field.from_options(
        :my_field,
        String,
        null: false,
        camelize: true
      )

      assert_equal :my_field, field.original_name
    end
  end

  describe "generated default" do
    class GeneratedDefaultTestSchema < GraphQL::Schema
      class BaseField < GraphQL::Schema::Field
        def resolve_field(obj, args, ctx)
          resolve(obj, args, ctx)
        end
      end

      class Company < GraphQL::Schema::Object
        field :id, ID, null: false
      end

      class Query < GraphQL::Schema::Object
        field_class BaseField

        field :company, Company do
          argument :id, ID
        end

        def company(id:)
          OpenStruct.new(id: id)
        end
      end

      query(Query)
    end

    it "works" do
      res = GeneratedDefaultTestSchema.execute("{ company(id: \"1\") { id } }")
      assert_equal "1", res["data"]["company"]["id"]
    end
  end

  describe ".connection_extension" do
    class CustomConnectionExtension < GraphQL::Schema::Field::ConnectionExtension
      def apply
        super
        field.argument(:z, String, required: false)
      end
    end

    class CustomExtensionField < GraphQL::Schema::Field
      connection_extension(CustomConnectionExtension)
    end

    class CustomExtensionObject < GraphQL::Schema::Object
      field_class CustomExtensionField

      field :ints, GraphQL::Types::Int.connection_type, null: false, scope: false
    end

    it "can be customized" do
      field = CustomExtensionObject.fields["ints"]
      assert_equal [CustomConnectionExtension], field.extensions.map(&:class)
      assert_equal ["after", "before", "first", "last", "z"], field.arguments.keys.sort
    end

    it "can be inherited" do
      child_field_class = Class.new(CustomExtensionField)
      assert_equal CustomConnectionExtension, child_field_class.connection_extension
    end
  end

  describe "retrieving nested hash keys using dig" do
    class DigSchema < GraphQL::Schema
      class PersonType < GraphQL::Schema::Object
        field :name, String, null: false
      end

      class MovieType < GraphQL::Schema::Object
        field :title, String, null: false, dig: [:title]
        field :stars, [PersonType], null: false, dig: ["credits", "stars"]
        field :metascore, Float, null: false, dig: [:meta, "metascore"]
        field :release_date, String, null: false, dig: [:meta, :release_date]
        field :includes_wilhelm_scream, Boolean, null: false, dig: [:meta, "wilhelm_scream"]
        field :nullable_field, String, dig: [:this_should, :work_since, :dig_handles, :safe_expansion]
      end

      class QueryType < GraphQL::Schema::Object
        field :a_good_laugh, MovieType, null: false
        def a_good_laugh
          {
            :title => "Monty Python and the Holy Grail",
            :meta => {
              "metascore" => 91,
              :release_date => "1975-05-25T00:00:00+00:00",
              "wilhelm_scream" => false
            },
            "credits" => {
              "stars" => [
                { :name => "Graham Chapman" },
                { :name => "John Cleese" }
              ]
            }
          }
        end
      end

      query(QueryType)
    end

    it "finds the expected data" do
      res = DigSchema.execute <<-GRAPHQL
      {
        aGoodLaugh {
          title
          includesWilhelmScream
          metascore
          nullableField
          releaseDate
          stars {
            name
          }
        }
      }
      GRAPHQL

      result = res["data"]["aGoodLaugh"]
      expected_result = {
        "title" => "Monty Python and the Holy Grail",
        "includesWilhelmScream" => false,
        "metascore" => 91.0,
        "nullableField" => nil,
        "releaseDate" => "1975-05-25T00:00:00+00:00",
        "stars" => [
          { "name" => "Graham Chapman" },
          { "name" => "John Cleese" }
        ]
      }
      assert_equal expected_result, result
    end
  end

  describe "looking up hash keys with case" do
    class HashKeySchema < GraphQL::Schema
      class ResultType < GraphQL::Schema::Object
        field :lowercase, String, camelize: false, null: true
        field :Capital, String, camelize: false, null: true
        field :Other, String, camelize: true, null: true
        field :OtherCapital, String, camelize: false, null: true, hash_key: "OtherCapital"
        # regression test against https://github.com/rmosolgo/graphql-ruby/issues/3944
        field :method, String, camelize: false, null: false, hash_key: "some_random_key"
        field :stringified_hash_key, String, null: false, hash_key: :stringified_hash_key
        field :boolean_true_with_hash_key, Boolean, null: false, hash_key: :boolean_true_with_hash_key
        field :boolean_false_with_hash_key, Boolean, null: false, hash_key: :boolean_false_with_hash_key
        field :boolean_false_with_symbolized_hash_key, Boolean, null: false, hash_key: :boolean_false_with_symbolized_hash_key
      end

      class QueryType < GraphQL::Schema::Object
        field :search_results, ResultType, null: false
        def search_results
          {
            "lowercase" => "lowercase-works",
            "Capital" => "capital-camelize-false-works",
            "Other" => "capital-camelize-true-works",
            "OtherCapital" => "explicit-hash-key-works",
            "some_random_key" => "hash-key-works-when-underlying-object-responds-to-field-name",
            "stringified_hash_key" => "hash-key-is-tried-as-string",
            "boolean_true_with_hash_key" => true,
            "boolean_false_with_hash_key" => false,
            :boolean_false_with_symbolized_hash_key => false
          }
        end

        field :ostruct_results, ResultType, null: false

        def ostruct_results
          OpenStruct.new(search_results)
        end
      end

      query(QueryType)
    end

    it "finds exact matches by hash key" do
      res = HashKeySchema.execute <<-GRAPHQL
      {
        searchResults {
          method
          lowercase
          Capital
          Other
          OtherCapital
          stringifiedHashKey
          booleanTrueWithHashKey
          booleanFalseWithHashKey
          booleanFalseWithSymbolizedHashKey
        }
      }
      GRAPHQL

      search_results = res["data"]["searchResults"]
      expected_result = {
        "lowercase" => "lowercase-works",
        "Capital" => "capital-camelize-false-works",
        "Other" => "capital-camelize-true-works",
        "OtherCapital" => "explicit-hash-key-works",
        "method" => "hash-key-works-when-underlying-object-responds-to-field-name",
        "stringifiedHashKey" => "hash-key-is-tried-as-string",
        "booleanTrueWithHashKey" => true,
        "booleanFalseWithHashKey" => false,
        "booleanFalseWithSymbolizedHashKey" => false

      }
      assert_equal expected_result, search_results
    end

    it "works with non-hash instances" do
      res = HashKeySchema.execute <<-GRAPHQL
      {
        ostructResults {
          method
          lowercase
          Capital
          Other
          OtherCapital
          stringifiedHashKey
          booleanTrueWithHashKey
          booleanFalseWithHashKey
          booleanFalseWithSymbolizedHashKey
        }
      }
      GRAPHQL

      search_results = res["data"]["ostructResults"]
      expected_result = {
        "lowercase" => "lowercase-works",
        "Capital" => "capital-camelize-false-works",
        "Other" => "capital-camelize-true-works",
        "OtherCapital" => "explicit-hash-key-works",
        "method" => "hash-key-works-when-underlying-object-responds-to-field-name",
        "stringifiedHashKey" => "hash-key-is-tried-as-string",
        "booleanTrueWithHashKey" => true,
        "booleanFalseWithHashKey" => false,
        "booleanFalseWithSymbolizedHashKey" => false
      }
      assert_equal expected_result, search_results
    end

    it "populates `method_str`" do
      hash_key_field = HashKeySchema.get_field("Result", "method")
      assert_equal "some_random_key", hash_key_field.method_str
    end
  end

  describe "when the owner is nil" do
    it "raises a descriptive error" do
      bad_field = GraphQL::Schema::Field.new(name: "something", owner: nil, type: String)
      assert_nil bad_field.owner
      err = assert_raises GraphQL::InvariantError do
        bad_field.owner_type
      end
      expected_message = "Field \"something\" (graphql name: \"something\") has no owner, but all fields should have an owner. How did this happen?!

This is probably a bug in GraphQL-Ruby, please report this error on GitHub: https://github.com/rmosolgo/graphql-ruby/issues/new?template=bug_report.md"

      assert_equal expected_message, err.message
    end
  end

  it "Delegates many properties to its @resolver_class" do
    resolver = Class.new(GraphQL::Schema::Resolver) do
      description "description 1"
      comment "comment 1"
      type [GraphQL::Types::Float], null: true

      argument :b, GraphQL::Types::Float
    end

    field = GraphQL::Schema::Field.new(name: "blah", owner: nil, resolver_class: resolver, extras: [:blah]) do
      argument :a, GraphQL::Types::Int
    end
    field.ensure_loaded

    assert_equal "description 1", field.description
    assert_equal "comment 1", field.comment
    assert_equal "[Float!]", field.type.to_type_signature
    assert_equal 1, field.complexity
    assert_equal :resolve_with_support, field.resolver_method
    assert_nil field.broadcastable?
    assert_equal false, field.has_max_page_size?
    assert_nil field.max_page_size
    assert_equal [:blah], field.extras
    assert_equal [:b, :a], field.all_argument_definitions.map(&:keyword)
    assert_equal true, field.scoped?

    resolver.description("description 2")
    resolver.comment("comment 2")
    resolver.type(GraphQL::Types::String, null: false)
    resolver.complexity(5)
    resolver.resolver_method(:blah)
    resolver.broadcastable(true)
    resolver.max_page_size(100)
    resolver.extras([:foo])
    resolver.argument(:c, GraphQL::Types::Boolean)

    assert_equal "description 2", field.description
    assert_equal "comment 2", field.comment
    assert_equal "String!", field.type.to_type_signature
    assert_equal 5, field.complexity
    assert_equal :blah, field.resolver_method
    assert_equal true, field.broadcastable?
    assert_equal true, field.has_max_page_size?
    assert_equal 100, field.max_page_size
    assert_equal [:blah, :foo], field.extras
    assert_equal [:b, :c, :a], field.all_argument_definitions.map(&:keyword)
    assert_equal false, field.scoped?
  end

  it "accepts partial overrides for type an nullability" do
    nonnull_float_resolver = Class.new(GraphQL::Schema::Resolver) do
      type GraphQL::Types::Float, null: false
    end

    nullable_field = GraphQL::Schema::Field.new(name: "blah", owner: nil, resolver_class: nonnull_float_resolver, null: true)
    assert_equal "Float", nullable_field.type.to_type_signature

    int_field = GraphQL::Schema::Field.new(name: "blah", owner: nil, resolver_class: nonnull_float_resolver, type: GraphQL::Types::Int)
    assert_equal "Int!", int_field.type.to_type_signature
  end

  class ResolverConnectionOverrideSchema < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      class Resolver < GraphQL::Schema::Resolver
        type [Int], null: false

        def resolve
          [1, 2, 3]
        end
      end

      field :f, GraphQL::Types::Int.connection_type, resolver: Resolver
    end

    query(Query)
  end

  it "uses the overridden type for detecting connections" do
    res = ResolverConnectionOverrideSchema.execute("{ f { nodes } }")
    assert_equal [1,2,3], res["data"]["f"]["nodes"]
  end

  it "has a consistent Object shape" do
    # This test will be inherently flaky: the `Field` instances
    # on the heap depends on what tests ran before this one and
    # whether or not GC ran since then.
    shapes = Set.new

    # This is custom state added by some test schemas:
    custom_ivars = [:@upcase, :@future_schema, :@visible, :@allow_for, :@metadata, :@admin_only]

    ObjectSpace.each_object(GraphQL::Schema::Field) do |field_obj|
      field_ivars = field_obj.instance_variables
      custom_ivars.each do |ivar|
        if field_ivars.delete(ivar) && field_obj.class == GraphQL::Schema::Field
          raise "Invariant: a built-in-based field instance has an ivar that was expected to be custom state(#{ivar.inspect}): #{field_obj.path} (#{field_obj.inspect})"
        end
      end
      shapes.add(field_ivars)
    end
    # To see the different shapes, uncomment this:
    # File.open("field_shapes.txt", "wb+") do |f|
    #   shapes.to_a.each do |shape|
    #     f.puts(shape.inspect + "\n")
    #   end
    # end
    default_field_shape = GraphQL::Introspection::TypeType.get_field("name").instance_variables
    # assert_equal [default_field_shape], shapes.to_a
  end

  it "works with implicit hash key and default value" do
    class HashDefautSchema < GraphQL::Schema
      class Example < GraphQL::Schema::Object
        field :implicit_lookup, [String, null: true]
        field :explicit_lookup, [String, null: true], hash_key: :nonexistent
      end

      class Query < GraphQL::Schema::Object
        field :example, Example, null: false

        def example
          Hash.new { [] }
        end
      end

      query(Query)
    end

    res = HashDefautSchema.execute('query { example { implicitLookup explicitLookup } }').to_h
    assert_equal({ "implicitLookup" => [], "explicitLookup" => [] }, res["data"]["example"])
  end

  module FieldConnectionTest
    class SomeConnection < GraphQL::Schema::Object; end
    class Connection < GraphQL::Schema::Object; end
  end

  it "Automatically detects connection, but can be overridden" do
    field = GraphQL::Schema::Field.new(name: "blah", owner: nil, type: FieldConnectionTest::SomeConnection)
    assert field.connection?
    field = GraphQL::Schema::Field.new(name: "blah", owner: nil, type: FieldConnectionTest::SomeConnection, connection: false)
    refute field.connection?

    field = GraphQL::Schema::Field.new(name: "blah", owner: nil, type: FieldConnectionTest::Connection)
    refute field.connection?
    field = GraphQL::Schema::Field.new(name: "blah", owner: nil, type: FieldConnectionTest::Connection, connection: true)
    assert field.connection?
  end
end
