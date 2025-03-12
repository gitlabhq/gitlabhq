# frozen_string_literal: true
require "spec_helper"

describe "Dynamic types, fields, arguments, and enum values" do
  class MultifieldSchema < GraphQL::Schema
    use GraphQL::Schema::Warden if ADD_WARDEN
    module AppliesToFutureSchema
      def initialize(*args, future_schema: nil, **kwargs, &block)
        @future_schema = future_schema
        super(*args, **kwargs, &block)
      end

      def visible?(context)
        if context[:visible_calls] && !context[:visibility_migration_warden_running]
          context[:visible_calls][self] << caller
        end
        super && (@future_schema.nil? || (@future_schema == !!context[:future_schema]))
      end

      attr_accessor :future_schema

      class MethodInspection
        def initialize(method)
          @method = method
        end

        def path
          "#{@method.owner}#{@method.receiver.is_a?(Class) ? "." : "#"}#{@method.name} @ #{@method.source_location.inspect}"
        end
      end

      # Make sure these methods are only called once at runtime:
      [:fields, :get_field, :arguments, :get_argument, :enum_values, :interfaces, :possible_types].each do |dynamic_members_method_name|
        if RUBY_VERSION > "3"
          define_method(dynamic_members_method_name) do |*args, **kwargs, &block|
            context = args.last
            if context && (context.is_a?(Hash) || context.is_a?(GraphQL::Query::Context)) && context[:visible_calls] && !context[:visibility_migration_warden_running]
              method_obj = self.method(dynamic_members_method_name)
              context[:visible_calls][MethodInspection.new(method_obj)] << caller
            end
            super(*args, **kwargs, &block)
          end
        else
          define_method(dynamic_members_method_name) do |*args, &block|
            context = args.last
            if context && (context.is_a?(Hash) || context.is_a?(GraphQL::Query::Context)) && context[:visible_calls] && !context[:visibility_migration_warden_running]
              method_obj = self.method(dynamic_members_method_name)
              context[:visible_calls][MethodInspection.new(method_obj)] << caller
            end
            super(*args, &block)
          end
        end
      end
    end

    class BaseArgument < GraphQL::Schema::Argument
      include AppliesToFutureSchema
    end

    class BaseField < GraphQL::Schema::Field
      include AppliesToFutureSchema
      argument_class BaseArgument
    end

    class BaseObject < GraphQL::Schema::Object
      field_class BaseField
      extend AppliesToFutureSchema
    end

    module BaseInterface
      include GraphQL::Schema::Interface
      class TypeMembership < GraphQL::Schema::TypeMembership
        include AppliesToFutureSchema
      end

      field_class BaseField
      type_membership_class TypeMembership
      definition_methods do
        include AppliesToFutureSchema
      end
    end

    class BaseUnion < GraphQL::Schema::Union
      extend AppliesToFutureSchema
      type_membership_class BaseInterface::TypeMembership
    end

    class BaseScalar < GraphQL::Schema::Scalar
      extend AppliesToFutureSchema
    end

    class BaseInputObject < GraphQL::Schema::InputObject
      extend AppliesToFutureSchema
      argument_class BaseArgument
    end

    class BaseEnumValue < GraphQL::Schema::EnumValue
      include AppliesToFutureSchema
    end

    class BaseEnum < GraphQL::Schema::Enum
      enum_value_class BaseEnumValue
    end

    module Node
      include BaseInterface

      field :id, Int, null: false, future_schema: true, deprecation_reason: "Use databaseId instead"
      field :id, Int, null: false, future_schema: false

      field :database_id, Int, null: false, future_schema: true
      field :uuid, ID, null: false, future_schema: true
    end

    class MoneyScalar < BaseScalar
      graphql_name "Money"

      self.future_schema = false
    end

    class LegacyMoney < MoneyScalar
      graphql_name "LegacyMoney"
    end

    module HasCurrency
      include BaseInterface
      field :currency, String, null: false
      self.future_schema = true
    end

    class Money < BaseObject
      implements HasCurrency
      field :amount, Integer, null: false
      field :currency, String, null: false, description: "The denomination of this amount of money"

      self.future_schema = true
    end

    class LegacyScream < BaseScalar
      graphql_name "Scream"
      description "An all-uppercase saying"
      def self.coerce_input(value, ctx)
        if value.upcase != value
          raise GraphQL::CoercionError, "scream must be SCREAMING"
        end
        value
      end

      self.future_schema = false
    end

    class Scream < BaseScalar
      description "A saying ending with at least four exclamation points"
      def self.coerce_input(value, ctx)
        if !value.end_with?("!!!!")
          raise GraphQL::CoercionError, "scream must be screaming!!!!"
        end
        value
      end

      self.future_schema = true
    end

    class LegacyThing < BaseObject
      implements Node
      field :price, LegacyMoney
    end

    class Thing < LegacyThing
      # TODO can I get rid of `future_schema: ...` here in a way that
      # still only requires one call to `visible?` at runtime?
      field :price, Money, future_schema: true
      field :price, MoneyScalar, method: :legacy_price, future_schema: false
    end

    class Language < BaseEnum
      value "RUBY"
      value "PERL6", deprecation_reason: "Use RAKU instead", future_schema: true
      value "PERL6", future_schema: false
      value "RAKU", future_schema: true
      value "COFFEE_SCRIPT", future_schema: false
    end

    module HasCapital
      include BaseInterface
      field :capital_name, String, null: false
    end

    module HasLanguages
      include BaseInterface
      field :languages, [String], null: false
    end

    class Country < BaseObject
      implements HasCurrency
      implements HasCapital, future_schema: true
      implements HasLanguages, future_schema: true
      implements HasLanguages, future_schema: false
    end

    class Locale < BaseUnion
      possible_types Country, future_schema: true

      if GraphQL::Schema.use_visibility_profile?
        # Profile won't check possible_types, this must be flagged
        self.future_schema = true
      end
    end

    class Place < BaseObject
      implements Node
      self.future_schema = true
      field :future_place_field, String
    end

    class LegacyPlace < BaseObject
      implements Node
      graphql_name "Place"
      self.future_schema = false
      field :legacy_place_field, String
    end

    class Region < BaseUnion
      self.future_schema = true
      possible_types Country, Place, LegacyPlace
    end

    class LegacyBot < BaseObject
      description "Legacy bot"
      graphql_name "Bot"
      field :handle, String, null: false
      field :verified, Boolean, null: false
      self.future_schema = false
    end

    class AbstractNamedThing < BaseObject
      field :name, String, null: false
    end

    class Bot < AbstractNamedThing
      description "Future bot"
      field :name, String, null: false
      field :is_verified, Boolean, null: false
      self.future_schema = true
    end

    class Actor < BaseUnion
      possible_types Bot, LegacyBot


      def self.resolve_type(obj, ctx)
        if ctx[:future_schema]
          Bot
        else
          LegacyBot
        end
      end
    end

    class BaseResolver < GraphQL::Schema::Resolver
      argument_class BaseArgument
    end

    class Add < BaseResolver
      argument :left, Float, future_schema: true
      argument :left, Int, future_schema: false
      argument :right, Float, future_schema: true
      argument :right, Int, future_schema: false

      type String, null: false

      def resolve(left:, right:)
        "#{left + right}"
      end
    end

    class ThingIdInput < BaseInputObject
      argument :id, ID, future_schema: true, loads: Thing, as: :thing
      argument :id, Int, future_schema: false, loads: Thing, as: :thing
    end

    class Query < BaseObject
      field :node, Node do
        argument :id, ID
      end

      field :f1, String, future_schema: true
      field :f1, Int, future_schema: false

      def f1
        if context[:future_schema]
          "abcdef"
        else
          123
        end
      end

      field :thing, Thing do
        argument :input, ThingIdInput
      end

      def thing(input:)
        input[:thing]
      end

      field :legacy_thing, LegacyThing, null: false do
        argument :id, ID
      end

      def legacy_thing(id:)
        { id: id, database_id: id, uuid: "thing-#{id}", price: "⚛︎#{id}00" }
      end

      field :favorite_language, Language, null: false do
        argument :lang, Language, required: false
      end

      def favorite_language(lang: nil)
        lang || context[:favorite_language] || "RUBY"
      end

      field :add, resolver: Add

      field :actor, Actor
      def actor
        { handle: "bot1", verified: false, name: "bot2", is_verified: true }
      end

      field :yell, String, null: false do
        # TODO: can I get rid of the requirement for `future_schema: true` here since `Scream.future_schema` is true?
        argument :scream, Scream, future_schema: true
        argument :scream, LegacyScream, future_schema: false
      end

      def yell(scream:)
        scream
      end

      # just to attach these to the schema:
      field :example_locale, Locale
      field :example_region, Region
      field :example_country, Country
    end

    class BaseMutation < GraphQL::Schema::RelayClassicMutation
      argument_class BaseArgument
      input_object_class BaseInputObject
      field_class BaseField
    end

    class UpdateThing < BaseMutation
      argument :thing_id, ID, future_schema: true
      argument :thing_id, Int, future_schema: false
      argument :price, Int

      field :thing, Thing, null: false, future_schema: true, method: :custom_thing
      field :thing, LegacyThing, null: false, hash_key: :legacy_thing, future_schema: false

      def resolve(thing_id:, price:)
        thing = { id: thing_id, uuid: thing_id, legacy_price: "£#{price}", future_price: { amount: price, currency: "£"} }
        thing[:price] = thing[:future_price]

        legacy_thing = thing.merge(price: thing[:legacy_price])

        {
          custom_thing: thing,
          legacy_thing: legacy_thing,
        }
      end
    end

    class Mutation < BaseObject
      field :update_thing, mutation: UpdateThing
    end

    query(Query)
    mutation(Mutation)
    orphan_types(Place, LegacyPlace, Country)

    def self.object_from_id(id, ctx)
      { id: id, database_id: id, uuid: "thing-#{id}", legacy_price: "⚛︎#{id}00", price: { amount: id.to_i * 100, currency: "⚛︎" }}
    end

    def self.resolve_type(type, obj, ctx)
      Thing
    end
  end

  def check_for_multiple_visible_calls(context)
    if [1] != context[:visible_calls].values.map(&:size).uniq
      ok_visible_calls = []
      not_ok_visible_calls = {}
      context[:visible_calls].each do |object, calls|
        if calls.size == 1
          ok_visible_calls << object.path
        else
          not_ok_visible_calls[object] = calls
        end
      end

      bad_calls_text = "".dup
      not_ok_visible_calls.each do |object, calls|
        bad_calls_text << "- #{object.path}[#{object.object_id}] -> #{calls.size}\n"
        calls_count = Hash.new(0)
        calls.each do |call|
          calls_count[call] += 1
        end
        calls_count.each do |call, count|
          bad_calls_text << "  #{count}x:\n"
          call.each do |line|
            bad_calls_text << "    #{line}\n"
          end
          bad_calls_text << "\n"
        end
        bad_calls_text << "\n\n"
      end

      raise <<-ERR
