# frozen_string_literal: true
require "spec_helper"
require "fiber"

if defined?(Console) && defined?(Async)
  Console.logger.disable(Async::Task)
end

describe GraphQL::Dataloader do
  class BatchedCallsCounter
    def initialize
      @count = 0
    end

    def increment
      @count += 1
    end

    attr_reader :count
  end

  class FiberSchema < GraphQL::Schema
    module Database
      extend self
      DATA = {}
      [
        { id: "1", name: "Wheat", type: "Grain" },
        { id: "2", name: "Corn", type: "Grain" },
        { id: "3", name: "Butter", type: "Dairy" },
        { id: "4", name: "Baking Soda", type: "LeaveningAgent" },
        { id: "5", name: "Cornbread", type: "Recipe", ingredient_ids: ["1", "2", "3", "4"] },
        { id: "6", name: "Grits", type: "Recipe", ingredient_ids: ["2", "3", "7"] },
        { id: "7", name: "Cheese", type: "Dairy" },
      ].each { |d| DATA[d[:id]] = d }

      def log
        @log ||= []
      end

      def mget(ids)
        log << [:mget, ids.sort]
        ids.map { |id| DATA[id] }
      end

      def find_by(attribute, values)
        log << [:find_by, attribute, values.sort]
        values.map { |v| DATA.each_value.find { |dv| dv[attribute] == v } }
      end
    end

    class DataObject < GraphQL::Dataloader::Source
      def initialize(column = :id)
        @column = column
      end

      def fetch(keys)
        if @column == :id
          Database.mget(keys)
        else
          Database.find_by(@column, keys)
        end
      end
    end

    class ToString < GraphQL::Dataloader::Source
      def fetch(keys)
        keys.map(&:to_s)
      end
    end

    class NestedDataObject < GraphQL::Dataloader::Source
      def fetch(ids)
        @dataloader.with(DataObject).load_all(ids)
      end
    end

    class SlowDataObject < GraphQL::Dataloader::Source
      def initialize(batch_key)
        # This is just so that I can force different instances in test
        @batch_key = batch_key
      end

      def fetch(keys)
        t = Thread.new {
          sleep 0.5
          Database.mget(keys)
        }
        dataloader.yield
        t.value
      end
    end

    class CustomBatchKeySource < GraphQL::Dataloader::Source
      def initialize(batch_key)
        @batch_key = batch_key
      end

      def self.batch_key_for(batch_key)
        Database.log << [:batch_key_for, batch_key]
        # Ignore it altogether
        :all_the_same
      end

      def fetch(keys)
        Database.mget(keys)
      end
    end

    class KeywordArgumentSource < GraphQL::Dataloader::Source
      def initialize(column:)
        @column = column
      end

      def fetch(keys)
        if @column == :id
          Database.mget(keys)
        else
          Database.find_by(@column, keys)
        end
      end
    end

    class AuthorizedSource < GraphQL::Dataloader::Source
      def initialize(counter)
        @counter = counter
      end

      def fetch(recipes)
        @counter&.increment
        recipes.map { true }
      end
    end

    class ErrorSource < GraphQL::Dataloader::Source
      def fetch(ids)
        raise GraphQL::Error, "Source error on: #{ids.inspect}"
      end
    end

    module Ingredient
      include GraphQL::Schema::Interface
      field :name, String, null: false
      field :id, ID, null: false

      field :name_by_scoped_context, String

      def name_by_scoped_context
        context[:ingredient_name]
      end
    end

    class Grain < GraphQL::Schema::Object
      implements Ingredient
    end

    class LeaveningAgent < GraphQL::Schema::Object
      implements Ingredient
    end

    class Dairy < GraphQL::Schema::Object
      implements Ingredient
    end

    class Recipe < GraphQL::Schema::Object
      def self.authorized?(obj, ctx)
        ctx.dataloader.with(AuthorizedSource, ctx[:batched_calls_counter]).load(obj)
      end

      field :name, String, null: false
      field :ingredients, [Ingredient], null: false

      def ingredients
        ingredients = dataloader.with(DataObject).load_all(object[:ingredient_ids])
        ingredients
      end

      field :slow_ingredients, [Ingredient], null: false

      def slow_ingredients
        # Use `object[:id]` here to force two different instances of the loader in the test
        dataloader.with(SlowDataObject, object[:id]).load_all(object[:ingredient_ids])
      end
    end

    class Query < GraphQL::Schema::Object
      field :recipes, [Recipe], null: false

      def recipes
        Database.mget(["5", "6"])
      end

      field :ingredient, Ingredient do
        argument :id, ID
      end

      def ingredient(id:)
        dataloader.with(DataObject).load(id)
      end

      field :ingredient_by_name, Ingredient do
        argument :name, String
      end

      def ingredient_by_name(name:)
        ing = dataloader.with(DataObject, :name).load(name)
        context.scoped_set!(:ingredient_name, "Scoped:#{name}")
        ing
      end

      field :nested_ingredient, Ingredient do
        argument :id, ID
      end

      def nested_ingredient(id:)
        dataloader.with(NestedDataObject).load(id)
      end

      field :slow_recipe, Recipe do
        argument :id, ID
      end

      def slow_recipe(id:)
        dataloader.with(SlowDataObject, id).load(id)
      end

      field :recipe, Recipe do
        argument :id, ID, loads: Recipe, as: :recipe
      end

      def recipe(recipe:)
        recipe
      end

      field :recipe_by_id_using_load, Recipe do
        argument :id, ID, required: false
      end

      def recipe_by_id_using_load(id:)
        dataloader.with(DataObject).load(id)
      end

      field :recipes_by_id_using_load_all, [Recipe] do
        argument :ids, [ID, null: true]
      end

      def recipes_by_id_using_load_all(ids:)
        dataloader.with(DataObject).load_all(ids)
      end

      field :recipes_by_id, [Recipe] do
        argument :ids, [ID], loads: Recipe, as: :recipes
      end

      def recipes_by_id(recipes:)
        recipes
      end

      field :key_ingredient, Ingredient do
        argument :id, ID
      end

      def key_ingredient(id:)
        dataloader.with(KeywordArgumentSource, column: :id).load(id)
      end

      class RecipeIngredientInput < GraphQL::Schema::InputObject
        argument :id, ID
        argument :ingredient_number, Int
      end

      field :recipe_ingredient, Ingredient do
        argument :recipe, RecipeIngredientInput
      end

      def recipe_ingredient(recipe:)
        recipe_object = dataloader.with(DataObject).load(recipe[:id])
        ingredient_idx = recipe[:ingredient_number] - 1
        ingredient_id = recipe_object[:ingredient_ids][ingredient_idx]
        dataloader.with(DataObject).load(ingredient_id)
      end

      field :common_ingredients, [Ingredient] do
        argument :recipe_1_id, ID
        argument :recipe_2_id, ID
      end

      def common_ingredients(recipe_1_id:, recipe_2_id:)
        req1 = dataloader.with(DataObject).request(recipe_1_id)
        req2 = dataloader.with(DataObject).request(recipe_2_id)
        recipe1 = req1.load
        recipe2 = req2.load
        common_ids = recipe1[:ingredient_ids] & recipe2[:ingredient_ids]
        dataloader.with(DataObject).load_all(common_ids)
      end

      field :common_ingredients_with_load, [Ingredient], null: false do
        argument :recipe_1_id, ID, loads: Recipe
        argument :recipe_2_id, ID, loads: Recipe
      end

      def common_ingredients_with_load(recipe_1:, recipe_2:)
        common_ids = recipe_1[:ingredient_ids] & recipe_2[:ingredient_ids]
        dataloader.with(DataObject).load_all(common_ids)
      end

      field :common_ingredients_from_input_object, [Ingredient], null: false do
        class CommonIngredientsInput < GraphQL::Schema::InputObject
          argument :recipe_1_id, ID, loads: Recipe
          argument :recipe_2_id, ID, loads: Recipe
        end
        argument :input, CommonIngredientsInput
      end

      def common_ingredients_from_input_object(input:)
        recipe_1 = input[:recipe_1]
        recipe_2 = input[:recipe_2]
        common_ids = recipe_1[:ingredient_ids] & recipe_2[:ingredient_ids]
        dataloader.with(DataObject).load_all(common_ids)
      end

      field :ingredient_with_custom_batch_key, Ingredient do
        argument :id, ID
        argument :batch_key, String
      end

      def ingredient_with_custom_batch_key(id:, batch_key:)
        dataloader.with(CustomBatchKeySource, batch_key).load(id)
      end

      field :recursive_ingredient_name, String do
        argument :id, ID
      end

      def recursive_ingredient_name(id:)
        res = context.schema.execute("{ ingredient(id: #{id}) { name } }")
        res["data"]["ingredient"]["name"]
      end

      field :test_error, String do
        argument :source, Boolean, required: false, default_value: false
      end

      def test_error(source:)
        if source
          dataloader.with(ErrorSource).load(1)
        else
          raise GraphQL::Error, "Field error"
        end
      end

      class LookaheadInput < GraphQL::Schema::InputObject
        argument :id, ID
        argument :batch_key, String
      end

      field :lookahead_ingredient, Ingredient, extras: [:lookahead] do
        argument :input, LookaheadInput
      end


      def lookahead_ingredient(input:, lookahead:)
        lookahead.arguments # forces a dataloader.run_isolated call
        dataloader.with(CustomBatchKeySource, input[:batch_key]).load(input[:id])
      end
    end

    query(Query)

    class Mutation1 < GraphQL::Schema::Mutation
      argument :argument_1, String, prepare: ->(val, ctx) {
        raise FieldTestError
      }
      field :value, String
      def resolve(argument_1:)
        { value: argument_1 }
      end
    end

    class Mutation2 < GraphQL::Schema::Mutation
      argument :argument_2, String, prepare: ->(val, ctx) {
        raise FieldTestError
      }
      field :value, String
      def resolve(argument_2:)
        { value: argument_2 }
      end
    end

    class Mutation3 < GraphQL::Schema::Mutation
      argument :label, String
      type String

      def resolve(label:)
        log = context[:mutation_log] ||= []
        log << "begin #{label}"
        dataloader.with(DataObject).load(1)
        log << "end #{label}"
        label
      end
    end

    class GetCache < GraphQL::Schema::Mutation
      type String
      def resolve
        dataloader.with(ToString).load(1)
      end
    end

    class Mutation < GraphQL::Schema::Object
      field :mutation_1, mutation: Mutation1
      field :mutation_2, mutation: Mutation2
      field :mutation_3, mutation: Mutation3
      field :set_cache, String do
        argument :input, String
      end

      def set_cache(input:)
        dataloader.with(ToString).merge({ 1 => input })
        input
      end

      field :get_cache, mutation: GetCache
    end

    mutation(Mutation)

    def self.object_from_id(id, ctx)
      ctx.dataloader.with(DataObject).load(id)
    end

    def self.resolve_type(type, obj, ctx)
      get_type(obj[:type])
    end

    orphan_types(Grain, Dairy, Recipe, LeaveningAgent)
    use GraphQL::Dataloader

    class FieldTestError < StandardError; end

    rescue_from(FieldTestError) do |err, obj, args, ctx, field|
      errs = ctx[:errors] ||= []
      errs << "FieldTestError @ #{ctx[:current_path]}, #{field.path} / #{ctx[:current_field].path}"
      nil
    end
  end

  class UsageAnalyzer < GraphQL::Analysis::Analyzer
    def initialize(query)
      @query = query
      @fields = Set.new
    end

    def on_enter_field(node, parent, visitor)
      args = @query.arguments_for(node, visitor.field_definition)
      # This bug has been around for a while,
      # see https://github.com/rmosolgo/graphql-ruby/issues/3321
      if args.is_a?(GraphQL::Execution::Lazy)
        args = args.value
      end
      @fields << [node.name, args.keys]
    end

    def result
      @fields
    end
  end

  def database_log
    FiberSchema::Database.log
  end

  before do
    database_log.clear
  end

  ALL_FIBERS = []


  class PartsSchema < GraphQL::Schema
    class FieldSource < GraphQL::Dataloader::Source
      DATA = [
        {"id" => 1, "name" => "a"},
        {"id" => 2, "name" => "b"},
        {"id" => 3, "name" => "c"},
        {"id" => 4, "name" => "d"},
      ]
      def fetch(fields)
        @previously_fetched ||= Set.new
        fields.each do |f|
          if !@previously_fetched.add?(f)
            raise "Duplicate fetch for #{f.inspect}"
          end
        end
        Array.new(fields.size, DATA)
      end
    end

    class StringFilter < GraphQL::Schema::InputObject
      argument :equal_to_any_of, [String]
    end

    class ComponentFilter < GraphQL::Schema::InputObject
      argument :name, StringFilter
    end

    class FetchObjects < GraphQL::Schema::Resolver
      argument :filter, ComponentFilter, required: false
      def resolve(**_kwargs)
        context.dataloader.with(FieldSource).load("#{field.path}/#{object&.fetch("id")}")
      end
    end

    class Component < GraphQL::Schema::Object
      field :name, String
    end

    class Part < GraphQL::Schema::Object
      field :components, [Component], resolver: FetchObjects
    end

    class Manufacturer < GraphQL::Schema::Object
      field :parts, [Part], resolver: FetchObjects
    end

    class Query < GraphQL::Schema::Object
      field :manufacturers, [Manufacturer], resolver: FetchObjects
    end

    query(Query)
    use GraphQL::Dataloader
  end

  module DataloaderAssertions
    module FiberCounting
      class << self
        attr_accessor :starting_fiber_count, :last_spawn_fiber_count, :last_max_fiber_count

        def current_fiber_count
          count_active_fibers - starting_fiber_count
        end

        def count_active_fibers
          GC.start
          ObjectSpace.each_object(Fiber).count
        end
      end

      def initialize(*args, **kwargs, &block)
        super
        FiberCounting.starting_fiber_count = FiberCounting.count_active_fibers
        FiberCounting.last_max_fiber_count = 0
        FiberCounting.last_spawn_fiber_count = 0
      end

      def spawn_fiber
        result = super
        update_fiber_counts
        result
      end

      def spawn_source_task(parent_task, condition, trace)
        result = super
        if result
          update_fiber_counts
        end
        result
      end

      private

      def update_fiber_counts
        FiberCounting.last_spawn_fiber_count += 1
        current_count = FiberCounting.current_fiber_count
        if current_count > FiberCounting.last_max_fiber_count
          FiberCounting.last_max_fiber_count = current_count
        end
      end
    end

    def self.included(child_class)
      child_class.class_eval do
        let(:schema) { make_schema_from(FiberSchema) }
        let(:parts_schema) { make_schema_from(PartsSchema) }

        it "Works with request(...)" do
          res = schema.execute <<-GRAPHQL
          {
            commonIngredients(recipe1Id: 5, recipe2Id: 6) {
              name
            }
          }
          GRAPHQL

          expected_data = {
            "data" => {
              "commonIngredients" => [
                { "name" => "Corn" },
                { "name" => "Butter" },
              ]
            }
          }
          assert_equal expected_data, res
          assert_equal [[:mget, ["5", "6"]], [:mget, ["2", "3"]]], database_log
        end

        it "runs mutations sequentially" do
          res = schema.execute <<-GRAPHQL
            mutation {
              first: mutation3(label: "first")
              second: mutation3(label: "second")
            }
          GRAPHQL

          assert_equal({ "first" => "first", "second" => "second" }, res["data"])
          assert_equal ["begin first", "end first", "begin second", "end second"], res.context[:mutation_log]
        end

        it "clears the cache between mutations" do
          res = schema.execute <<-GRAPHQL
            mutation {
              setCache(input: "Salad")
              getCache
            }
          GRAPHQL

          assert_equal({"setCache" => "Salad", "getCache" => "1"}, res["data"])
        end

        it "batch-loads" do
          res = schema.execute <<-GRAPHQL
          {
            i1: ingredient(id: 1) { id name }
            i2: ingredient(id: 2) { name }
            r1: recipe(id: 5) {
              # This loads Ingredients 3 and 4
              ingredients { name }
            }
            # This loads Ingredient 7
            ri1: recipeIngredient(recipe: { id: 6, ingredientNumber: 3 }) {
              name
            }
          }
          GRAPHQL

          expected_data = {
            "i1" => { "id" => "1", "name" => "Wheat" },
            "i2" => { "name" => "Corn" },
            "r1" => {
              "ingredients" => [
                { "name" => "Wheat" },
                { "name" => "Corn" },
                { "name" => "Butter" },
                { "name" => "Baking Soda" },
              ],
            },
            "ri1" => {
              "name" => "Cheese",
            },
          }
          assert_equal(expected_data, res["data"])

          expected_log = [
            [:mget, [
              "1", "2",           # The first 2 ingredients
              "5",                # The first recipe
              "6",                # recipeIngredient recipeId
            ]],
            [:mget, [
              "7",                # recipeIngredient ingredient_id
            ]],
            [:mget, [
              "3", "4",           # The two unfetched ingredients the first recipe
            ]],
          ]
          assert_equal expected_log, database_log
        end

        it "caches and batch-loads across a multiplex" do
          context = {}
          result = schema.multiplex([
            { query: "{ i1: ingredient(id: 1) { name } i2: ingredient(id: 2) { name } }", },
            { query: "{ i2: ingredient(id: 2) { name } r1: recipe(id: 5) { ingredients { name } } }", },
            { query: "{ i1: ingredient(id: 1) { name } ri1: recipeIngredient(recipe: { id: 5, ingredientNumber: 2 }) { name } }", },
          ], context: context)

          expected_result = [
            {"data"=>{"i1"=>{"name"=>"Wheat"}, "i2"=>{"name"=>"Corn"}}},
            {"data"=>{"i2"=>{"name"=>"Corn"}, "r1"=>{"ingredients"=>[{"name"=>"Wheat"}, {"name"=>"Corn"}, {"name"=>"Butter"}, {"name"=>"Baking Soda"}]}}},
            {"data"=>{"i1"=>{"name"=>"Wheat"}, "ri1"=>{"name"=>"Corn"}}},
          ]
          assert_equal expected_result, result
          expected_log = [
            [:mget, ["1", "2", "5"]],
            [:mget, ["3", "4"]],
          ]
          assert_equal expected_log, database_log
        end

        it "works with calls within sources" do
          res = schema.execute <<-GRAPHQL
          {
            i1: nestedIngredient(id: 1) { name }
            i2: nestedIngredient(id: 2) { name }
          }
          GRAPHQL

          expected_data = { "i1" => { "name" => "Wheat" }, "i2" => { "name" => "Corn" } }
          assert_equal expected_data, res["data"]
          assert_equal [[:mget, ["1", "2"]]], database_log
        end

        it "works with batch parameters" do
          res = schema.execute <<-GRAPHQL
          {
            i1: ingredientByName(name: "Butter") { id }
            i2: ingredientByName(name: "Corn") { id }
            i3: ingredientByName(name: "Gummi Bears") { id }
          }
          GRAPHQL

          expected_data = {
            "i1" => { "id" => "3" },
            "i2" => { "id" => "2" },
            "i3" => nil,
          }
          assert_equal expected_data, res["data"]
          assert_equal [[:find_by, :name, ["Butter", "Corn", "Gummi Bears"]]], database_log
        end

        it "works with manual parallelism" do
          start = Time.now.to_f
          schema.execute <<-GRAPHQL
          {
            i1: slowRecipe(id: 5) { slowIngredients { name } }
            i2: slowRecipe(id: 6) { slowIngredients { name } }
          }
          GRAPHQL
          finish = Time.now.to_f

          # For some reason Async adds some overhead to this manual parallelism.
          # But who cares, you wouldn't use Thread#join in that case
          delta = schema.dataloader_class == GraphQL::Dataloader ? 0.1 : 0.5
          # Each load slept for 0.5 second, so sequentially, this would have been 2s sequentially
          assert_in_delta 1, finish - start, delta, "Load threads are executed in parallel"
          expected_log = [
            # These were separated because of different recipe IDs:
            [:mget, ["5"]],
            [:mget, ["6"]],
            # These were cached separately because of different recipe IDs:
            [:mget, ["2", "3", "7"]],
            [:mget, ["1", "2", "3", "4"]],
          ]
          # Sort them because threads may have returned in slightly different order
          assert_equal expected_log.sort, database_log.sort
        end

        it "Works with multiple-field selections and __typename" do
          query_str = <<-GRAPHQL
          {
            ingredient(id: 1) {
              __typename
              name
            }
          }
          GRAPHQL

          res = schema.execute(query_str)
          expected_data = {
            "ingredient" => {
              "__typename" => "Grain",
              "name" => "Wheat",
            }
          }
          assert_equal expected_data, res["data"]
        end

        it "Works when the parent field didn't yield" do
          query_str = <<-GRAPHQL
          {
            recipes {
              ingredients {
                name
              }
            }
          }
          GRAPHQL

          res = schema.execute(query_str)
          expected_data = {
            "recipes" =>[
              { "ingredients" => [
                {"name"=>"Wheat"},
                {"name"=>"Corn"},
                {"name"=>"Butter"},
                {"name"=>"Baking Soda"}
              ]},
              { "ingredients" => [
                {"name"=>"Corn"},
                {"name"=>"Butter"},
                {"name"=>"Cheese"}
              ]},
            ]
          }
          assert_equal expected_data, res["data"]

          expected_log = [
            [:mget, ["5", "6"]],
            [:mget, ["1", "2", "3", "4", "7"]],
          ]
          assert_equal expected_log, database_log
        end

        it "loads arguments in batches, even with request" do
          query_str = <<-GRAPHQL
          {
            commonIngredientsWithLoad(recipe1Id: 5, recipe2Id: 6) {
              name
            }
          }
          GRAPHQL

          res = schema.execute(query_str)
          expected_data = {
            "commonIngredientsWithLoad" => [
              {"name"=>"Corn"},
              {"name"=>"Butter"},
            ]
          }
          assert_equal expected_data, res["data"]

          expected_log = [
            [:mget, ["5", "6"]],
            [:mget, ["2", "3"]],
          ]
          assert_equal expected_log, database_log
        end

        it "works with sources that use keyword arguments in the initializer" do
          query_str = <<-GRAPHQL
          {
            keyIngredient(id: 1) {
              __typename
              name
            }
          }
          GRAPHQL

          res = schema.execute(query_str)
          expected_data = {
            "keyIngredient" => {
              "__typename" => "Grain",
              "name" => "Wheat",
            }
          }
          assert_equal expected_data, res["data"]
        end

        it "Works with analyzing arguments with `loads:`, even with .request" do
          query_str = <<-GRAPHQL
          {
            commonIngredientsWithLoad(recipe1Id: 5, recipe2Id: 6) {
              name
            }
          }
          GRAPHQL
          query = GraphQL::Query.new(schema, query_str)
          results = GraphQL::Analysis.analyze_query(query, [UsageAnalyzer])
          expected_results = [
            ["commonIngredientsWithLoad", [:recipe_1, :recipe_2]],
            ["name", []],
          ]
          normalized_results = results.first.to_a
          normalized_results.each do |key, values|
            values.sort!
          end
          assert_equal expected_results, results.first.to_a
        end

        it "Works with input objects, load and request" do
          query_str = <<-GRAPHQL
          {
            commonIngredientsFromInputObject(input: { recipe1Id: 5, recipe2Id: 6 }) {
              name
            }
          }
          GRAPHQL
          res = schema.execute(query_str)
          expected_data = {
            "commonIngredientsFromInputObject" => [
              {"name"=>"Corn"},
              {"name"=>"Butter"},
            ]
          }
          assert_equal expected_data, res["data"]

          expected_log = [
            [:mget, ["5", "6"]],
            [:mget, ["2", "3"]],
          ]
          assert_equal expected_log, database_log
        end

        it "batches calls in .authorized?" do
          query_str = "{ r1: recipe(id: 5) { name } r2: recipe(id: 6) { name } }"
          context = { batched_calls_counter: BatchedCallsCounter.new }
          schema.execute(query_str, context: context)
          assert_equal 1, context[:batched_calls_counter].count

          query_str = "{ recipes { name } }"
          context = { batched_calls_counter: BatchedCallsCounter.new }
          schema.execute(query_str, context: context)
          assert_equal 1, context[:batched_calls_counter].count

          query_str = "{ recipesById(ids: [5, 6]) { name } }"
          context = { batched_calls_counter: BatchedCallsCounter.new }
          schema.execute(query_str, context: context)
          assert_equal 1, context[:batched_calls_counter].count
        end

        it "works when passing nil into source" do
          query_str = <<-GRAPHQL
          query($id: ID) {
            recipe: recipeByIdUsingLoad(id: $id) {
              name
            }
          }
          GRAPHQL
          res = schema.execute(query_str, variables: { id: nil })
          expected_data = { "recipe" => nil }
          assert_equal expected_data, res["data"]

          query_str = <<-GRAPHQL
          query($ids: [ID]!) {
            recipes: recipesByIdUsingLoadAll(ids: $ids) {
              name
            }
          }
          GRAPHQL
          res = schema.execute(query_str, variables: { ids: [nil] })
          expected_data = { "recipes" => nil }
          assert_equal expected_data, res["data"]
        end

        it "Works with input objects using variables, load and request" do
          query_str = <<-GRAPHQL
          query($input: CommonIngredientsInput!) {
            commonIngredientsFromInputObject(input: $input) {
              name
            }
          }
          GRAPHQL
          res = schema.execute(query_str, variables: { input: { recipe1Id: 5, recipe2Id: 6 }})
          expected_data = {
            "commonIngredientsFromInputObject" => [
              {"name"=>"Corn"},
              {"name"=>"Butter"},
            ]
          }
          assert_equal expected_data, res["data"]

          expected_log = [
            [:mget, ["5", "6"]],
            [:mget, ["2", "3"]],
          ]
          assert_equal expected_log, database_log
        end

        it "supports general usage" do
          a = b = c = nil

          res = GraphQL::Dataloader.with_dataloading { |dataloader|
            dataloader.append_job {
              a = dataloader.with(FiberSchema::DataObject).load("1")
            }

            dataloader.append_job {
              b = dataloader.with(FiberSchema::DataObject).load("1")
            }

            dataloader.append_job {
              r1 = dataloader.with(FiberSchema::DataObject).request("2")
              r2 = dataloader.with(FiberSchema::DataObject).request("3")
              c = [
                r1.load,
                r2.load
              ]
            }

            :finished
          }

          assert_equal :finished, res
          assert_equal [[:mget, ["1", "2", "3"]]], database_log
          assert_equal "Wheat", a[:name]
          assert_equal "Wheat", b[:name]
          assert_equal ["Corn", "Butter"], c.map { |d| d[:name] }
        end

        it "works with scoped context" do
          query_str = <<-GRAPHQL
            {
              i1: ingredientByName(name: "Corn") { nameByScopedContext }
              i2: ingredientByName(name: "Wheat") { nameByScopedContext }
              i3: ingredientByName(name: "Butter") { nameByScopedContext }
            }
          GRAPHQL

          expected_data = {
            "i1" => { "nameByScopedContext" => "Scoped:Corn" },
            "i2" => { "nameByScopedContext" => "Scoped:Wheat" },
            "i3" => { "nameByScopedContext" => "Scoped:Butter" },
          }
          result = schema.execute(query_str)
          assert_equal expected_data, result["data"]
        end

        it "works when the schema calls itself" do
          result = schema.execute("{ recursiveIngredientName(id: 1) }")
          assert_equal "Wheat", result["data"]["recursiveIngredientName"]
        end

        it "uses .batch_key_for in source classes" do
          query_str = <<-GRAPHQL
          {
            i1: ingredientWithCustomBatchKey(id: 1, batchKey: "abc") { name }
            i2: ingredientWithCustomBatchKey(id: 2, batchKey: "def") { name }
            i3: ingredientWithCustomBatchKey(id: 3, batchKey: "ghi") { name }
          }
          GRAPHQL

          res = schema.execute(query_str)
          expected_data = { "i1" => { "name" => "Wheat" }, "i2" => { "name" => "Corn" }, "i3" => { "name" => "Butter" } }
          assert_equal expected_data, res["data"]
          expected_log = [
            # Each batch key is given to the source class:
            [:batch_key_for, "abc"],
            [:batch_key_for, "def"],
            [:batch_key_for, "ghi"],
            # But since they return the same value,
            # all keys are fetched in the same call:
            [:mget, ["1", "2", "3"]]
          ]
          assert_equal expected_log, database_log
        end

        it "uses cached values from .merge" do
          query_str = "{ ingredient(id: 1) { id name } }"
          assert_equal "Wheat", schema.execute(query_str)["data"]["ingredient"]["name"]
          assert_equal [[:mget, ["1"]]], database_log
          database_log.clear

          dataloader = schema.dataloader_class.new
          data_source = dataloader.with(FiberSchema::DataObject)
          data_source.merge({ "1" => { name: "Kamut", id: "1", type: "Grain" } })
          assert_equal "Kamut", data_source.load("1")[:name]
          res = schema.execute(query_str, context: { dataloader: dataloader })
          assert_equal [], database_log
          assert_equal "Kamut", res["data"]["ingredient"]["name"]
        end

        it "raises errors from fields" do
          err = assert_raises GraphQL::Error do
            schema.execute("{ testError }")
          end

          assert_equal "Field error", err.message
        end

        it "raises errors from sources" do
          err = assert_raises GraphQL::Error do
            schema.execute("{ testError(source: true) }")
          end

          assert_equal "Source error on: [1]", err.message
        end

        it "works with very very large queries" do
          query_str = "{".dup
          fields = 1100
          fields.times do |i|
            query_str << "\n  field#{i}: lookaheadIngredient(input: { id: 1, batchKey: \"key-#{i}\"}) { name }"
          end
          query_str << "\n}"
          GC.start
          GC.disable
          old_fibers = []
          ObjectSpace.each_object(Fiber) do |f|
            old_fibers << f
          end
          res = schema.execute(query_str)
          assert_equal fields, res["data"].keys.size
          all_fibers = []
          ObjectSpace.each_object(Fiber) do |f|
            all_fibers << f
          end
          new_fibers = all_fibers - old_fibers
          if new_fibers.any?(&:alive?)
            message = "Alive fibers:\n\n".dup
            new_fibers.select(&:alive?).each do |f|
              message << "  - #{f.inspect}\n"
              f.backtrace.each do |line|
                message << "      #{line}\n"
              end
            end
            puts message
          end
          assert_equal [false], new_fibers.map(&:alive?).uniq
        ensure
          GC.enable
        end

        it "doesn't perform duplicate source fetches" do
          query = <<~QUERY
            query {
              manufacturers {
                parts {
                  components(filter: {name: {equalToAnyOf: ["c1", "c2", "c3"]}}) {
                    name
                  }
                }
              }
            }
          QUERY
          response = parts_schema.execute(query).to_h
          assert_equal [4, 4, 4, 4], response["data"]["manufacturers"].map { |parts_obj| parts_obj["parts"].size }
        end

        describe "fiber_limit" do
          def assert_last_max_fiber_count(expected_last_max_fiber_count, message = nil)
            if FiberCounting.last_max_fiber_count == (expected_last_max_fiber_count + 1)
              # TODO why does this happen sometimes?
              warn "AsyncDataloader had +1 last_max_fiber_count"
              assert_equal (expected_last_max_fiber_count + 1), FiberCounting.last_max_fiber_count, message
            else
              assert_equal expected_last_max_fiber_count, FiberCounting.last_max_fiber_count, message
            end
          end

          it "respects a configured fiber_limit" do
            query_str = <<-GRAPHQL
            {
              recipes {
                ingredients {
                  name
                }
              }
              nestedIngredient(id: 2) {
                name
              }
              keyIngredient(id: 4) {
                name
              }
              commonIngredientsWithLoad(recipe1Id: 5, recipe2Id: 6) {
                name
              }
            }
            GRAPHQL

            fiber_counting_dataloader_class = Class.new(schema.dataloader_class)
            fiber_counting_dataloader_class.include(FiberCounting)

            res = schema.execute(query_str, context: { dataloader: fiber_counting_dataloader_class.new })
            assert_nil res.context.dataloader.fiber_limit
            assert_equal 12, FiberCounting.last_spawn_fiber_count
            assert_last_max_fiber_count(9, "No limit works as expected")

            res = schema.execute(query_str, context: { dataloader: fiber_counting_dataloader_class.new(fiber_limit: 4) })
            assert_equal 4, res.context.dataloader.fiber_limit
            assert_equal 14, FiberCounting.last_spawn_fiber_count
            assert_last_max_fiber_count(4, "Limit of 4 works as expected")

            res = schema.execute(query_str, context: { dataloader: fiber_counting_dataloader_class.new(fiber_limit: 6) })
            assert_equal 6, res.context.dataloader.fiber_limit
            assert_equal 10, FiberCounting.last_spawn_fiber_count
            assert_last_max_fiber_count(6, "Limit of 6 works as expected")
          end

          it "accepts a default fiber_limit config" do
            schema = Class.new(FiberSchema) do
              use GraphQL::Dataloader, fiber_limit: 4
            end
            query_str = <<-GRAPHQL
            {
              recipes {
                ingredients {
                  name
                }
              }
              nestedIngredient(id: 2) {
                name
              }
              keyIngredient(id: 4) {
                name
              }
              commonIngredientsWithLoad(recipe1Id: 5, recipe2Id: 6) {
                name
              }
            }
            GRAPHQL
            res = schema.execute(query_str)
            assert_equal 4, res.context.dataloader.fiber_limit
            assert_nil res["errors"]
          end

          it "requires at least three fibers" do
            dl = GraphQL::Dataloader.new(fiber_limit: 2)
            err = assert_raises ArgumentError do
              dl.run
            end
            assert_equal "Dataloader fiber limit is too low (2), it must be at least 4", err.message
          end
        end
      end
    end
  end

  def make_schema_from(schema)
    schema
  end

  include DataloaderAssertions

  if RUBY_VERSION >= "3.1.1"
    require "async"
    describe "AsyncDataloader" do
      def make_schema_from(schema)
        Class.new(schema) {
          use GraphQL::Dataloader::AsyncDataloader
        }
      end

      include DataloaderAssertions
    end
  end

  if Fiber.respond_to?(:scheduler)
    describe "nonblocking: true" do
      def make_schema_from(schema)
        Class.new(schema) do
          use GraphQL::Dataloader, nonblocking: true
        end
      end

      before do
        Fiber.set_scheduler(::DummyScheduler.new)
      end

      after do
        Fiber.set_scheduler(nil)
      end

      include DataloaderAssertions
    end

    if RUBY_ENGINE == "ruby" && !ENV["GITHUB_ACTIONS"]
      describe "nonblocking: true with libev" do
        require "libev_scheduler"
        def make_schema_from(schema)
          Class.new(schema) do
            use GraphQL::Dataloader, nonblocking: true
          end
        end

        before do
          Fiber.set_scheduler(Libev::Scheduler.new)
        end

        after do
          Fiber.set_scheduler(nil)
        end

        include DataloaderAssertions
      end
    end
  end

  describe "example from #3314" do
    module Example
      class FooType < GraphQL::Schema::Object
        field :id, ID, null: false
      end

      class FooSource < GraphQL::Dataloader::Source
        def fetch(ids)
          ids.map { |id| OpenStruct.new(id: id) }
        end
      end

      class QueryType < GraphQL::Schema::Object
        field :foo, Example::FooType do
          argument :foo_id, GraphQL::Types::ID, required: false, loads: Example::FooType
        end

        def foo(foo: nil)
          dataloader.with(Example::FooSource).load("load")
        end
      end

      class Schema < GraphQL::Schema
        query Example::QueryType
        use GraphQL::Dataloader

        def self.object_from_id(id, ctx)
          ctx.dataloader.with(Example::FooSource).load(id)
        end

        def self.resolve_type(type, obj, ctx)
          type
        end
      end
    end

    it "loads properly" do
      result = Example::Schema.execute(<<-GRAPHQL)
      {
        fooWithLoad: foo(fooId: "Other") {
          __typename
          id
        }
      }
      GRAPHQL
      # This should not have a Lazy in it
      expected_result = {
        "data" => {
          "fooWithLoad" => { "id" => "load", "__typename" => "Foo" },
        }
      }

      assert_equal expected_result, result.to_h
    end
  end

  class FiberErrorSchema < GraphQL::Schema
    class ErrorObject < GraphQL::Dataloader::Source
      def fetch(_)
        raise ArgumentError, "Nope"
      end
    end

    class Query < GraphQL::Schema::Object
      field :load, String, null: false
      field :load_all, String, null: false
      field :request, String, null: false
      field :request_all, String, null: false

      def load
        dataloader.with(ErrorObject).load(123)
      end

      def load_all
        dataloader.with(ErrorObject).load_all([123])
      end

      def request
        req = dataloader.with(ErrorObject).request(123)
        req.load
      end

      def request_all
        req = dataloader.with(ErrorObject).request_all([123])
        req.load
      end
    end

    use GraphQL::Dataloader
    query(Query)

    rescue_from(StandardError) do |err, obj, args, ctx, field|
      ctx[:errors] << "#{err.message} (#{field.owner.name}.#{field.graphql_name}, #{obj.inspect}, #{args.inspect})"
      nil
    end
  end

  it "Works with error handlers" do
    context = { errors: [] }

    res = FiberErrorSchema.execute("{ load loadAll request requestAll }", context: context)

    expected_errors = [
      "Nope (FiberErrorSchema::Query.load, nil, {})",
      "Nope (FiberErrorSchema::Query.loadAll, nil, {})",
      "Nope (FiberErrorSchema::Query.request, nil, {})",
      "Nope (FiberErrorSchema::Query.requestAll, nil, {})",
    ]

    assert_nil(res["data"])
    assert_equal(expected_errors, context[:errors].sort)
  end

  it "has proper context[:current_field]" do
    res = FiberSchema.execute("mutation { mutation1(argument1: \"abc\") { __typename } mutation2(argument2: \"def\") { __typename } }")
    assert_equal({"mutation1"=>{ "__typename" => "Mutation1Payload" }, "mutation2"=>{ "__typename" => "Mutation2Payload"} }, res["data"])
    expected_errors = [
      "FieldTestError @ [\"mutation1\"], Mutation.mutation1 / Mutation.mutation1",
      "FieldTestError @ [\"mutation2\"], Mutation.mutation2 / Mutation.mutation2",
    ]
    assert_equal expected_errors, res.context[:errors]
  end

  it "passes along throws" do
    value = catch(:hello) do
      dataloader = GraphQL::Dataloader.new
      dataloader.append_job do
        throw(:hello, :world)
      end
      dataloader.run
    end

    assert :world, value
  end

  class CanaryDataloader < GraphQL::Dataloader::NullDataloader
  end

  it "uses context[:dataloader] when given" do
    res = Class.new(GraphQL::Schema) do
      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"
      end
      query(query_type)
    end.execute("{ __typename }")
    assert_instance_of GraphQL::Dataloader::NullDataloader, res.context.dataloader
    res = FiberSchema.execute("{ __typename }")
    assert_instance_of GraphQL::Dataloader, res.context.dataloader
    refute res.context.dataloader.nonblocking?
    res = FiberSchema.execute("{ __typename }", context: { dataloader: CanaryDataloader.new } )
    assert_instance_of CanaryDataloader, res.context.dataloader

    if Fiber.respond_to?(:scheduler)
      Fiber.set_scheduler(::DummyScheduler.new)
      res = FiberSchema.execute("{ __typename }", context: { dataloader: GraphQL::Dataloader.new(nonblocking: true) })
      assert res.context.dataloader.nonblocking?

      res = FiberSchema.multiplex([{ query: "{ __typename }" }], context: { dataloader: GraphQL::Dataloader.new(nonblocking: true) })
      assert res[0].context.dataloader.nonblocking?
      Fiber.set_scheduler(nil)
    end
  end

  describe "#run_isolated" do
    module RunIsolated
      class CountSource < GraphQL::Dataloader::Source
        def fetch(ids)
          @count ||= 0
          @count += ids.size
          ids.map { |_id| @count }
        end
      end
    end

    it "uses its own queue" do
      dl = GraphQL::Dataloader.new
      result = {}
      dl.append_job { result[:a] = 1 }
      dl.append_job { result[:b] = 2 }
      dl.append_job { result[:c] = 3 }

      dl.run_isolated { result[:d] = 4 }

      assert_equal({ d: 4 }, result)

      dl.run_isolated {
        _r1 = dl.with(RunIsolated::CountSource).request(1)
        _r2 = dl.with(RunIsolated::CountSource).request(2)
        r3 = dl.with(RunIsolated::CountSource).request(3)
        # This is going to `Fiber.yield`
        result[:e] = r3.load
      }

      assert_equal({ d: 4, e: 3 }, result)
      dl.run
      assert_equal({ a: 1, b: 2, c: 3, d: 4, e: 3 }, result)
    end

    it "shares a cache" do
      dl = GraphQL::Dataloader.new
      result = {}
      dl.run_isolated {
        _r1 = dl.with(RunIsolated::CountSource).request(1)
        _r2 = dl.with(RunIsolated::CountSource).request(2)
        r3 = dl.with(RunIsolated::CountSource).request(3)
        # Run all three of the above requests:
        result[:a] = r3.load
      }

      dl.append_job {
        # This should return cached from above
        result[:b] = dl.with(RunIsolated::CountSource).load(1)
      }
      dl.append_job {
        # This one is run by itself
        result[:c] = dl.with(RunIsolated::CountSource).load(4)
      }

      assert_equal({ a: 3 }, result)
      dl.run
      assert_equal({ a: 3, b: 3, c: 4 }, result)
    end
  end

  describe "thread local variables" do
    module ThreadVariable
      class Type < GraphQL::Schema::Object
        field :key, String, null: false
        field :value, String, null: false
      end

      class Source < GraphQL::Dataloader::Source
        def fetch(keys)
          keys.map { |key| OpenStruct.new(key: key, value: Thread.current[key.to_sym]) }
        end
      end

      class QueryType < GraphQL::Schema::Object
        field :thread_var, ThreadVariable::Type do
          argument :key, GraphQL::Types::String
        end

        def thread_var(key:)
          dataloader.with(ThreadVariable::Source).load(key)
        end
      end

      class Schema < GraphQL::Schema
        query ThreadVariable::QueryType
        use GraphQL::Dataloader
      end
    end

    it "sets the parent thread locals in the execution fiber" do
      Thread.current[:test_thread_var] = 'foobarbaz'

      result = ThreadVariable::Schema.execute(<<-GRAPHQL)
      {
        threadVar(key: "test_thread_var") {
          key
          value
        }
      }
      GRAPHQL

      expected_result = {
        "data" => {
          "threadVar" => { "key" => "test_thread_var", "value" => "foobarbaz" }
        }
      }

      assert_equal expected_result, result.to_h
    end
  end

  describe "thread-local variables with custom dataloader" do
    module CustomThreadVariable
      class Type < GraphQL::Schema::Object
        field :key, String, null: false
        field :value, String, null: false
      end

      class CustomDataloader < GraphQL::Dataloader
        def get_fiber_variables
          { test_thread_var: "bazbarfoo" }
        end
      end

      class Source < GraphQL::Dataloader::Source
        def fetch(keys)
          keys.map { |key| OpenStruct.new(key: key, value: Thread.current[key.to_sym]) }
        end
      end

      class QueryType < GraphQL::Schema::Object
        field :thread_var, CustomThreadVariable::Type do
          argument :key, GraphQL::Types::String
        end

        def thread_var(key:)
          dataloader.with(CustomThreadVariable::Source).load(key)
        end
      end

      class Schema < GraphQL::Schema
        query CustomThreadVariable::QueryType
        use CustomDataloader
      end
    end

    it "sets the parent thread locals in the execution fiber" do
      result = CustomThreadVariable::Schema.execute(<<-GRAPHQL)
      {
        threadVar(key: "test_thread_var") {
          key
          value
        }
      }
      GRAPHQL

      expected_result = {
        "data" => {
          "threadVar" => { "key" => "test_thread_var", "value" => "bazbarfoo" }
        }
      }

      assert_equal expected_result, result.to_h
    end
  end

  describe "dataloader calls from inside sources" do
    class NestedDataloaderCallsSchema < GraphQL::Schema
      class Echo < GraphQL::Dataloader::Source
        def fetch(keys)
          keys
        end
      end

      class Nested < GraphQL::Dataloader::Source
        def fetch(keys)
          dataloader.with(Echo).load_all(keys)
        end
      end

      class Nested2 < GraphQL::Dataloader::Source
        def fetch(keys)
          dataloader.with(Nested).load_all(keys)
        end
      end

      class QueryType < GraphQL::Schema::Object
        field :nested, String
        field :nested2, String

        def nested
          dataloader.with(Nested).load("nested")
        end

        def nested2
          dataloader.with(Nested2).load("nested2")
        end
      end

      query QueryType
      use GraphQL::Dataloader
    end
  end

  it "loads data from inside source methods" do
    assert_equal({ "data" => { "nested" => "nested" } }, NestedDataloaderCallsSchema.execute("{ nested }"))
    assert_equal({ "data" => { "nested2" => "nested2" } }, NestedDataloaderCallsSchema.execute("{ nested2 }"))
    assert_equal({ "data" => { "nested" => "nested", "nested2" => "nested2" } }, NestedDataloaderCallsSchema.execute("{ nested nested2 }"))
  end

  describe "with lazy authorization hooks" do
    class LazyAuthHookSchema < GraphQL::Schema
      class Source < ::GraphQL::Dataloader::Source
        def fetch(ids)
          return ids.map {|i| i * 2}
        end
      end

      class BarType < GraphQL::Schema::Object
        field :id, Integer

        def id
          object
        end

        def self.authorized?(object, context)
          -> { true }
        end
      end

      class FooType < GraphQL::Schema::Object
        field :dataloader_value, BarType

        def self.authorized?(object, context)
          -> { true }
        end

        def dataloader_value
          dataloader.with(Source).load(1)
        end
      end

      class QueryType < GraphQL::Schema::Object
        field :foo, FooType

        def foo
          {}
        end
      end

      use GraphQL::Dataloader
      query QueryType
      lazy_resolve Proc, :call
    end

    it "resolves everything" do
      dataloader_query = """
        query {
          foo {
            dataloaderValue {
              id
            }
          }
        }
      """
      dataloader_result = LazyAuthHookSchema.execute(dataloader_query)
      assert_equal 2, dataloader_result["data"]["foo"]["dataloaderValue"]["id"]
    end
  end
end
