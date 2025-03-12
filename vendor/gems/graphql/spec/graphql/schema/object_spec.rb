# frozen_string_literal: true
require "spec_helper"
describe GraphQL::Schema::Object do
  describe "class attributes" do
    let(:object_class) { Jazz::Ensemble }

    it "tells type data" do
      assert_equal "Ensemble", object_class.graphql_name
      assert_equal "A group of musicians playing together", object_class.description
      assert_equal 9, object_class.fields.size
      assert_equal [
          "GloballyIdentifiable",
          "HasMusicians",
          "InvisibleNameEntity",
          "NamedEntity",
          "PrivateNameEntity",
        ], object_class.interfaces.map(&:graphql_name).sort
      # It filters interfaces, too
      assert_equal [
          "GloballyIdentifiable",
          "HasMusicians",
          "NamedEntity"
        ], object_class.interfaces({}).map(&:graphql_name).sort
      # Compatibility methods are delegated to the underlying BaseType
      assert object_class.respond_to?(:connection_type)
    end

    describe "path" do
      it "is the type name" do
        assert_equal "Ensemble", object_class.path
      end
    end

    it "inherits fields and interfaces" do
      new_object_class = Class.new(object_class) do
        field :newField, String
        field :name, String, description: "The new description", null: true
      end

      # one more than the parent class
      assert_equal 10, new_object_class.fields.size
      # inherited interfaces are present
      expected_interface_names = [
        "GloballyIdentifiable",
        "HasMusicians",
        "InvisibleNameEntity",
        "NamedEntity",
        "PrivateNameEntity",
      ]
      assert_equal expected_interface_names, object_class.interfaces.map(&:graphql_name).sort
      assert_equal expected_interface_names, new_object_class.interfaces.map(&:graphql_name).sort
      # The new field is present
      assert new_object_class.fields.key?("newField")
      # The overridden field is present:
      name_field = new_object_class.fields["name"]
      assert_equal "The new description", name_field.description
    end

    it "inherits name and description" do
      # Manually assign a name since `.name` isn't populated for dynamic classes
      new_subclass_1 = Class.new(object_class) do
        graphql_name "NewSubclass"
      end
      new_subclass_2 = Class.new(new_subclass_1)
      assert_equal "NewSubclass", new_subclass_1.graphql_name
      assert_equal "NewSubclass", new_subclass_2.graphql_name
      assert_equal object_class.description, new_subclass_2.description
    end

    it "implements visibility constrained interface when context is private" do
      found_interfaces = object_class.interfaces({ private: true })
      assert_equal 5, found_interfaces.count
      assert found_interfaces.any? { |int| int.graphql_name == 'PrivateNameEntity' }
    end

    it "should take Ruby name (without Type suffix) as default graphql name" do
      TestingClassType = Class.new(GraphQL::Schema::Object)
      assert_equal "TestingClass", TestingClassType.graphql_name
    end

    it "raise on anonymous class without declared graphql name" do
      anonymous_class = Class.new(GraphQL::Schema::Object)
      assert_raises GraphQL::RequiredImplementationMissingError do
        anonymous_class.graphql_name
      end
    end

    class OverrideNameObject < GraphQL::Schema::Object
      class << self
        def default_graphql_name
          "Override"
        end
      end
    end

    it "can override the default graphql_name" do
      override_name_object = OverrideNameObject

      assert_equal "Override", override_name_object.graphql_name
    end
  end

  describe "implementing interfaces" do
    it "raises an error when trying to implement a non-interface module" do
      object_type = Class.new(GraphQL::Schema::Object)

      module NotAnInterface
      end

      err = assert_raises do
        object_type.implements(NotAnInterface)
      end

      message = "NotAnInterface cannot be implemented since it's not a GraphQL Interface. Use `include` for plain Ruby modules."
      assert_equal message, err.message
    end

    it "does not inherit singleton methods from base interface when implementing another interface" do
      object_type = Class.new(GraphQL::Schema::Object)
      methods = object_type.singleton_methods
      method_defs = Hash[methods.zip(methods.map{|method| object_type.method(method.to_sym)})]

      module InterfaceType
        include GraphQL::Schema::Interface
      end

      object_type.implements(InterfaceType)
      new_method_defs = Hash[methods.zip(methods.map{|method| object_type.method(method.to_sym)})]
      assert_equal method_defs, new_method_defs
    end
  end

  it "doesnt convolute field names that differ with underscore" do
    interface = Module.new do
      include GraphQL::Schema::Interface
      graphql_name 'TestInterface'
      description 'Requires an id'

      field :id, GraphQL::Types::ID, null: false
    end

    object = Class.new(GraphQL::Schema::Object) do
      graphql_name 'TestObject'
      implements interface
      global_id_field :id

      field :_id, String, description: 'database id', null: true
    end

    assert_equal 2, object.fields.size
  end

  describe "wrapping a Hash" do
    it "automatically looks up symbol and string keys" do
      query_str = <<-GRAPHQL
      {
        hashyEnsemble {
          musicians { name }
          formedAt
        }
      }
      GRAPHQL
      res = Jazz::Schema.execute(query_str)
      ensemble = res["data"]["hashyEnsemble"]
      assert_equal ["Jerry Garcia"], ensemble["musicians"].map { |m| m["name"] }
      assert_equal "May 5, 1965", ensemble["formedAt"]
    end

    it "works with strings and symbols" do
      query_str = <<-GRAPHQL
      {
        hashByString { falsey }
        hashBySym { falsey }
      }
      GRAPHQL
      res = Jazz::Schema.execute(query_str)
      assert_equal false, res["data"]["hashByString"]["falsey"]
      assert_equal false, res["data"]["hashBySym"]["falsey"]
    end
  end

  describe "wrapping `nil`" do
    it "doesn't wrap nil in lists" do
      query_str = <<-GRAPHQL
      {
        namedEntities {
          name
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      expected_items = [{"name" => "Bela Fleck and the Flecktones"}, nil]
      assert_equal expected_items, res["data"]["namedEntities"]
    end
  end

  describe "in queries" do
    after {
      Jazz::Models.reset
    }

    it "returns data" do
      query_str = <<-GRAPHQL
      {
        ensembles { name }
        instruments { name }
      }
      GRAPHQL
      res = Jazz::Schema.execute(query_str)
      expected_ensembles = [
        {"name" => "Bela Fleck and the Flecktones"},
        {"name" => "ROBERT GLASPER Experiment"},
      ]
      assert_equal expected_ensembles, res["data"]["ensembles"]
      assert_equal({"name" => "Banjo"}, res["data"]["instruments"].first)
    end

    it "does mutations" do
      mutation_str = <<-GRAPHQL
      mutation AddEnsemble($name: String!) {
        addEnsemble(input: { name: $name }) {
          id
        }
      }
      GRAPHQL

      query_str = <<-GRAPHQL
      query($id: ID!) {
        find(id: $id) {
          ... on Ensemble {
            name
          }
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(mutation_str, variables: { name: "Miles Davis Quartet" })
      new_id = res["data"]["addEnsemble"]["id"]

      res2 = Jazz::Schema.execute(query_str, variables: { id: new_id })
      assert_equal "Miles Davis Quartet", res2["data"]["find"]["name"]
    end

    it "initializes root wrappers once" do
      query_str = " { oid1: objectId oid2: objectId }"
      res = Jazz::Schema.execute(query_str)
      assert_equal res["data"]["oid1"], res["data"]["oid2"]
    end

    it "skips fields properly" do
      query_str = "{ find(id: \"MagicalSkipId\") { __typename } }"
      res = Jazz::Schema.execute(query_str)
      skip_value = {}
      assert_equal({"data" => skip_value }, res.to_h)
    end
  end

  describe "when fields conflict with built-ins" do
    it "warns when no override" do
      expected_warning = "X's `field :method` conflicts with a built-in method, use `resolver_method:` to pick a different resolver method for this field (for example, `resolver_method: :resolve_method` and `def resolve_method`). Or use `method_conflict_warning: false` to suppress this warning.\n"
      assert_output "", expected_warning do
        Class.new(GraphQL::Schema::Object) do
          graphql_name "X"
          field :method, String
        end
      end
    end

    it "warns when override matches field name" do
      expected_warning = "X's `field :object` conflicts with a built-in method, use `resolver_method:` to pick a different resolver method for this field (for example, `resolver_method: :resolve_object` and `def resolve_object`). Or use `method_conflict_warning: false` to suppress this warning.\n"
      assert_output "", expected_warning do
        Class.new(GraphQL::Schema::Object) do
          graphql_name "X"
          field :object, String, resolver_method: :object
        end
      end
    end

    it "doesn't warn with a resolver_method: override" do
      assert_output "", "" do
        Class.new(GraphQL::Schema::Object) do
          graphql_name "X"
          field :method, String, resolver_method: :resolve_method
        end
      end
    end

    it "doesn't warn with a method: override" do
      assert_output "", "" do
        Class.new(GraphQL::Schema::Object) do
          graphql_name "X"
          field :module, String, method: :mod
        end
      end
    end

    it "doesn't warn with a suppression" do
      assert_output "", "" do
        Class.new(GraphQL::Schema::Object) do
          graphql_name "X"
          field :method, String, method_conflict_warning: false
        end
      end
    end

    it "doesn't warn when parsing a schema" do
      assert_output "", "" do
        schema = GraphQL::Schema.from_definition <<-GRAPHQL
        type Query {
          method: String
        }
        GRAPHQL
        assert_equal ["method"], schema.query.fields.keys
      end
    end

    it "doesn't warn when passing object through using resolver_method" do
      assert_output "", "" do
        Class.new(GraphQL::Schema::Object) do
          graphql_name "X"
          field :thing, String, resolver_method: :object
        end
      end
    end
  end

  describe "type-specific invalid null errors" do
    class ObjectInvalidNullSchema < GraphQL::Schema
      module Numberable
        include GraphQL::Schema::Interface

        field :float, Float, null: false

        def float
          nil
        end
      end

      class Query < GraphQL::Schema::Object
        implements Numberable

        field :int, Integer, null: false
        def int
          nil
        end
      end
      query(Query)

      def self.type_error(err, ctx)
        raise err
      end
    end

    it "raises them when invalid nil is returned" do
      assert_raises(ObjectInvalidNullSchema::Query::InvalidNullError) do
        ObjectInvalidNullSchema.execute("{ int }")
      end
    end

    it "raises them for fields inherited from interfaces" do
      assert_raises(ObjectInvalidNullSchema::Query::InvalidNullError) do
        ObjectInvalidNullSchema.execute("{ float }")
      end
    end
  end

  it "has a consistent object shape" do
    type_defn_shapes = Set.new
    example_shapes_by_name = {}
    ObjectSpace.each_object(Class) do |cls|
      if cls < GraphQL::Schema::Object
        shape = cls.instance_variables
        # these are from a custom test
        shape.delete(:@configs)
        shape.delete(:@future_schema)
        shape.delete(:@metadata)
        shape.delete(:@admin_only)
        if type_defn_shapes.add?(shape)
          example_shapes_by_name[cls.graphql_name] = shape
        end
      end
    end

    # Uncomment this to debug shapes:
    # File.open("shapes.txt", "w+") do |f|
    #   f.puts(type_defn_shapes.to_a.map { |ary| ary.inspect }.join("\n"))
    #   example_shapes_by_name.each do |name, sh|
    #     f.puts("#{name} ==> #{sh.inspect}")
    #   end
    # end

    default_shape = Class.new(GraphQL::Schema::Object).instance_variables
    default_type_with_connection_type = Class.new(GraphQL::Schema::Object) { graphql_name("Thing") }
    default_type_with_connection_type.connection_type # initialize the relay metadata
    default_shape_with_connection_type = default_type_with_connection_type.instance_variables
    default_edge_shape = Class.new(GraphQL::Types::Relay::BaseEdge).instance_variables
    default_connection_shape = Class.new(GraphQL::Types::Relay::BaseConnection).instance_variables
    default_mutation_payload_shape = Class.new(GraphQL::Schema::RelayClassicMutation) { graphql_name("DoSomething") }.payload_type.instance_variables
    default_visibility_shape = Class.new(GraphQL::Schema::Object).instance_variables
    expected_default_shapes = [
      default_shape,
      default_shape_with_connection_type,
      default_edge_shape,
      default_connection_shape,
      default_mutation_payload_shape,
      default_visibility_shape
    ]

    type_defn_shapes_a = type_defn_shapes.to_a
    assert type_defn_shapes_a.find { |sh| sh == default_shape }, "There's a match for default_shape"
    assert type_defn_shapes_a.find { |sh| sh == default_shape_with_connection_type }, "There's a match for default_shape_with_connection_type"
    assert type_defn_shapes_a.find { |sh| sh == default_edge_shape }, "There's a match for default_edge_shape"
    assert type_defn_shapes_a.find { |sh| sh == default_connection_shape }, "There's a match for default_connection_shape"
    assert type_defn_shapes_a.find { |sh| sh == default_mutation_payload_shape }, "There's a match for default_mutation_payload_shape"
    assert type_defn_shapes_a.find { |sh| sh == default_visibility_shape }, "There's a match for default_visibility_shape"

    extra_shapes = type_defn_shapes_a - expected_default_shapes
    extra_shapes_by_name = {}
    extra_shapes.each do |shape|
      name = example_shapes_by_name.key(shape)
      extra_shapes_by_name[name] = shape
    end

    assert_equal({}, extra_shapes_by_name, "There aren't any extra shape profiles")
  end

  describe "overriding wrap" do
    class WrapOverrideSchema < GraphQL::Schema
      module LogTrace
        def trace(key, data)
          if ((q = data[:query]) && (c = q.context))
            c[:log] << key
          end
          yield
        end
        ["parse", "lex", "validate",
        "analyze_query", "analyze_multiplex",
        "execute_query", "execute_multiplex",
        "execute_field", "execute_field_lazy",
        "authorized", "authorized_lazy",
        "resolve_type", "resolve_type_lazy",
        "execute_query_lazy"].each do |method_name|
          define_method(method_name) do |**data, &block|
            trace(method_name, data, &block)
          end
        end
      end

      class SimpleMethodCallField < GraphQL::Schema::Field
        def resolve(obj, args, ctx)
          obj.public_send("resolve_#{@original_name}")
        end
      end

      module CustomIntrospection
        class DynamicFields < GraphQL::Introspection::DynamicFields
          field_class(SimpleMethodCallField)
          field :__typename, String

          def self.wrap(obj, ctx)
            OpenStruct.new(resolve___typename: "Wrapped")
          end
        end
      end

      class Query < GraphQL::Schema::Object
        field_class(SimpleMethodCallField)
        def self.wrap(obj, ctx)
          OpenStruct.new(resolve_int: 5)
        end
        field :int, Integer, null: false
      end

      query(Query)
      introspection(CustomIntrospection)
      trace_with(LogTrace)
    end

    it "avoids calls to Object.authorized? and uses the returned object" do
      log = []
      res = WrapOverrideSchema.execute("{ __typename int }", context: { log: log })
      assert_equal "Wrapped", res["data"]["__typename"]
      assert_equal 5, res["data"]["int"]
      expected_log = [
        "validate",
        "analyze_query",
        "execute_query",
        "execute_field",
        "execute_field",
        "execute_query_lazy"
      ]

      assert_equal expected_log, log
    end
  end

  describe ".comment" do
    it "isn't inherited and can be set to nil" do
      obj1 = Class.new(GraphQL::Schema::Object) do
        graphql_name "Obj1"
        comment "TODO: fix this"
      end

      obj2 = Class.new(obj1) do
        graphql_name("Obj2")
      end

      assert_equal "TODO: fix this", obj1.comment
      assert_nil obj2.comment
      obj1.comment(nil)
      assert_nil obj1.comment
    end
  end

  describe "when defined with no fields" do
    class NoFieldsSchema < GraphQL::Schema
      class NoFieldsThing < GraphQL::Schema::Object
      end

      class NoFieldsCompatThing < GraphQL::Schema::Object
        has_no_fields(true)
      end

      class Query < GraphQL::Schema::Object
        field :no_fields_thing, NoFieldsThing
        field :no_fields_compat_thing, NoFieldsCompatThing
      end

      query(Query)
    end

    it "raises an error at runtime and printing" do
      refute NoFieldsSchema::NoFieldsThing.has_no_fields?

      expected_message = "Object types must have fields, but NoFieldsThing doesn't have any. Define a field for this type, remove it from your schema, or add `has_no_fields(true)` to its definition.

This will raise an error in a future GraphQL-Ruby version.
"
      res = assert_warns(expected_message) do
        NoFieldsSchema.execute("{ noFieldsThing { blah } }")
      end
      assert_equal ["Field 'blah' doesn't exist on type 'NoFieldsThing'"], res["errors"].map { |err| err["message"] }

      assert_warns(expected_message) do
        NoFieldsSchema.to_definition
      end

      assert_warns(expected_message) do
        NoFieldsSchema.to_json
      end
    end

    it "doesn't raise an error if has_no_fields(true)" do
      assert NoFieldsSchema::NoFieldsCompatThing.has_no_fields?

      res = assert_warns "" do
        NoFieldsSchema.execute("{ noFieldsCompatThing { blah } }")
      end
      assert_equal ["Field 'blah' doesn't exist on type 'NoFieldsCompatThing'"], res["errors"].map { |e| e["message"] }
    end
  end
end