Should be only one visible call per schema member:

#{bad_calls_text}

OK: #{ok_visible_calls}
ERR
    end
  end

  VISIBLE_CALLS = Hash.new { |h, k| h[k] = [] }

  def exec_query(*args, **kwargs)
    context = kwargs[:context] ||= {}
    context[:visible_calls] = VISIBLE_CALLS.dup
    res = MultifieldSchema.execute(*args, **kwargs)
    check_for_multiple_visible_calls(res.context)
    res
  end

  def exec_future_query(*args, **kwargs)
    context = kwargs[:context] ||= {}
    context[:future_schema] = true
    exec_query(*args, **kwargs)
  end

  def future_schema_sdl
    ctx = { future_schema: true, visible_calls: VISIBLE_CALLS.dup }
    sdl = MultifieldSchema.to_definition(context: ctx)
    check_for_multiple_visible_calls(ctx)
    sdl
  end

  def legacy_schema_sdl
    ctx = { visible_calls: VISIBLE_CALLS.dup }
    sdl = MultifieldSchema.to_definition(context: ctx)
    check_for_multiple_visible_calls(ctx)
    sdl
  end

  it "returns different fields according context for Ruby methods, runtime, introspection, and to_definition" do
    # Accessing in Ruby
    assert_equal GraphQL::Types::Int, MultifieldSchema::Query.get_field("f1", { future_schema: nil }).type
    assert_equal GraphQL::Types::Int, MultifieldSchema::Query.get_field("f1", { future_schema: false }).type
    assert_equal GraphQL::Types::String, MultifieldSchema::Query.get_field("f1", { future_schema: true }).type
    assert_equal GraphQL::Types::Int, MultifieldSchema.get_field("Query", "f1", { future_schema: false }).type
    assert_equal GraphQL::Types::String, MultifieldSchema.get_field("Query", "f1", { future_schema: true }).type
    err = assert_raises GraphQL::Schema::DuplicateNamesError do
      MultifieldSchema::Query.get_field("f1")
    end
    assert_equal "Query.f1", err.duplicated_name

    expected_message = "Found two visible definitions for `Query.f1`: #<MultifieldSchema::BaseField Query.f1: String>, #<MultifieldSchema::BaseField Query.f1: Int>"
    assert_equal expected_message, err.message

    # GraphQL usage
    query_str = "{ f1 }"
    assert_equal 123, exec_query(query_str)["data"]["f1"]
    assert_equal "abcdef", exec_future_query(query_str)["data"]["f1"]

    # GraphQL Introspection
    introspection_query_str = '{ __type(name: "Query") { fields { name type { name } } } }'
    assert_equal "Int", exec_query(introspection_query_str)["data"]["__type"]["fields"].find { |f| f["name"] == "f1" }["type"]["name"]
    assert_equal "String", exec_future_query(introspection_query_str)["data"]["__type"]["fields"].find { |f| f["name"] == "f1" }["type"]["name"]

    # Schema dump
    legacy_query_type_str = legacy_schema_sdl[/type Query \{[^}]*\}/m]
    expected_legacy_query_type_str = <<-GRAPHQL.chomp
