# frozen_string_literal: true
require "spec_helper"

describe "GraphQL::Authorization" do
  module AuthTest
    class Box
      attr_reader :value
      def initialize(value:)
        @value = value
      end
    end

    class BaseArgument < GraphQL::Schema::Argument
      def visible?(context)
        super && (context[:hide] ? @name != "hidden" : true)
      end

      def authorized?(parent_object, value, context)
        super && parent_object != :hide2
      end
    end

    class BaseInputObjectArgument < BaseArgument
      def authorized?(parent_object, value, context)
        super && parent_object != :hide3
      end
    end

    class BaseInputObject < GraphQL::Schema::InputObject
      argument_class BaseInputObjectArgument
    end

    class BaseField < GraphQL::Schema::Field
      argument_class BaseArgument
      def visible?(context)
        super && (context[:hide] ? @name != "hidden" : true)
      end

      def authorized?(object, args, context)
        if object == :raise
          raise GraphQL::UnauthorizedFieldError.new("raised authorized field error", object: object)
        end
        return Box.new(value: context[:lazy_field_authorized]) if context.key?(:lazy_field_authorized)

        super && object != :hide && object != :replace
      end
    end

    class BaseObject < GraphQL::Schema::Object
      field_class BaseField
    end

    module BaseInterface
      include GraphQL::Schema::Interface
    end

    class BaseEnumValue < GraphQL::Schema::EnumValue
      def initialize(*args, role: nil, **kwargs)
        @role = role
        super(*args, **kwargs)
      end

      def visible?(context)
        super && (context[:hide] ? @role != :hidden : true)
      end

      def authorized?(context)
        super && (context[:authorized] ? true : @role != :unauthorized)
      end
    end

    class BaseEnum < GraphQL::Schema::Enum
      enum_value_class(BaseEnumValue)
    end

    module HiddenInterface
      include BaseInterface

      definition_methods do
        def visible?(ctx)
          super && !ctx[:hide]
        end

        def resolve_type(obj, ctx)
          HiddenObject
        end
      end
    end

    module HiddenDefaultInterface
      if GraphQL::Schema.use_visibility_profile?
        include HiddenInterface
      else
        # Warden will detect no possible types
        include BaseInterface
      end

      def self.resolve_type(obj, ctx)
        HiddenObject
      end
    end

    class HiddenObject < BaseObject
      implements HiddenInterface
      implements HiddenDefaultInterface
      def self.visible?(ctx)
        super && !ctx[:hide]
      end

      field :some_field, String
    end

    class RelayObject < BaseObject
      def self.visible?(ctx)
        super && !ctx[:hidden_relay]
      end

      def self.authorized?(_val, ctx)
        super && !ctx[:unauthorized_relay]
      end

      field :some_field, String
    end

    class UnauthorizedObject < BaseObject
      def self.authorized?(value, context)
        if context[:raise]
          raise GraphQL::UnauthorizedError.new("raised authorized object error", object: value.object)
        end
        super && !context[:hide]
      end

      field :value, String, null: false, method: :itself
    end

    class UnauthorizedBox < BaseObject
      # Hide `"a"`
      def self.authorized?(value, context)
        super && value != "a"
      end

      field :value, String, null: false, method: :itself
    end

    module UnauthorizedInterface
      include BaseInterface

      def self.resolve_type(obj, ctx)
        if obj.is_a?(String)
          UnauthorizedCheckBox
        else
          raise "Unexpected value: #{obj.inspect}"
        end
      end
    end

    class UnauthorizedCheckBox < BaseObject
      implements UnauthorizedInterface
      # This authorized check returns a lazy object, it should be synced by the runtime.
      def self.authorized?(value, context)
        if !value.is_a?(String)
          raise "Unexpected box value: #{value.inspect}"
        end
        is_authed = super && value != "a"
        # Make it many levels nested just to make sure we support nested lazy objects
        Box.new(value: Box.new(value: Box.new(value: Box.new(value: is_authed))))
      end

      field :value, String, null: false, method: :itself
    end

    class IntegerObject < BaseObject
      def self.authorized?(obj, ctx)
        if !obj.is_a?(Integer)
          raise "Unexpected IntegerObject: #{obj}"
        end
        is_allowed = !(ctx[:unauthorized_relay] || obj == ctx[:exclude_integer])
        Box.new(value: Box.new(value: is_allowed))
      end
      field :value, Integer, null: false, method: :itself
    end

    class IntegerObjectEdge < GraphQL::Types::Relay::BaseEdge
      node_type(IntegerObject)
    end

    class IntegerObjectConnection < GraphQL::Types::Relay::BaseConnection
      edge_type(IntegerObjectEdge)
    end

    # This object responds with `replaced => false`,
    # but if its replacement value is used, it gives `replaced => true`
    class Replaceable
      def replacement
        { replaced: true }
      end

      def replaced
        false
      end
    end

    class ReplacedObject < BaseObject
      def self.authorized?(obj, ctx)
        super && !ctx[:replace_me]
      end

      field :replaced, Boolean, null: false
    end

    class LandscapeFeature < BaseEnum
      value "MOUNTAIN"
      value "STREAM", role: :unauthorized
      value "FIELD"
      value "TAR_PIT", role: :hidden
    end

    class Query < BaseObject
      def self.authorized?(obj, ctx)
        !ctx[:query_unauthorized]
      end

      field :hidden, Integer, null: false
      field :unauthorized, Integer, method: :itself
      field :int2, Integer do
        argument :int, Integer, required: false
        argument :hidden, Integer, required: false
        argument :unauthorized, Integer, required: false
      end

      def int2(**args)
        args[:unauthorized] || 1
      end

      field :landscape_feature, LandscapeFeature, null: false do
        argument :string, String, required: false
        argument :enum, LandscapeFeature, required: false
      end

      def landscape_feature(string: nil, enum: nil)
        string || enum
      end

      field :landscape_features, [LandscapeFeature], null: false do
        argument :strings, [String], required: false
        argument :enums, [LandscapeFeature], required: false
      end

      def landscape_features(strings: [], enums: [])
        strings + enums
      end

      def empty_array; []; end
      field :hidden_object, HiddenObject, null: false, resolver_method: :itself
      field :hidden_interface, HiddenInterface, null: false, resolver_method: :itself
      field :hidden_default_interface, HiddenDefaultInterface, null: false, resolver_method: :itself
      field :hidden_connection, RelayObject.connection_type, null: :false, resolver_method: :empty_array
      field :hidden_edge, RelayObject.edge_type, null: :false, resolver_method: :edge_object

      field :unauthorized_object, UnauthorizedObject, resolver_method: :itself
      field :unauthorized_connection, RelayObject.connection_type, null: false, resolver_method: :array_with_item
      field :unauthorized_edge, RelayObject.edge_type, null: false, resolver_method: :edge_object

      def edge_object
        OpenStruct.new(node: 100)
      end

      def array_with_item
        [1]
      end

      field :unauthorized_lazy_box, UnauthorizedBox do
        argument :value, String
      end
      def unauthorized_lazy_box(value:)
        # Make it extra nested, just for good measure.
        Box.new(value: Box.new(value: value))
      end
      field :unauthorized_list_items, [UnauthorizedObject]
      def unauthorized_list_items
        [self, self]
      end

      field :unauthorized_lazy_check_box, UnauthorizedCheckBox, resolver_method: :unauthorized_lazy_box do
        argument :value, String
      end

      field :unauthorized_interface, UnauthorizedInterface, resolver_method: :unauthorized_lazy_box do
        argument :value, String
      end

      field :unauthorized_lazy_list_interface, [UnauthorizedInterface, null: true]

      def unauthorized_lazy_list_interface
        ["z", Box.new(value: Box.new(value: "z2")), "a", Box.new(value: "a")]
      end

      field :integers, IntegerObjectConnection, null: false

      def integers
        [1,2,3]
      end

      field :lazy_integers, IntegerObjectConnection, null: false

      def lazy_integers
        Box.new(value: Box.new(value: [1,2,3]))
      end

      field :replaced_object, ReplacedObject, null: false
      def replaced_object
        Replaceable.new
      end
    end

    class DoHiddenStuff < GraphQL::Schema::RelayClassicMutation
      def self.visible?(ctx)
        super && (ctx[:hidden_mutation] ? false : true)
      end
    end

    class DoHiddenStuff2 < GraphQL::Schema::Mutation
      def self.visible?(ctx)
        super && !ctx[:hidden_mutation]
      end

      field :some_return_field, String
    end

    class DoUnauthorizedStuff < GraphQL::Schema::RelayClassicMutation
      def self.authorized?(obj, ctx)
        super && (ctx[:unauthorized_mutation] ? false : true)
      end
    end

    class Mutation < BaseObject
      field :do_hidden_stuff, mutation: DoHiddenStuff
      field :do_hidden_stuff2, mutation: DoHiddenStuff2
      field :do_unauthorized_stuff, mutation: DoUnauthorizedStuff
    end

    class Nothing < GraphQL::Schema::Directive
      locations(FIELD)
      def self.visible?(ctx)
        !!ctx[:show_nothing_directive]
      end
    end

    class Schema < GraphQL::Schema
      query(Query)
      mutation(Mutation)
      directive(Nothing)
      use GraphQL::Schema::Warden if ADD_WARDEN
      lazy_resolve(Box, :value)

      def self.unauthorized_object(err)
        if err.object.respond_to?(:replacement)
          err.object.replacement
        elsif err.object == :replace
          33
        elsif err.object == :raise_from_object
          raise GraphQL::ExecutionError, err.message
        else
          raise GraphQL::ExecutionError, "Unauthorized #{err.type.graphql_name}: #{err.object.inspect}"
        end
      end
    end

    class SchemaWithFieldHook < GraphQL::Schema
      query(Query)
      use GraphQL::Schema::Warden if ADD_WARDEN
      lazy_resolve(Box, :value)

      def self.unauthorized_field(err)
        if err.object == :replace
          42
        elsif err.object == :raise
          raise GraphQL::ExecutionError, "#{err.message} in field #{err.field.graphql_name}"
        else
          raise GraphQL::ExecutionError, "Unauthorized field #{err.field.graphql_name} on #{err.type.graphql_name}: #{err.object}"
        end
      end
    end
  end

  def auth_execute(*args, **kwargs)
    AuthTest::Schema.execute(*args, **kwargs)
  end

  describe "applying the visible? method" do
    it "works in queries" do
      res = auth_execute(" { int int2 } ", context: { hide: true })
      assert_equal 1, res["errors"].size
    end

    it "applies return type visibility to fields" do
      error_queries = {
        "hiddenObject" => "{ hiddenObject { __typename } }",
        "hiddenInterface" => "{ hiddenInterface { __typename } }",
        "hiddenDefaultInterface" => "{ hiddenDefaultInterface { __typename } }",
      }

      error_queries.each do |name, q|
        hidden_res = auth_execute(q, context: { hide: true})
        assert_equal ["Field '#{name}' doesn't exist on type 'Query'#{name == "hiddenDefaultInterface" ?  "" : " (Did you mean `hiddenConnection`?)"}"], hidden_res["errors"].map { |e| e["message"] }

        visible_res = auth_execute(q)
        # Both fields exist; the interface resolves to the object type, though
        assert_equal "HiddenObject", visible_res["data"][name]["__typename"]
      end
    end

    it "uses the mutation for derived fields, inputs and outputs" do
      query = "mutation { doHiddenStuff(input: {}) { __typename } }"
      res = auth_execute(query, context: { hidden_mutation: true })
      assert_equal ["Field 'doHiddenStuff' doesn't exist on type 'Mutation'"], res["errors"].map { |e| e["message"] }

      # `#resolve` isn't implemented, so this errors out:
      assert_raises GraphQL::RequiredImplementationMissingError do
        auth_execute(query)
      end

      introspection_q = <<-GRAPHQL
        {
          t1: __type(name: "DoHiddenStuffInput") { name }
          t2: __type(name: "DoHiddenStuffPayload") { name }
        }
      GRAPHQL
      hidden_introspection_res = auth_execute(introspection_q, context: { hidden_mutation: true })
      assert_nil hidden_introspection_res["data"]["t1"]
      assert_nil hidden_introspection_res["data"]["t2"]

      visible_introspection_res = auth_execute(introspection_q)
      assert_equal "DoHiddenStuffInput", visible_introspection_res["data"]["t1"]["name"]
      assert_equal "DoHiddenStuffPayload", visible_introspection_res["data"]["t2"]["name"]
    end

    it "works with Schema::Mutation" do
      query = "mutation { doHiddenStuff2 { __typename } }"
      res = auth_execute(query, context: { hidden_mutation: true })
      assert_equal ["Field 'doHiddenStuff2' doesn't exist on type 'Mutation'"], res["errors"].map { |e| e["message"] }

      # `#resolve` isn't implemented, so this errors out:
      assert_raises GraphQL::RequiredImplementationMissingError do
        auth_execute(query)
      end
    end

    it "uses the base type for edges and connections" do
      query = <<-GRAPHQL
      {
        hiddenConnection { __typename }
        hiddenEdge { __typename }
      }
      GRAPHQL

      hidden_res = auth_execute(query, context: { hidden_relay: true })
      assert_equal 2, hidden_res["errors"].size

      visible_res = auth_execute(query)
      assert_equal "RelayObjectConnection", visible_res["data"]["hiddenConnection"]["__typename"]
      assert_equal "RelayObjectEdge", visible_res["data"]["hiddenEdge"]["__typename"]
    end

    it "treats hidden enum values as non-existent, even in lists" do
      hidden_res_1 = auth_execute <<-GRAPHQL, context: { hide: true }
      {
        landscapeFeature(enum: TAR_PIT)
      }
      GRAPHQL

      assert_equal ["Argument 'enum' on Field 'landscapeFeature' has an invalid value (TAR_PIT). Expected type 'LandscapeFeature'."], hidden_res_1["errors"].map { |e| e["message"] }

      hidden_res_2 = auth_execute <<-GRAPHQL, context: { hide: true }
      {
        landscapeFeatures(enums: [STREAM, TAR_PIT])
      }
      GRAPHQL

      assert_equal ["Argument 'enums' on Field 'landscapeFeatures' has an invalid value ([STREAM, TAR_PIT]). Expected type '[LandscapeFeature!]'."], hidden_res_2["errors"].map { |e| e["message"] }

      success_res = auth_execute <<-GRAPHQL, context: { hide: false, authorized: true }
      {
        landscapeFeature(enum: TAR_PIT)
        landscapeFeatures(enums: [STREAM, TAR_PIT])
      }
      GRAPHQL

      assert_equal "TAR_PIT", success_res["data"]["landscapeFeature"]
      assert_equal ["STREAM", "TAR_PIT"], success_res["data"]["landscapeFeatures"]
    end

    it "refuses to resolve to hidden enum values" do
      expected_class = AuthTest::LandscapeFeature::UnresolvedValueError
      assert_raises(expected_class) do
        auth_execute <<-GRAPHQL, context: { hide: true }
        {
          landscapeFeature(string: "TAR_PIT")
        }
        GRAPHQL
      end

      assert_raises(expected_class) do
        auth_execute <<-GRAPHQL, context: { hide: true }
        {
          landscapeFeatures(strings: ["STREAM", "TAR_PIT"])
        }
        GRAPHQL
      end
    end

    it "rejects incoming unauthorized enum values" do
      res = auth_execute <<-GRAPHQL, context: { }
        {
          landscapeFeature(enum: STREAM)
        }
      GRAPHQL

      assert_equal ["Unauthorized LandscapeFeature: \"STREAM\""], res["errors"].map { |e| e["message"] }
    end

    it "rejects outgoing unauthorized enum values" do
      err = assert_raises(AuthTest::LandscapeFeature::UnresolvedValueError) do
        auth_execute <<-GRAPHQL, context: { }
          {
            landscapeFeature(string: "STREAM")
          }
        GRAPHQL
      end

      assert_equal "`Query.landscapeFeature` returned `\"STREAM\"` at `landscapeFeature`, but this value was unauthorized. Update the field or resolver to return a different value in this case (or return `nil`).", err.message
    end

    it "works in introspection" do
      res = auth_execute <<-GRAPHQL, context: { hide: true, hidden_mutation: true }
        {
          query: __type(name: "Query") {
            fields {
              name
              args { name }
            }
          }

          hiddenObject: __type(name: "HiddenObject") { name }
          hiddenInterface: __type(name: "HiddenInterface") { name }
          landscapeFeatures: __type(name: "LandscapeFeature") { enumValues { name } }
        }
      GRAPHQL
      query_field_names = res["data"]["query"]["fields"].map { |f| f["name"] }
      refute_includes query_field_names, "int"
      int2_arg_names = res["data"]["query"]["fields"].find { |f| f["name"] == "int2" }["args"].map { |a| a["name"] }
      assert_equal ["int", "unauthorized"], int2_arg_names

      assert_nil res["data"]["hiddenObject"]
      assert_nil res["data"]["hiddenInterface"]

      visible_landscape_features = res["data"]["landscapeFeatures"]["enumValues"].map { |v| v["name"] }
      assert_equal ["MOUNTAIN", "STREAM", "FIELD"], visible_landscape_features
    end

    it "works when printing the SDL" do
      full_sdl_lines = AuthTest::Schema.to_definition.split("\n")
      restricted_sdl_lines = AuthTest::Schema.to_definition(context: { hide: true, hidden_mutation: true, hidden_relay: true }).split("\n")
      expected_hidden_lines = [
        "Autogenerated return type of DoHiddenStuff2.",
        "type DoHiddenStuff2Payload {",
        "Autogenerated input type of DoHiddenStuff",
        "input DoHiddenStuffInput {",
        "Autogenerated return type of DoHiddenStuff.",
        "type DoHiddenStuffPayload {",
        "interface HiddenDefaultInterface",
        "interface HiddenInterface",
        "type HiddenObject implements HiddenDefaultInterface & HiddenInterface {",
        "  doHiddenStuff(",
        "    Parameters for DoHiddenStuff",
        "    input: DoHiddenStuffInput!",
        "  ): DoHiddenStuffPayload",
        "  doHiddenStuff2: DoHiddenStuff2Payload",
        "  hidden: Int!",
        "  hiddenConnection(",
        "  hiddenDefaultInterface: HiddenDefaultInterface!",
        "  hiddenEdge: RelayObjectEdge",
        "  hiddenInterface: HiddenInterface!",
        "  hiddenObject: HiddenObject!",
        "  int2(hidden: Int, int: Int, unauthorized: Int): Int"
      ]
      assert_equal expected_hidden_lines, full_sdl_lines.select { |l| l.include?("Hidden") || l.include?("hidden") }
      assert_equal [], restricted_sdl_lines.select { |l| l.include?("Hidden") || l.include?("hidden") }
    end

    it "works with directives" do
      query_str = "{ __typename @nothing }"
      visible_response = auth_execute(query_str, context: { show_nothing_directive: true })
      assert_equal "Query", visible_response["data"]["__typename"]
      hidden_response = auth_execute(query_str)
      assert_equal ["Directive @nothing is not defined"], hidden_response["errors"].map { |e| e["message"] }
    end
  end

  describe "applying the authorized? method" do
    it "halts on unauthorized objects, replacing the object with nil" do
      query = "{ unauthorizedObject { __typename } }"
      hidden_response = auth_execute(query, context: { hide: true })
      assert_nil hidden_response["data"].fetch("unauthorizedObject")
      visible_response = auth_execute(query, context: {})
      assert_equal({ "__typename" => "UnauthorizedObject" }, visible_response["data"]["unauthorizedObject"])
    end

    it "halts on unauthorized mutations" do
      query = "mutation { doUnauthorizedStuff(input: {}) { __typename } }"
      res = auth_execute(query, context: { unauthorized_mutation: true })
      assert_nil res["data"].fetch("doUnauthorizedStuff")
      assert_raises GraphQL::RequiredImplementationMissingError do
        auth_execute(query)
      end
    end

    describe "field level authorization" do
      describe "unauthorized field" do
        describe "with an unauthorized field hook configured" do
          describe "when the hook returns a value" do
            it "replaces the response with the return value of the unauthorized field hook" do
              query = "{ unauthorized }"
              response = AuthTest::SchemaWithFieldHook.execute(query, root_value: :replace)
              assert_equal 42, response["data"].fetch("unauthorized")
            end
          end

          describe "when the field hook raises an error" do
            it "returns nil" do
              query = "{ unauthorized }"
              response = AuthTest::SchemaWithFieldHook.execute(query, root_value: :hide)
              assert_nil response["data"].fetch("unauthorized")
            end

            it "adds the error to the errors key" do
              query = "{ unauthorized }"
              response = AuthTest::SchemaWithFieldHook.execute(query, root_value: :hide)
              assert_equal ["Unauthorized field unauthorized on Query: hide"], response["errors"].map { |e| e["message"] }
            end
          end


          describe "when the field authorization resolves lazily" do
            it "returns value if authorized" do
              query = "{ unauthorized }"
              response = AuthTest::SchemaWithFieldHook.execute(query, root_value: 34, context: { lazy_field_authorized: true })
              assert_equal 34, response["data"].fetch("unauthorized")
            end

            it "returns nil if not authorized" do
              query = "{ unauthorized }"
              response = AuthTest::SchemaWithFieldHook.execute(query, root_value: 34, context: { lazy_field_authorized: false })
              assert_nil response["data"].fetch("unauthorized")
              assert_equal ["Unauthorized field unauthorized on Query: 34"], response["errors"].map { |e| e["message"] }
            end
          end

          describe "when the field authorization raises an UnauthorizedFieldError" do
            it "receives the raised error" do
              query = "{ unauthorized }"
              response = AuthTest::SchemaWithFieldHook.execute(query, root_value: :raise)
              assert_equal ["raised authorized field error in field unauthorized"], response["errors"].map { |e| e["message"] }
            end
          end
        end

        describe "with an unauthorized field hook not configured" do
          describe "When the object hook replaces the field" do
            it "delegates to the unauthorized object hook, which replaces the object" do
              query = "{ unauthorized }"
              response = AuthTest::Schema.execute(query, root_value: :replace)
              assert_equal 33, response["data"].fetch("unauthorized")
            end
          end
          describe "When the object hook raises an error" do
            it "returns nil" do
              query = "{ unauthorized }"
              response = AuthTest::Schema.execute(query, root_value: :hide)
              assert_nil response["data"].fetch("unauthorized")
            end

            it "adds the error to the errors key" do
              query = "{ unauthorized }"
              response = AuthTest::Schema.execute(query, root_value: :hide)
              assert_equal ["Unauthorized Query: :hide"], response["errors"].map { |e| e["message"] }
            end
          end
        end
      end

      describe "authorized field" do
        it "returns the field data" do
          query = "{ unauthorized }"
          response = AuthTest::SchemaWithFieldHook.execute(query, root_value: 1)
          assert_equal 1, response["data"].fetch("unauthorized")
        end
      end
    end

    it "halts on unauthorized fields, using the parent object" do
      query = "{ unauthorized }"
      hidden_response = auth_execute(query, root_value: :hide)
      assert_nil hidden_response["data"].fetch("unauthorized")
      visible_response = auth_execute(query, root_value: 1)
      assert_equal 1, visible_response["data"]["unauthorized"]
    end

    it "halts on unauthorized arguments, using the parent object" do
      query = "{ int2(unauthorized: 5) }"
      hidden_response = auth_execute(query, root_value: :hide2)
      assert_nil hidden_response["data"].fetch("int2")
      visible_response = auth_execute(query)
      assert_equal 5, visible_response["data"]["int2"]
    end

    it "works with edges and connections" do
      query = <<-GRAPHQL
      {
        unauthorizedConnection {
          __typename
          edges {
            __typename
            node {
              __typename
            }
          }
          nodes {
            __typename
          }
        }
        unauthorizedEdge {
          __typename
          node {
            __typename
          }
        }
      }
      GRAPHQL

      unauthorized_res = auth_execute(query, context: { unauthorized_relay: true })
      conn = unauthorized_res["data"].fetch("unauthorizedConnection")
      assert_equal "RelayObjectConnection", conn.fetch("__typename")
      # This is tricky: the previous behavior was to replace the _whole_
      # list with `nil`. This was due to an implementation detail:
      # The list field's return value (an array of integers) was wrapped
      # _before_ returning, and during this wrapping, a cascading error
      # caused the entire field to be nilled out.
      #
      # In the interpreter, each list item is contained and the error doesn't propagate
      # up to the whole list.
      #
      # Originally, I thought that this was a _feature_ that obscured list entries.
      # But really, look at the test below: you don't get this "feature" if
      # you use `edges { node }`, so it can't be relied on in any way.
      #
      # All that to say, in the interpreter, `nodes` and `edges { node }` behave
      # the same.
      #
      # TODO revisit the docs for this.
      failed_nodes_value = [nil]
      assert_equal failed_nodes_value, conn.fetch("nodes")
      assert_equal [{"node" => nil, "__typename" => "RelayObjectEdge"}], conn.fetch("edges")

      edge = unauthorized_res["data"].fetch("unauthorizedEdge")
      assert_nil edge.fetch("node")
      assert_equal "RelayObjectEdge", edge["__typename"]

      unauthorized_object_paths = [
        ["unauthorizedConnection", "edges", 0, "node"],
        ["unauthorizedConnection", "nodes", 0],
        ["unauthorizedEdge", "node"]
      ]

      assert_equal unauthorized_object_paths, unauthorized_res["errors"].map { |e| e["path"] }

      authorized_res = auth_execute(query)
      conn = authorized_res["data"].fetch("unauthorizedConnection")
      assert_equal "RelayObjectConnection", conn.fetch("__typename")
      assert_equal [{"__typename"=>"RelayObject"}], conn.fetch("nodes")
      assert_equal [{"node" => {"__typename" => "RelayObject"}, "__typename" => "RelayObjectEdge"}], conn.fetch("edges")

      edge = authorized_res["data"].fetch("unauthorizedEdge")
      assert_equal "RelayObject", edge.fetch("node").fetch("__typename")
      assert_equal "RelayObjectEdge", edge["__typename"]
    end

    it "authorizes _after_ resolving lazy objects" do
      query = <<-GRAPHQL
      {
        a: unauthorizedLazyBox(value: "a") { value }
        b: unauthorizedLazyBox(value: "b") { value }
      }
      GRAPHQL

      unauthorized_res = auth_execute(query)
      assert_nil unauthorized_res["data"].fetch("a")
      assert_equal "b", unauthorized_res["data"]["b"]["value"]
    end

    it "authorizes items in a list" do
      query = <<-GRAPHQL
      {
        unauthorizedListItems { __typename }
      }
      GRAPHQL

      unauthorized_res = auth_execute(query, context: { hide: true })

      assert_nil unauthorized_res["data"]["unauthorizedListItems"]
      authorized_res = auth_execute(query, context: { hide: false })
      assert_equal 2, authorized_res["data"]["unauthorizedListItems"].size
    end

    it "syncs lazy objects from authorized? checks" do
      query = <<-GRAPHQL
      {
        a: unauthorizedLazyCheckBox(value: "a") { value }
        b: unauthorizedLazyCheckBox(value: "b") { value }
      }
      GRAPHQL

      unauthorized_res = auth_execute(query)
      assert_nil unauthorized_res["data"].fetch("a")
      assert_equal "b", unauthorized_res["data"]["b"]["value"]
      # Also, the custom handler was called:
      assert_equal ["Unauthorized UnauthorizedCheckBox: \"a\""], unauthorized_res["errors"].map { |e| e["message"] }
    end

    it "Works for lazy connections" do
      query = <<-GRAPHQL
      {
        lazyIntegers { edges { node { value } } }
      }
      GRAPHQL
      res = auth_execute(query)
      assert_equal [1,2,3], res["data"]["lazyIntegers"]["edges"].map { |e| e["node"]["value"] }
    end

    it "Works for eager connections" do
      query = <<-GRAPHQL
      {
        integers { edges { node { value } } }
      }
      GRAPHQL
      res = auth_execute(query)
      assert_equal [1,2,3], res["data"]["integers"]["edges"].map { |e| e["node"]["value"] }
    end

    it "filters out individual nodes by value" do
      query = <<-GRAPHQL
      {
        integers { edges { node { value } } }
      }
      GRAPHQL
      res = auth_execute(query, context: { exclude_integer: 1 })
      assert_equal [nil,2,3], res["data"]["integers"]["edges"].map { |e| e["node"] && e["node"]["value"] }
      assert_equal ["Unauthorized IntegerObject: 1"], res["errors"].map { |e| e["message"] }
    end

    it "works with lazy values / interfaces" do
      query = <<-GRAPHQL
      query($value: String!){
        unauthorizedInterface(value: $value) {
          ... on UnauthorizedCheckBox {
            value
          }
        }
      }
      GRAPHQL

      res = auth_execute(query, variables: { value: "a"})
      assert_nil res["data"]["unauthorizedInterface"]

      res2 = auth_execute(query, variables: { value: "b"})
      assert_equal "b", res2["data"]["unauthorizedInterface"]["value"]
    end

    it "works with lazy values / lists of interfaces" do
      query = <<-GRAPHQL
      {
        unauthorizedLazyListInterface {
          ... on UnauthorizedCheckBox {
            value
          }
        }
      }
      GRAPHQL

      res = auth_execute(query)
      # An error from two, values from the others
      assert_equal ["Unauthorized UnauthorizedCheckBox: \"a\"", "Unauthorized UnauthorizedCheckBox: \"a\""], res["errors"].map { |e| e["message"] }
      assert_equal [{"value" => "z"}, {"value" => "z2"}, nil, nil], res["data"]["unauthorizedLazyListInterface"]
    end

    describe "with an unauthorized field hook configured" do
      it "replaces objects from the unauthorized_object hook" do
        query = "{ replacedObject { replaced } }"
        res = auth_execute(query, context: { replace_me: true })
        assert_equal true, res["data"]["replacedObject"]["replaced"]

        res = auth_execute(query, context: { replace_me: false })
        assert_equal false, res["data"]["replacedObject"]["replaced"]
      end

      it "works when the query hook returns false and there's no root object" do
        query = "{ __typename }"
        res = auth_execute(query)
        assert_equal "Query", res["data"]["__typename"]

        unauth_res = auth_execute(query, context: { query_unauthorized: true })
        assert_nil unauth_res["data"]
        assert_equal [{"message"=>"Unauthorized Query: nil"}], unauth_res["errors"]
      end

      describe "when the object authorization raises an UnauthorizedFieldError" do
        it "receives the raised error" do
          query = "{ unauthorizedObject { value } }"
          response = auth_execute(query, context: { raise: true }, root_value: :raise_from_object)
          assert_equal ["raised authorized object error"], response["errors"].map { |e| e["message"] }
        end
      end
    end
  end

  describe "returning false" do
    class FalseSchema < GraphQL::Schema
      class Query < GraphQL::Schema::Object
        def self.authorized?(obj, ctx)
          false
        end

        field :int, Integer, null: false

        def int
          1
        end
      end
      query(Query)
    end

    it "works out-of-the-box" do
      res = FalseSchema.execute("{ int }")
      assert_nil res.fetch("data")
      refute res.key?("errors")
    end
  end

  describe "overriding authorized_new" do
    class AuthorizedNewOverrideSchema < GraphQL::Schema
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

      module CustomIntrospection
        class DynamicFields < GraphQL::Introspection::DynamicFields
          def self.authorized_new(obj, ctx)
            new(obj, ctx)
          end
        end
      end

      class Query < GraphQL::Schema::Object
        def self.authorized_new(obj, ctx)
          new(obj, ctx)
        end
        field :int, Integer, null: false
        def int; 1; end
      end

      query(Query)
      introspection(CustomIntrospection)
      trace_with(LogTrace)
    end

    it "avoids calls to Object.authorized?" do
      log = []
      res = AuthorizedNewOverrideSchema.execute("{ __typename int }", context: { log: log })
      assert_equal "Query", res["data"]["__typename"]
      assert_equal 1, res["data"]["int"]
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
end
