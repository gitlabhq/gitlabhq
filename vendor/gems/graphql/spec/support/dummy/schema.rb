# frozen_string_literal: true
require "graphql"
require_relative "./data"
module Dummy
  class NoSuchDairyError < StandardError; end

  class BaseField < GraphQL::Schema::Field
  end

  class AdminField < GraphQL::Schema::Field
    def visible?(context)
      context[:admin] == true
    end
  end

  module BaseInterface
    include GraphQL::Schema::Interface
  end

  class BaseObject < GraphQL::Schema::Object
    field_class BaseField
  end

  class BaseUnion < GraphQL::Schema::Union
  end

  class BaseEnum < GraphQL::Schema::Enum
  end

  class BaseInputObject < GraphQL::Schema::InputObject
  end

  class BaseScalar < GraphQL::Schema::Scalar
  end

  class BaseDirective < GraphQL::Schema::Directive
  end

  module LocalProduct
    include BaseInterface
    description "Something that comes from somewhere"
    field :origin, String, null: false,
      description: "Place the thing comes from"
  end

  module Edible
    include BaseInterface
    description "Something you can eat, yum"
    field :fat_content, Float, null: false, description: "Percentage which is fat"
    field :origin, String, null: false, description: "Place the edible comes from"
    field :self_as_edible, Edible
    def self_as_edible
      object
    end
  end

  module EdibleAsMilk
    include Edible
    description "Milk :+1:"
    def self.resolve_type(obj, ctx)
      Milk
    end
  end

  class DairyAnimal < BaseEnum
    description "An animal which can yield milk"
    value("NONE",     "No animal", value: nil)
    value("COW",      "Animal with black and white spots", value: 1)
    value("DONKEY",   "Animal with fur", value: :donkey)
    value("GOAT",     "Animal with horns")
    value("REINDEER", "Animal with horns", value: 'reindeer')
    value("SHEEP",    "Animal with wool")
    value("YAK",      "Animal with long hair", deprecation_reason: "Out of fashion")
  end

  module AnimalProduct
    include BaseInterface
    description "Comes from an animal, no joke"
    field :source, DairyAnimal, "Animal which produced this product", null: false
  end

  class Cheese < BaseObject
    description "Cultured dairy product"
    implements Edible
    implements EdibleAsMilk
    implements AnimalProduct
    implements LocalProduct

    def self.authorized?(obj, ctx)
      -> { true }
    end

    field :id, Int, "Unique identifier", null: false
    field :flavor, String, "Kind of Cheese", null: false
    field :origin, String, "Place the cheese comes from", null: false

    field :source, DairyAnimal,
      "Animal which produced the milk for this cheese",
      null: false

    field :similar_cheese, Cheese, "Cheeses like this one"  do
      argument :source, [DairyAnimal]
      argument :nullable_source, [DairyAnimal], required: false, default_value: [1]
    end

    def similar_cheese(source:, nullable_source:)
      # get the strings out:
      sources = source
      if sources.include?("YAK")
        raise NoSuchDairyError.new("No cheeses are made from Yak milk!")
      else
        CHEESES.values.find { |cheese| sources.include?(cheese.source) }
      end
    end

    field :nullable_cheese, Cheese, "Not really a Cheese at all" do
      argument :source, [DairyAnimal], required: false
    end
    def nullable_cheese; raise("NotImplemented"); end

    field :dairy_product, "Dummy::DairyProduct", "Some related dairy product, perhaps" do
      argument :input, "Dummy::DairyProductInput", required: false
    end
    def dairy_product; raise("NotImplemented"); end

    field :deeply_nullable_cheese, Cheese, "Definitely not a cheese" do
      argument :source, [[DairyAnimal, null: true], null: true], required: false
    end
    def deeply_nullable_cheese; raise("NotImplemented"); end

    # Keywords can be used for definition methods
    field :fat_content,
      type: Float,
      null: false,
      description: "Percentage which is milkfat",
      deprecation_reason: "Diet fashion has changed"
  end

  class Milk < BaseObject
    description "Dairy beverage"
    implements Edible
    implements EdibleAsMilk
    implements AnimalProduct
    implements LocalProduct

    field :id, ID, null: false
    field :source, DairyAnimal, null: false, description: "Animal which produced this milk"
    field :origin, String, null: false, description: "Place the milk comes from"
    field :flavors, [String, null: true], description: "Chocolate, Strawberry, etc" do
      argument :limit, Int, required: false
    end

    def flavors(limit: nil)
      limit ? object.flavors.first(limit) : object.flavors
    end

    field :execution_error, String
    def execution_error; raise(GraphQL::ExecutionError, "There was an execution error"); end

    field :all_dairy, ["Dummy::DairyProduct", null: true]
    def all_dairy; CHEESES.values + MILKS.values; end
  end

  class Beverage < BaseUnion
    description "Something you can drink"
    possible_types Milk
  end

  class Aspartame < BaseObject; end

  module Sweetener
    include BaseInterface
    field :sweetness, Integer

    orphan_types Aspartame
  end

  # No actual data; This type is an "orphan", only accessible through Interfaces
  class Honey < BaseObject
    description "Sweet, dehydrated bee barf"
    field :flower_type, String, "What flower this honey came from"
    implements Edible
    implements AnimalProduct
    implements Sweetener
  end

  # No actual data; Same as "Honey", but only accessible through an interface's orphans
  class Aspartame < BaseObject
    description "Sugar substitute with an off-flavor aftertaste"
    field :manufacturer, String, "What manufacturer this aspartame came from"
    implements Edible
    implements Sweetener
  end

  class Dairy < BaseObject
    description "A farm where milk is harvested and cheese is produced"
    field :id, ID, null: false
    field :cheese, Cheese
    field :milks, [Milk, null: true]
  end

  class MaybeNull < BaseObject
    description "An object whose fields return nil"
    field :cheese, Cheese
  end

  class TracingScalar < BaseObject
    description "An object which has traced scalars"

    field :trace_nil, Integer
    field :trace_false, Integer, trace: false
    field :trace_true, Integer, trace: true
  end

  class DairyProduct < BaseUnion
    description "Kinds of food made from milk"
    # Test that these forms of declaration still work:
    possible_types "Dummy::Milk", Cheese
  end

  class Cow < BaseObject
    description "A bovine animal that produces milk"
    field :id, ID, null: false
    field :name, String
    field :last_produced_dairy, DairyProduct

    field :cant_be_null_but_is, String, null: false
    def cant_be_null_but_is; nil; end

    field :cant_be_null_but_raises_execution_error, String, null: false
    def cant_be_null_but_raises_execution_error; raise(GraphQL::ExecutionError, "BOOM"); end
  end

  class Goat < BaseObject
    description "An caprinae animal that produces milk"
    field :id, ID, null: false
    field :name, String
    field :last_produced_dairy, DairyProduct
  end

  class Animal < BaseUnion
    description "Species of living things"
    possible_types Cow, Goat
  end

  class AnimalAsCow < BaseUnion
    description "All animals go mooooo!"
    possible_types Cow
    def self.resolve_type(obj, ctx)
      Cow
    end
  end

  class ResourceOrder < BaseInputObject
    graphql_name "ResourceOrderType"
    description "Properties used to determine ordering"

    argument :direction, String, description: "ASC or DESC"
  end

  class DairyProductInput < BaseInputObject
    description "Properties for finding a dairy product"
    argument :source, DairyAnimal, description: "Where it came from"
    argument :origin_dairy, String, required: false, description: "Dairy which produced it", default_value: "Sugar Hollow Dairy"
    argument :fat_content, Float, required: false, description: "How much fat it has", default_value: 0.3
    argument :organic, Boolean, required: false, default_value: false
    argument :order_by, ResourceOrder, required: false, default_value: { direction: "ASC" }, camelize: false
    argument :old_source, String, required: false, deprecation_reason: "No longer supported"
  end

  class PreparedDateInput < BaseInputObject
    description "Input with prepared value"
    argument :date, String, description: "date as a string", required: false
    argument :deprecated_date, String, description: "date as a string", required: false, deprecation_reason: "Use date"

    def prepare
      return nil unless date || deprecated_date

      Date.parse(date || deprecated_date)
    end
  end

  class DeepNonNull < BaseObject
    field :non_null_int, Integer, null: false do
      argument :returning, Integer, required: false
    end
    def non_null_int(returning: nil)
      returning
    end

    field :deep_non_null, DeepNonNull, null: false
    def deep_non_null; :deep_non_null; end
  end

  class Time < BaseScalar
    description "Time since epoch in seconds"
    specified_by_url "https://time.graphql"

    def self.coerce_input(value, ctx)
      Time.at(Float(value))
    rescue ArgumentError
      raise GraphQL::CoercionError, 'cannot coerce to Float'
    end

    def self.coerce_result(value, ctx)
      value.to_f
    end
  end

  class FetchItem < GraphQL::Schema::Resolver
    class << self
      attr_accessor :data
    end

    def self.build(type:, data:, id_type: "Int")
      Class.new(self) do
        graphql_name("Fetch#{type.graphql_name}")
        self.data = data
        type(type, null: true)
        description("Find a #{type.name} by id")
        argument :id, id_type
      end
    end

    def resolve(id:)
      id_string = id.to_s # Cheese has Int type, Milk has ID type :(
      _id, item = self.class.data.find { |item_id, _item| item_id.to_s == id_string }
      item
    end
  end

  class GetSingleton < GraphQL::Schema::Resolver
    class << self
      attr_accessor :data
    end

    def self.build(type:, data:)
      Class.new(self) do
        graphql_name("Get#{type.graphql_name}")
        description("Find the only #{type.name}")
        type(type, null: true)
        self.data = data
      end
    end

    def resolve
      if context[:resolved_count]
        context[:resolved_count] += 1
      end
      self.class.data
    end
  end

  class DairyAppQuery < BaseObject
    graphql_name "Query"
    description "Query root of the system"
    # Returns `root_value:`
    field :root, String
    def root
      object
    end
    field :cheese, resolver: FetchItem.build(type: Cheese, data: CHEESES)
    field :milk, resolver: FetchItem.build(type: Milk, data: MILKS, id_type: "ID")
    field :dairy, resolver: GetSingleton.build(type: Dairy, data: DAIRY)
    field :from_source, [Cheese, null: true], description: "Cheese from source" do
      argument :source, DairyAnimal, required: false, default_value: 1
      argument :old_source, String, required: false, deprecation_reason: "No longer supported"
    end
    def from_source(source:)
      CHEESES.values.select { |c| c.source == source }
    end

    field :favorite_edible, Edible, description: "My favorite food"
    def favorite_edible
      MILKS[1]
    end

    field :cow, resolver: GetSingleton.build(type: Cow, data: COWS[1])
    field :search_dairy, DairyProduct, null: false do
      description "Find dairy products matching a description"
      # This is a list just for testing 😬
      argument :product, [DairyProductInput, null: true], required: false, default_value: [{source: "SHEEP"}]
      argument :old_product, [DairyProductInput], required: false, deprecation_reason: "No longer supported"
      argument :single_product, DairyProductInput, required: false
      argument :product_ids, [String], required: false, deprecation_reason: "No longer supported"
      argument :expires_after, Time, required: false
    end

    def search_dairy(product:, expires_after: nil)
      source = product[0][:source]
      products = CHEESES.values + MILKS.values
      if !source.nil?
        products = products.select { |pr| pr.source == source }
      end
      products.first
    end

    field :all_animal, [Animal, null: true], null: false
    def all_animal
      COWS.values + GOATS.values
    end

    field :all_animal_as_cow, [AnimalAsCow, null: true], null: false, resolver_method: :all_animal

    field :all_dairy, [DairyProduct, null: true] do
      argument :execution_error_at_index, Integer, required: false
    end
    def all_dairy(execution_error_at_index: nil)
      result = CHEESES.values + MILKS.values
      if execution_error_at_index
        result[execution_error_at_index] = GraphQL::ExecutionError.new("missing dairy")
      end
      result
    end

    field :all_edible do
      type [Edible, null: true]
    end

    def all_edible
      CHEESES.values + MILKS.values
    end

    field :all_edible_as_milk, [EdibleAsMilk, null: true], resolver_method: :all_edible

    field :error, String, description: "Raise an error"
    def error
      raise("This error was raised on purpose")
    end

    field :execution_error, String
    def execution_error
      raise(GraphQL::ExecutionError, "There was an execution error")
    end

    field :value_with_execution_error, Integer, null: false, extras: [:execution_errors]
    def value_with_execution_error(execution_errors:)
      execution_errors.add("Could not fetch latest value")
      0
    end

    field :multiple_errors_on_non_nullable_field, String, null: false
    def multiple_errors_on_non_nullable_field
      [
        GraphQL::ExecutionError.new("This is an error message for some error."),
        GraphQL::ExecutionError.new("This is another error message for a different error.")
      ]
    end

    field :multiple_errors_on_non_nullable_list_field, [String], null: false
    def multiple_errors_on_non_nullable_list_field
      [
        GraphQL::ExecutionError.new("The first error message for a field defined to return a list of strings."),
        GraphQL::ExecutionError.new("The second error message for a field defined to return a list of strings.")
      ]
    end

    field :execution_error_with_options, Integer
    def execution_error_with_options
      GraphQL::ExecutionError.new("Permission Denied!", options: { "code" => "permission_denied" })
    end

    field :execution_error_with_extensions, Integer
    def execution_error_with_extensions
      GraphQL::ExecutionError.new("Permission Denied!", extensions: { code: "permission_denied" })
    end

    # To test possibly-null fields
    field :maybe_null, MaybeNull
    def maybe_null
      OpenStruct.new(cheese: nil)
    end

    field :tracing_scalar, TracingScalar
    def tracing_scalar
      OpenStruct.new(
        trace_nil: 2,
        trace_false: 3,
        trace_true: 5,
      )
    end

    field :deep_non_null, null: false do
      type(DeepNonNull)
    end

    def deep_non_null; :deep_non_null; end

    field :huge_integer, Integer
    def huge_integer
      GraphQL::Types::Int::MAX + 1
    end

    field :example_beverage, Beverage # just to add this type to the schema
  end

  class AdminDairyAppQuery < BaseObject
    field_class AdminField

    field :admin_only_message, String
    def admin_only_message
      "This field is only visible to admin"
    end
  end

  GLOBAL_VALUES = []

  class ReplaceValuesInput < BaseInputObject
    argument :values, [Integer]
  end

  class DairyAppMutation < BaseObject
    graphql_name "Mutation"
    description "The root for mutations in this schema"
    field :push_value, [Integer], null: false, description: "Push a value onto a global array :D" do
      argument :value, Integer, as: :val
      argument :deprecated_test_input, DairyProductInput, required: false
      argument :prepared_test_input, PreparedDateInput, required: false
    end
    def push_value(val:)
      GLOBAL_VALUES << val
      GLOBAL_VALUES
    end

    field :replace_values, [Integer], "Replace the global array with new values", null: false do
      argument :input, ReplaceValuesInput
    end

    def replace_values(input:)
      GLOBAL_VALUES.clear
      GLOBAL_VALUES.concat(input[:values])
      GLOBAL_VALUES
    end
  end

  class DirectiveForVariableDefinition < BaseDirective
    locations(VARIABLE_DEFINITION)
  end

  class Subscription < BaseObject
    field :test, String
    def test; "Test"; end
  end

  class Schema < GraphQL::Schema
    query { DairyAppQuery }
    mutation { DairyAppMutation }
    subscription { Subscription }
    max_depth 5
    orphan_types Honey
    trace_with GraphQL::Tracing::CallLegacyTracers
    directives(DirectiveForVariableDefinition)

    rescue_from(NoSuchDairyError) { |err| raise GraphQL::ExecutionError, err.message  }

    def self.resolve_type(type, obj, ctx)
      -> { Schema.types[obj.class.name.split("::").last] }
    end

    # This is used to confirm that the hook is called:
    MAGIC_INT_COERCE_VALUE = -1

    def self.type_error(err, ctx)
      if err.is_a?(GraphQL::IntegerEncodingError) && err.integer_value == 99**99
        MAGIC_INT_COERCE_VALUE
      else
        super
      end
    end

    use GraphQL::Dataloader

    lazy_resolve(Proc, :call)
  end

  class AdminSchema < GraphQL::Schema
    query AdminDairyAppQuery
  end
end