type Query {
  actor: Actor
  add(left: Int!, right: Int!): String!
  exampleCountry: Country
  f1: Int
  favoriteLanguage(lang: Language): Language!
  legacyThing(id: ID!): LegacyThing!
  node(id: ID!): Node
  thing(input: ThingIdInput!): Thing
  yell(scream: Scream!): String!
}
GRAPHQL
    assert_equal expected_legacy_query_type_str, legacy_query_type_str

    assert_includes future_schema_sdl, <<-GRAPHQL
type Query {
  actor: Actor
  add(left: Float!, right: Float!): String!
  exampleCountry: Country
  exampleLocale: Locale
  exampleRegion: Region
  f1: String
  favoriteLanguage(lang: Language): Language!
  legacyThing(id: ID!): LegacyThing!
  node(id: ID!): Node
  thing(input: ThingIdInput!): Thing
  yell(scream: Scream!): String!
}
GRAPHQL
  end

  it "serves interface fields according to the per-query version" do
    # Schema dump
    assert_includes legacy_schema_sdl, <<-GRAPHQL
interface Node {
  id: Int!
}
GRAPHQL

    assert_includes future_schema_sdl, <<-GRAPHQL
interface Node {
  databaseId: Int!
  id: Int! @deprecated(reason: "Use databaseId instead")
  uuid: ID!
}
GRAPHQL

    query_str = "{ thing(input: { id: 15 }) { databaseId id uuid } }"
    assert_equal ["Field 'databaseId' doesn't exist on type 'Thing'", "Field 'uuid' doesn't exist on type 'Thing'"], exec_query(query_str)["errors"].map { |e| e["message"] }
    res = exec_future_query(query_str)
    assert_equal({ "thing" => { "databaseId" => 15, "id" => 15, "uuid" => "thing-15"} }, res["data"])
  end

  it "supports multiple implementations of the same interface" do
    query_str = '{ __type(name: "Country") { interfaces { name } } }'
    assert_equal ["HasLanguages"], exec_query(query_str)["data"]["__type"]["interfaces"].map { |i| i["name"] }
    assert_equal ["HasCapital", "HasCurrency", "HasLanguages"], exec_future_query(query_str)["data"]["__type"]["interfaces"].map { |i| i["name"] }
  end

  it "overrides fields from interfaces instead of multi-defining them" do
    f = MultifieldSchema::Money.get_field("currency")
    assert_equal MultifieldSchema::Money, f.owner
    assert_equal "The denomination of this amount of money", f.description
  end

  it "supports different versions of field arguments" do
    res = exec_future_query("{ thing(input: { id: \"15\" }) { id } }")
    assert_equal 15, res["data"]["thing"]["id"]
    # On legacy, `"15"` is parsed as an int, which makes it null:
    res = exec_query("{ thing(input: { id: \"15\" }) { id } }")
    assert_equal ["Argument 'id' on InputObject 'ThingIdInput' has an invalid value (\"15\"). Expected type 'Int!'."], res["errors"].map { |e| e["message"] }

    introspection_query = "{ __type(name: \"ThingIdInput\") { inputFields { name type { name ofType { name } } } } }"
    introspection_res = exec_query(introspection_query)
    assert_equal "Int", introspection_res["data"]["__type"]["inputFields"].find { |f| f["name"] == "id" }["type"]["ofType"]["name"]

    introspection_res = exec_future_query(introspection_query)
    assert_equal "ID", introspection_res["data"]["__type"]["inputFields"].find { |f| f["name"] == "id" }["type"]["ofType"]["name"]
  end

  it "hides fields from hidden interfaces" do
    # in this case, the whole interface is hidden
    assert MultifieldSchema::HasCurrency.visible?({ future_schema: true })
    refute MultifieldSchema::HasCurrency.visible?({ future_schema: false })

    refute MultifieldSchema::Country.fields({ future_schema: false }).key?("currency")
    assert MultifieldSchema::Country.fields({ future_schema: true }).key?("currency")
    assert_nil MultifieldSchema::Country.get_field("currency", { future_schema: false })
    refute_nil MultifieldSchema::Country.get_field("currency", { future_schema: true })

    refute_includes MultifieldSchema::Country.interfaces({ future_schema: false }), MultifieldSchema::HasCurrency
    assert_includes MultifieldSchema::Country.interfaces({ future_schema: true }), MultifieldSchema::HasCurrency
    assert_includes MultifieldSchema::Country.interfaces, MultifieldSchema::HasCurrency
  end

  it "hides hidden interface implementations" do
    # in this case, the interface is always visible:
    assert MultifieldSchema::HasCapital.visible?({ future_schema: true })
    assert MultifieldSchema::HasCapital.visible?({ future_schema: false })

    # but the field is sometimes hidden:
    refute_includes MultifieldSchema::Country.fields({ future_schema: false }), "capitalName"
    assert_includes MultifieldSchema::Country.fields({ future_schema: true }), "capitalName"

    assert_nil MultifieldSchema::Country.get_field("capitalName", { future_schema: false })
    refute_nil MultifieldSchema::Country.get_field("capitalName", { future_schema: true })

    # and the interface relationship is sometimes hidden:
    refute_includes MultifieldSchema::Country.interfaces({ future_schema: false }), MultifieldSchema::HasCapital
    refute_includes MultifieldSchema.possible_types(MultifieldSchema::HasCapital, { future_schema: false }), MultifieldSchema::Country
    assert_includes MultifieldSchema::Country.interfaces({ future_schema: true }), MultifieldSchema::HasCapital
    assert_includes MultifieldSchema.possible_types(MultifieldSchema::HasCapital, { future_schema: true }), MultifieldSchema::Country
    assert_includes MultifieldSchema::Country.interfaces, MultifieldSchema::HasCapital
    if GraphQL::Schema.use_visibility_profile?
      # filtered with `future_schema: nil`
      refute_includes MultifieldSchema.possible_types(MultifieldSchema::HasCapital), MultifieldSchema::Country
    else
      assert_includes MultifieldSchema.possible_types(MultifieldSchema::HasCapital), MultifieldSchema::Country
    end
  end

  it "hides hidden union memberships" do
    assert MultifieldSchema::Locale.visible?({ future_schema: true })
    if GraphQL::Schema.use_visibility_profile?
      refute MultifieldSchema::Locale.visible?({ future_schema: false })
    else
      # Warden will check possible types -- but Profile doesn't
      assert MultifieldSchema::Locale.visible?({ future_schema: false })
    end

    # and the possible types relationship is sometimes hidden:
    refute_includes MultifieldSchema.possible_types(MultifieldSchema::Locale, { future_schema: false }), MultifieldSchema::Country
    assert_includes MultifieldSchema.possible_types(MultifieldSchema::Locale, { future_schema: true }), MultifieldSchema::Country
    if GraphQL::Schema.use_visibility_profile?
      # This type is hidden in this case
      assert_equal [], MultifieldSchema.possible_types(MultifieldSchema::Locale)
    else
      assert_includes MultifieldSchema.possible_types(MultifieldSchema::Locale), MultifieldSchema::Country
    end
  end

  it "hides hidden unions" do
    # in this case, the union is only sometimes visible:
    assert MultifieldSchema::Region.visible?({ future_schema: true })
    refute MultifieldSchema::Region.visible?({ future_schema: false })

    # and the possible types relationship is sometimes hidden:
    assert_equal [], MultifieldSchema.possible_types(MultifieldSchema::Region, { future_schema: false })
    assert_equal [MultifieldSchema::Country, MultifieldSchema::Place], MultifieldSchema.possible_types(MultifieldSchema::Region, { future_schema: true })
    if GraphQL::Schema.use_visibility_profile?
      # Filtered like `future_schema: false`
      assert_equal [MultifieldSchema::Country, MultifieldSchema::LegacyPlace], MultifieldSchema.possible_types(MultifieldSchema::Region)
    else
      assert_equal [MultifieldSchema::Country, MultifieldSchema::Place, MultifieldSchema::LegacyPlace], MultifieldSchema.possible_types(MultifieldSchema::Region)
    end
  end

  it "supports different versions of input object arguments" do
    res = exec_query("mutation { updateThing(input: { thingId: 12, price: 100 }) { thing { price id } } }")
    assert_equal "£100", res["data"]["updateThing"]["thing"]["price"]
    assert_equal 12, res["data"]["updateThing"]["thing"]["id"]

    res = exec_future_query("mutation { updateThing(input: { thingId: \"11\", price: 120 }) { thing { uuid price { amount } } } }")
    assert_equal "11", res["data"]["updateThing"]["thing"]["uuid"]
    assert_equal 120, res["data"]["updateThing"]["thing"]["price"]["amount"]

    introspection_query_str = "{ __type(name: \"UpdateThingInput\") { inputFields { name type { name ofType { name } } } } }"
    res = exec_query(introspection_query_str)
    assert_equal "Int", res["data"]["__type"]["inputFields"].find { |f| f["name"] == "thingId" }["type"]["ofType"]["name"]
    res = exec_future_query(introspection_query_str)
    assert_equal "ID", res["data"]["__type"]["inputFields"].find { |f| f["name"] == "thingId" }["type"]["ofType"]["name"]

    introspection_query_str = "{ __type(name: \"UpdateThingPayload\") { fields { name type { name ofType { name } } } } }"
    res = exec_query(introspection_query_str)
    assert_equal "LegacyThing", res["data"]["__type"]["fields"].find { |f| f["name"] == "thing" }["type"]["ofType"]["name"]
    res = exec_future_query(introspection_query_str)
    assert_equal "Thing", res["data"]["__type"]["fields"].find { |f| f["name"] == "thing" }["type"]["ofType"]["name"]

    update_thing_payload_sdl = <<-GRAPHQL
type UpdateThingPayload {
  """
  A unique identifier for the client performing the mutation.
  """
  clientMutationId: String
  thing: %{typename}!
}
GRAPHQL

    assert_includes legacy_schema_sdl, update_thing_payload_sdl % { typename: "LegacyThing"}
    assert_includes future_schema_sdl, update_thing_payload_sdl % { typename: "Thing"}
  end

  it "can migrate scalars to objects" do
    # Schema dump
    assert_includes legacy_schema_sdl, "scalar Money"
    refute_includes legacy_schema_sdl, "type Money"

    assert_includes future_schema_sdl, <<-GRAPHQL
type Money implements HasCurrency {
  amount: Int!

  """
  The denomination of this amount of money
  """
  currency: String!
}
GRAPHQL
    refute_includes future_schema_sdl, "scalar Money"

    assert_equal MultifieldSchema::MoneyScalar, MultifieldSchema.get_type("Money", { future_schema: nil })
    assert_equal MultifieldSchema::MoneyScalar, MultifieldSchema.get_type("Money", { future_schema: false })
    assert_equal MultifieldSchema::Money, MultifieldSchema.get_type("Money", { future_schema: true })
    if GraphQL::Schema.use_visibility_profile?
      # Filtered like `future_schema: nil`
      assert_equal MultifieldSchema::MoneyScalar, MultifieldSchema.get_type("Money")
    else
      err = assert_raises GraphQL::Schema::DuplicateNamesError do
        assert_nil MultifieldSchema.get_type("Money")
      end
      assert_equal "Money", err.duplicated_name
      expected_message = "Found two visible definitions for `Money`: MultifieldSchema::Money, MultifieldSchema::MoneyScalar"
      assert_equal expected_message, err.message
    end

    assert_equal "⚛︎100",exec_query("{ thing( input: { id: 1 }) { price } }")["data"]["thing"]["price"]
    res = exec_query("{ __type(name: \"Money\") { kind name } }")
    assert_equal "SCALAR", res["data"]["__type"]["kind"]
    assert_equal "Money", res["data"]["__type"]["name"]
    assert_equal({ "amount" => 200, "currency" => "⚛︎" }, exec_future_query("{ thing(input: { id: 2}) { price { amount currency } } }")["data"]["thing"]["price"])
    res = exec_future_query("{ __type(name: \"Money\") { name kind } }")
    assert_equal "OBJECT", res["data"]["__type"]["kind"]
    assert_equal "Money", res["data"]["__type"]["name"]
  end

  it "works with subclasses" do
    res = exec_query("{ legacyThing(id: 1) { price } thing(input: { id: 3 }) { price } }")
    assert_equal "⚛︎100", res["data"]["legacyThing"]["price"]
    assert_equal "⚛︎300", res["data"]["thing"]["price"]

    future_res = exec_future_query("{ legacyThing(id: 1) { price } thing(input: { id: 3 }) { price { amount } } }")
    assert_equal "⚛︎100", future_res["data"]["legacyThing"]["price"]
    assert_equal 300, future_res["data"]["thing"]["price"]["amount"]
  end


  it "supports different enum value definitions" do
    # Schema dump:
    legacy_schema = legacy_schema_sdl
    assert_includes legacy_schema, "COFFEE_SCRIPT"
    refute_includes legacy_schema, "RAKU"
    future_schema = future_schema_sdl
    assert_includes future_schema, "RAKU\n"
    assert_includes future_schema, "\"Use RAKU instead\""
    refute_includes future_schema, "COFFEE_SCRIPT"

    # Introspection:
    query_str = "{ __type(name: \"Language\") { enumValues(includeDeprecated: true) { name deprecationReason } } }"
    legacy_res = exec_query(query_str)
    assert_equal ["RUBY", "PERL6", "COFFEE_SCRIPT"], legacy_res["data"]["__type"]["enumValues"].map { |v| v["name"] }
    assert_equal [nil, nil, nil], legacy_res["data"]["__type"]["enumValues"].map { |v| v["deprecationReason"] }

    future_res = exec_future_query(query_str)
    assert_equal ["RUBY", "PERL6", "RAKU"], future_res["data"]["__type"]["enumValues"].map { |v| v["name"] }
    assert_equal [nil, "Use RAKU instead", nil], future_res["data"]["__type"]["enumValues"].map { |v| v["deprecationReason"] }

    # Runtime return values and inputs:
    assert_equal "COFFEE_SCRIPT", exec_query("{ favoriteLanguage }", context: { favorite_language: "COFFEE_SCRIPT"})["data"]["favoriteLanguage"]
    assert_raises MultifieldSchema::Language::UnresolvedValueError do
      exec_future_query("{ favoriteLanguage }", context: { favorite_language: "COFFEE_SCRIPT"})
    end
    assert_equal "COFFEE_SCRIPT", exec_query("{ favoriteLanguage(lang: COFFEE_SCRIPT) }")["data"]["favoriteLanguage"]
    assert_equal ["Argument 'lang' on Field 'favoriteLanguage' has an invalid value (COFFEE_SCRIPT). Expected type 'Language'."], exec_future_query("{ favoriteLanguage(lang: COFFEE_SCRIPT) }")["errors"].map { |e| e["message"] }

    assert_equal "RAKU", exec_future_query("{ favoriteLanguage }", context: { favorite_language: "RAKU"})["data"]["favoriteLanguage"]
    assert_raises MultifieldSchema::Language::UnresolvedValueError do
      exec_query("{ favoriteLanguage }", context: { favorite_language: "RAKU"})
    end
    assert_equal "RAKU", exec_future_query("{ favoriteLanguage(lang: RAKU) }")["data"]["favoriteLanguage"]
    assert_equal ["Argument 'lang' on Field 'favoriteLanguage' has an invalid value (RAKU). Expected type 'Language'."], exec_query("{ favoriteLanguage(lang: RAKU) }")["errors"].map { |e| e["message"] }
  end

  it "supports multiple types with the same name in orphan_types" do
    legacy_schema = legacy_schema_sdl
    assert_includes legacy_schema, "legacyPlaceField"
    refute_includes legacy_schema, "futurePlaceField"
    assert_equal ["type Place"], legacy_schema.scan("type Place")
    future_schema = future_schema_sdl
    refute_includes future_schema, "legacyPlaceField"
    assert_includes future_schema, "futurePlaceField"
    assert_equal ["type Place"], future_schema.scan("type Place")
  end

  it "supports different resolver arguments" do
    assert_equal "4", exec_query("{ add(left: 1, right: 3) }")["data"]["add"]
    assert_equal ["Argument 'left' on Field 'add' has an invalid value (1.2). Expected type 'Int!'."], exec_query("{ add(left: 1.2, right: 3) }")["errors"].map { |e| e["message"] }

    assert_equal "4.5", exec_future_query("{ add(left: 1.2, right: 3.3) }")["data"]["add"]
    assert_equal "4.2", exec_future_query("{ add(left: 1.2, right: 3) }")["data"]["add"]

    introspection_query_str = "{ __type(name: \"Query\") { fields { name args { type { ofType { name } } } } } }"
    legacy_res = exec_query(introspection_query_str)
    assert_equal ["Int", "Int"], legacy_res["data"]["__type"]["fields"].find { |f| f["name"] == "add" }["args"].map { |a| a["type"]["ofType"]["name"] }
    future_res = exec_future_query(introspection_query_str)
    assert_equal ["Float", "Float"], future_res["data"]["__type"]["fields"].find { |f| f["name"] == "add" }["args"].map { |a| a["type"]["ofType"]["name"] }
  end

  it "supports unions with possible types of the same name" do
    assert_includes future_schema_sdl, "union Actor = Bot\n"
    assert_includes future_schema_sdl, "type Bot {\n  isVerified: Boolean!\n  name: String!\n}\n"
    assert_equal 1, future_schema_sdl.scan("type Bot").size
    assert_includes legacy_schema_sdl, "union Actor = Bot\n"
    assert_includes legacy_schema_sdl, "type Bot {\n  handle: String!\n  verified: Boolean!\n}\n"
    assert_equal 1, legacy_schema_sdl.scan("type Bot").size

    legacy_res = exec_query("{ actor { ... on Bot { handle } } }")
    assert_equal "bot1", legacy_res["data"]["actor"]["handle"]
    legacy_res2 = exec_query("{ actor { ... on Bot { name } } }")
    assert_equal ["Field 'name' doesn't exist on type 'Bot'"], legacy_res2["errors"].map { |e| e["message"] }

    future_res = exec_future_query("{ actor { ... on Bot { name } } }")
    assert_equal "bot2", future_res["data"]["actor"]["name"]
    future_res2 = exec_future_query("{ actor { ... on Bot { handle } } }")
    assert_equal ["Field 'handle' doesn't exist on type 'Bot'"], future_res2["errors"].map { |e| e["message"] }

    introspection_query_str = "{ __type(name: \"Actor\") { possibleTypes { description } } }"
    assert_equal ["Legacy bot"], exec_query(introspection_query_str)["data"]["__type"]["possibleTypes"].map { |t| t["description"] }
    assert_equal ["Future bot"], exec_future_query(introspection_query_str)["data"]["__type"]["possibleTypes"].map { |t| t["description"] }
  end

  it "supports different types connected by argument definitions" do
    future_description = "A saying ending with at least four exclamation points"
    legacy_description = "An all-uppercase saying"
    assert_includes future_schema_sdl, future_description
    refute_includes future_schema_sdl, legacy_description

    assert_includes legacy_schema_sdl, legacy_description
    refute_includes legacy_schema_sdl, future_description

    query_str = "query($scream: Scream!) { yell(scream: $scream) }"
    assert_equal "YIKES", exec_query(query_str, variables: { scream: "YIKES" })["data"]["yell"]
    assert_equal ["scream must be SCREAMING"], exec_query(query_str, variables: { scream: "yikes!!!!" })["errors"].map { |e| e["extensions"]["problems"].first["explanation"] }
    assert_equal "yikes!!!!", exec_future_query(query_str, variables: { scream: "yikes!!!!" })["data"]["yell"]
    assert_equal ["scream must be screaming!!!!"], exec_future_query(query_str, variables: { scream: "YIKES" })["errors"].map { |e| e["extensions"]["problems"].first["explanation"] }
  end

  describe "A schema with every possible type having the same name" do
    class NameConflictSchema < GraphQL::Schema
      use GraphQL::Schema::Warden if ADD_WARDEN
      module ConflictingThing
        def visible?(context)
          super && kind.name == context[:thing_kind]
        end
      end

      class ThingScalar < GraphQL::Schema::Scalar
        graphql_name "Thing"
        extend ConflictingThing
      end

      class ThingEnum < GraphQL::Schema::Enum
        graphql_name "Thing"
        value "T"
        extend ConflictingThing
      end

      class ThingInput < GraphQL::Schema::InputObject
        graphql_name "Thing"
        argument :t, Int
        extend ConflictingThing
      end

      module ThingInterface
        include GraphQL::Schema::Interface
        graphql_name "Thing"
        field :t, String, null: false
        extend ConflictingThing

        def self.resolve_type(_obj, _ctx)
          OtherObject
        end
      end

      class ThingObject < GraphQL::Schema::Object
        graphql_name "Thing"
        field :t, String, null: false
        extend ConflictingThing
      end

      class OtherObject < GraphQL::Schema::Object
        implements ThingInterface
        field :f, Int, null: false
      end
      class ThingUnion < GraphQL::Schema::Union
        graphql_name "Thing"
        possible_types OtherObject
        extend ConflictingThing

        def self.resolve_type(obj, ctx)
          OtherObject
        end
      end

      class BaseField < GraphQL::Schema::Field
        def visible?(context)
          if graphql_name == "thing"
            type.kind.name == context[:thing_kind] && super
          else
            super
          end
        end
      end

      class Query < GraphQL::Schema::Object
        field_class BaseField
        field :f1, Int, null: false do
          argument :thing, ThingInput, required: false
        end

        def f1(thing: nil)
          5 * thing[:t]
        end

        field :thing, ThingScalar
        field :thing, ThingEnum
        field :thing, ThingObject
        field :thing, ThingUnion
        field :thing, ThingInterface

        def thing
          type_kind = context[:current_field].type.kind.name
          case type_kind
          when "ENUM"
            "T"
          when "SCALAR"
            "T2"
          when "UNION"
            { f: 12 }
          when "OBJECT"
            { t: "object" }
          when "INTERFACE"
            { f: 22 }
          else
            raise ArgumentError, "Unhandled type kind: #{type_kind.inspect}"
          end
        end

        field :other_object, OtherObject
      end

      query(Query)
    end
  end

  def check_thing_type_is_kind(type_kind)
    context = { thing_kind: type_kind }

    all_types_query_str = "{ __schema { types { name kind } } }"
    all_types_res = NameConflictSchema.execute(all_types_query_str, context: context)
    thing_types = all_types_res["data"]["__schema"]["types"].select { |t| t["name"] == "Thing" }
    assert_equal 1, thing_types.size, "Only one type called Thing (#{thing_types})"

    query_str = "{ __type(name: \"Thing\") { name kind } }"
    res = NameConflictSchema.execute(query_str, context: context)
    type_res = res["data"]["__type"]
    assert_equal thing_types.first, type_res, "The introspection results match"

    schema_dump = NameConflictSchema.to_definition(context: context)
    return schema_dump, context
  end

  it "returns one type at a time for the given name" do
    schema_dump, context = check_thing_type_is_kind("ENUM")
    assert_equal 2, schema_dump.scan("Thing").size, "The schema dump contains a type definition and field definition: #{schema_dump}"
    assert_includes schema_dump, "enum Thing {\n"
    res = NameConflictSchema.execute("{ thing }", context: context)
    assert_equal "T", res["data"]["thing"]

    schema_dump, context = check_thing_type_is_kind("SCALAR")
    assert_equal 2, schema_dump.scan("Thing").size, "The schema dump contains a type definition and field definition: #{schema_dump}"
    assert_includes schema_dump, "scalar Thing\n"
    res = NameConflictSchema.execute("{ thing }", context: context)
    assert_equal "T2", res["data"]["thing"]

    schema_dump, context = check_thing_type_is_kind("INPUT_OBJECT")
    assert_equal 2, schema_dump.scan("Thing").size, "input defn, argument defn: #{schema_dump}"
    assert_includes schema_dump, "input Thing {\n"
    assert_includes schema_dump, "f1(thing: Thing): Int!"
    res = NameConflictSchema.execute("{ f1(thing: { t: 100 } ) }", context: context)
    assert_equal 500, res["data"]["f1"]

    schema_dump, context = check_thing_type_is_kind("OBJECT")
    assert_equal 2, schema_dump.scan("Thing").size, "The schema dump contains a type definition and field definition: #{schema_dump}"
    assert_includes schema_dump, "type Thing {\n"
    assert_includes schema_dump, "\n  thing: Thing\n"
    assert_includes schema_dump, "f1: Int!\n"
    res = NameConflictSchema.execute("{ thing { t } }", context: context)
    assert_equal "object", res["data"]["thing"]["t"]

    schema_dump, context = check_thing_type_is_kind("UNION")
    assert_equal 2, schema_dump.scan("Thing").size, "The schema dump contains a type definition and field definition: #{schema_dump}"
    assert_includes schema_dump, "union Thing = OtherObject\n"
    res = NameConflictSchema.execute("{ thing { ... on Thing { __typename  } ... on OtherObject { f } } }", context: context)
    assert_equal "OtherObject", res["data"]["thing"]["__typename"]
    assert_equal 12, res["data"]["thing"]["f"]

    schema_dump, context = check_thing_type_is_kind("INTERFACE")
    assert_includes schema_dump, "interface Thing {\n"
    assert_includes schema_dump, "type OtherObject implements Thing {\n"
    assert_equal 3, schema_dump.scan("Thing").size, "Interface definition, interface field, object field: #{schema_dump}"
    res = NameConflictSchema.execute("{ thing { ... on Thing { __typename  } ... on OtherObject { f } } }", context: context)
    assert_equal "OtherObject", res["data"]["thing"]["__typename"]
    assert_equal 22, res["data"]["thing"]["f"]
  end

  describe "duplicate values for a given name" do
    module DuplicateNames
      module HasAllowedFor
        def initialize(*args, allow_for: nil, **kwargs, &block)
          super(*args, **kwargs, &block)
          @allow_for = allow_for
        end

        def visible?(context)
          super && @allow_for ? @allow_for.include?(context[:allowed_for]) : true
        end
      end

      class BaseArgument < GraphQL::Schema::Argument
        include HasAllowedFor
      end

      class BaseField < GraphQL::Schema::Field
        include HasAllowedFor
        argument_class(BaseArgument)
      end

      class BaseEnumValue < GraphQL::Schema::EnumValue
        include HasAllowedFor
      end

      class DuplicateEnumValue < GraphQL::Schema::Enum
        enum_value_class(BaseEnumValue)
        value "ONE", description: "second definition", allow_for: [2, 3]
        value "ONE", description: "first definition", allow_for: [1, 2]
      end

      class DuplicateFieldObject < GraphQL::Schema::Object
        field_class(BaseField)
        field :f, String, allow_for: [1, 2], description: "first definition"
        field :f, Int, allow_for: [2, 3], description: "second definition"
      end

      class DuplicateArgumentObject < GraphQL::Schema::Object
        field_class BaseField

        field :multi_arg, String do
          argument :a, String, required: false, allow_for: [1, 2], description: "first definition"
          argument :a, Int, required: false, allow_for: [2, 3], description: "second definition"
        end
      end

      class DuplicateNameObject1 < GraphQL::Schema::Object
        graphql_name("DuplicateNameObject")
        description "first definition"

        field :f, String, null: false

        def self.visible?(context)
          (context[:allowed_for] == 1 || context[:allowed_for] == 2) && super
        end
      end

      class DuplicateNameObject2 < GraphQL::Schema::Object
        graphql_name("DuplicateNameObject")
        description "second definition"

        field :f, String, null: false

        def self.visible?(context)
          (context[:allowed_for] == 2 || context[:allowed_for] == 3) && super
        end
      end
    end

    it "raises when a given context would permit multiple types with the same name" do
      query_type = Class.new(GraphQL::Schema::Object) {
        graphql_name("Query")
        field(:f1, DuplicateNames::DuplicateNameObject1, null: false)
        field(:f2, DuplicateNames::DuplicateNameObject2, null: false)
      }
      schema = Class.new(GraphQL::Schema) {
        query(query_type)
        use GraphQL::Schema::Warden if ADD_WARDEN
      }
      assert_equal "first definition", schema.types({ allowed_for: 1 })["DuplicateNameObject"].description
      assert_equal "second definition", schema.get_type("DuplicateNameObject", { allowed_for: 3 }).description
      assert_includes schema.to_definition(context: { allowed_for: 1 }), "first definition"
      refute_includes schema.to_definition(context: { allowed_for: 1 }), "second definition"
      assert_includes schema.to_definition(context: { allowed_for: 3 }), "second definition"
      refute_includes schema.to_definition(context: { allowed_for: 3 }), "first definition"

      assert_includes schema.to_json(context: { allowed_for: 1 }), "first definition"
      refute_includes schema.to_json(context: { allowed_for: 1 }), "second definition"
      assert_includes schema.to_json(context: { allowed_for: 3 }), "second definition"
      refute_includes schema.to_json(context: { allowed_for: 3 }), "first definition"


      err = assert_raises GraphQL::Schema::DuplicateNamesError do
        schema.types({ allowed_for: 2 })
      end
      assert_equal "DuplicateNameObject", err.duplicated_name
      expected_message = "Found two visible definitions for `DuplicateNameObject`: DuplicateNames::DuplicateNameObject1, DuplicateNames::DuplicateNameObject2"
      assert_equal expected_message, err.message

      err2 = assert_raises GraphQL::Schema::DuplicateNamesError do
        schema.get_type("DuplicateNameObject", { allowed_for: 2 })
      end
      assert_equal "DuplicateNameObject", err2.duplicated_name

      assert_equal expected_message, err2.message

      err3 = assert_raises GraphQL::Schema::DuplicateNamesError do
        schema.to_definition(context: { allowed_for: 2 })
      end
      assert_equal "DuplicateNameObject", err3.duplicated_name
      assert_equal expected_message, err3.message

      err4 = assert_raises GraphQL::Schema::DuplicateNamesError do
        schema.to_json(context: { allowed_for: 2 })
      end
      assert_equal "DuplicateNameObject", err4.duplicated_name
      assert_equal expected_message, err4.message
    end

    it "raises when a given context would permit multiple enum values with the same name" do
      enum_type = DuplicateNames::DuplicateEnumValue
      query_type = Class.new(GraphQL::Schema::Object) { graphql_name("Query"); field(:f, enum_type, null: false) }
      schema = Class.new(GraphQL::Schema) {
        query(query_type)
        use GraphQL::Schema::Warden if ADD_WARDEN
      }

      assert_equal "first definition", enum_type.values({ allowed_for: 1 })["ONE"].description
      assert_equal "second definition", enum_type.values({ allowed_for: 3 })["ONE"].description
      assert_includes schema.to_definition(context: { allowed_for: 1 }), "first definition"
      refute_includes schema.to_definition(context: { allowed_for: 1 }), "second definition"
      assert_includes schema.to_definition(context: { allowed_for: 3 }), "second definition"
      refute_includes schema.to_definition(context: { allowed_for: 3 }), "first definition"

      assert_includes schema.to_json(context: { allowed_for: 1 }), "first definition"
      refute_includes schema.to_json(context: { allowed_for: 1 }), "second definition"
      assert_includes schema.to_json(context: { allowed_for: 3 }), "second definition"
      refute_includes schema.to_json(context: { allowed_for: 3 }), "first definition"

      err = assert_raises GraphQL::Schema::DuplicateNamesError do
        enum_type.values({ allowed_for: 2 })
      end
      expected_message ="Found two visible definitions for `DuplicateEnumValue.ONE`: #<DuplicateNames::BaseEnumValue DuplicateEnumValue.ONE @value=\"ONE\" @description=\"second definition\">, #<DuplicateNames::BaseEnumValue DuplicateEnumValue.ONE @value=\"ONE\" @description=\"first definition\">"
      assert_equal expected_message, err.message

      # no get_value method ... yet ...

      err3 = assert_raises GraphQL::Schema::DuplicateNamesError do
        schema.to_definition(context: { allowed_for: 2 })
      end
      assert_equal "DuplicateEnumValue.ONE", err3.duplicated_name
      assert_equal expected_message, err3.message

      err4 = assert_raises GraphQL::Schema::DuplicateNamesError do
        schema.to_json(context: { allowed_for: 2 })
      end
      assert_equal "DuplicateEnumValue.ONE", err4.duplicated_name
      assert_equal expected_message, err4.message
    end

    it "raises when a given context would permit multiple argument definitions" do
      schema = Class.new(GraphQL::Schema) {
        query(DuplicateNames::DuplicateArgumentObject)
        use GraphQL::Schema::Warden if ADD_WARDEN
      }
      field = DuplicateNames::DuplicateArgumentObject.get_field("multiArg")

      assert_equal "first definition", field.get_argument("a", { allowed_for: 1 }).description
      assert_equal "second definition", field.arguments({ allowed_for: 3 })["a"].description
      assert_includes schema.to_definition(context: { allowed_for: 1 }), "first definition"
      refute_includes schema.to_definition(context: { allowed_for: 1 }), "second definition"
      assert_includes schema.to_definition(context: { allowed_for: 3 }), "second definition"
      refute_includes schema.to_definition(context: { allowed_for: 3 }), "first definition"

      assert_includes schema.to_json(context: { allowed_for: 1 }), "first definition"
      refute_includes schema.to_json(context: { allowed_for: 1 }), "second definition"
      assert_includes schema.to_json(context: { allowed_for: 3 }), "second definition"
      refute_includes schema.to_json(context: { allowed_for: 3 }), "first definition"

      err = assert_raises GraphQL::Schema::DuplicateNamesError do
        field.arguments({ allowed_for: 2 })
      end
      expected_message = "Found two visible definitions for `DuplicateArgumentObject.multiArg.a`: #<DuplicateNames::BaseArgument DuplicateArgumentObject.multiArg.a: String @description=\"first definition\">, #<DuplicateNames::BaseArgument DuplicateArgumentObject.multiArg.a: Int @description=\"second definition\">"
      assert_equal expected_message, err.message
      assert_equal "DuplicateArgumentObject.multiArg.a", err.duplicated_name

      err2 = assert_raises GraphQL::Schema::DuplicateNamesError do
        field.get_argument("a", { allowed_for: 2 })
      end
      assert_equal expected_message, err2.message
      assert_equal "DuplicateArgumentObject.multiArg.a", err2.duplicated_name

      err3 = assert_raises GraphQL::Schema::DuplicateNamesError do
        schema.to_definition(context: { allowed_for: 2 })
      end
      assert_equal expected_message, err3.message
      assert_equal "DuplicateArgumentObject.multiArg.a", err3.duplicated_name

      err4 = assert_raises GraphQL::Schema::DuplicateNamesError do
        schema.to_json(context: { allowed_for: 2 })
      end
      assert_equal expected_message, err4.message
      assert_equal "DuplicateArgumentObject.multiArg.a", err4.duplicated_name
    end

    it "raises when a given context would permit multiple field definitions" do
      schema = Class.new(GraphQL::Schema) {
        query(DuplicateNames::DuplicateFieldObject)
        use GraphQL::Schema::Warden if ADD_WARDEN
      }
      assert_equal "first definition", DuplicateNames::DuplicateFieldObject.get_field("f", { allowed_for: 1 }).description
      assert_equal "second definition", DuplicateNames::DuplicateFieldObject.fields({ allowed_for: 3 })["f"].description
      assert_includes schema.to_definition(context: { allowed_for: 1 }), "first definition"
      refute_includes schema.to_definition(context: { allowed_for: 1 }), "second definition"
      assert_includes schema.to_definition(context: { allowed_for: 3 }), "second definition"
      refute_includes schema.to_definition(context: { allowed_for: 3 }), "first definition"

      assert_includes schema.to_json(context: { allowed_for: 1 }), "first definition"
      refute_includes schema.to_json(context: { allowed_for: 1 }), "second definition"
      assert_includes schema.to_json(context: { allowed_for: 3 }), "second definition"
      refute_includes schema.to_json(context: { allowed_for: 3 }), "first definition"

      err = assert_raises GraphQL::Schema::DuplicateNamesError do
        DuplicateNames::DuplicateFieldObject.fields({ allowed_for: 2 })
      end
      expected_message = "Found two visible definitions for `DuplicateFieldObject.f`: #<DuplicateNames::BaseField DuplicateFieldObject.f: String>, #<DuplicateNames::BaseField DuplicateFieldObject.f: Int>"
      assert_equal expected_message, err.message
      assert_equal "DuplicateFieldObject.f", err.duplicated_name

      err2 = assert_raises GraphQL::Schema::DuplicateNamesError do
        DuplicateNames::DuplicateFieldObject.get_field("f", { allowed_for: 2 })
      end
      assert_equal expected_message, err2.message
      assert_equal "DuplicateFieldObject.f", err2.duplicated_name

      err3 = assert_raises GraphQL::Schema::DuplicateNamesError do
        schema.to_definition(context: { allowed_for: 2 })
      end
      assert_equal expected_message, err3.message
      assert_equal "DuplicateFieldObject.f", err3.duplicated_name

      err4 = assert_raises GraphQL::Schema::DuplicateNamesError do
        schema.to_json(context: { allowed_for: 2 })
      end
      assert_equal expected_message, err4.message
      assert_equal "DuplicateFieldObject.f", err4.duplicated_name
    end
  end
end
