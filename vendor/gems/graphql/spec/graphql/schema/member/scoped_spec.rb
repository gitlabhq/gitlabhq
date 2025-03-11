# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Member::Scoped do
  class ScopeSchema < GraphQL::Schema
    class BaseObject < GraphQL::Schema::Object
    end

    class Item < BaseObject
      def self.scope_items(items, context)
        context[:scope_calls] ||= 0
        context[:scope_calls] += 1
        if context[:french]
          items.select { |i| i.name == "Trombone" }
        elsif context[:english]
          items.select { |i| i.name == "Paperclip" }
        elsif context[:lazy]
          # return everything, but make the runtime wait for it,
          # and add a flag for confirming it was called
          ->() {
            context[:proc_called] = true
            items
          }
        else
          # boot everything
          items.reject { true }
        end
      end

      def self.authorized?(obj, ctx)
        if ctx[:allow_unscoped]
          true
        else
          raise "This should never be called (#{ctx[:current_path]}, #{ctx[:current_field].path})"
        end
      end

      reauthorize_scoped_objects(false)

      field :name, String, null: false
    end

    class ReauthorizeItem < Item
      reauthorize_scoped_objects(true)

      def self.authorized?(_obj, context)
        context[:was_authorized] = true
        true
      end
    end

    class FrenchItem < Item
      def self.scope_items(items, context)
        super(items, {french: true})
      end
    end

    class Equipment < BaseObject
      field :designation, String, null: false, method: :name
    end

    class BaseUnion < GraphQL::Schema::Union
    end

    class Thing < BaseUnion
      def self.scope_items(items, context)
        l = context.fetch(:first_letter)
        items.select { |i| i.name.start_with?(l) }
      end

      possible_types Item, Equipment

      def self.resolve_type(item, ctx)
        if item.name == "Turbine"
          Equipment
        else
          Item
        end
      end

      reauthorize_scoped_objects(false)
    end

    class Query < BaseObject
      field :items, [Item], null: false
      field :unscoped_items, [Item], null: false,
        scope: false,
        resolver_method: :items

      field :nil_items, [Item]
      def nil_items
        nil
      end

      field :french_items, [FrenchItem], null: false,
        resolver_method: :items

      field :items_connection, Item.connection_type, null: false,
          resolver_method: :items

      def items
        [
          OpenStruct.new(name: "Trombone"),
          OpenStruct.new(name: "Paperclip"),
        ]
      end

      field :reauthorize_items, [ReauthorizeItem], resolver_method: :items

      field :things, [Thing], null: false
      def things
        items + [OpenStruct.new(name: "Turbine")]
      end

      field :lazy_items, [Item], null: false
      field :lazy_items_connection, Item.connection_type, null: false, resolver_method: :lazy_items
      def lazy_items
        ->() { items }
      end
    end

    query(Query)
    lazy_resolve(Proc, :call)
  end

  describe ".scope_items(items, ctx)" do
    def get_item_names_with_context(ctx, field_name: "items")
      query_str = "
      {
        #{field_name} {
          name
        }
      }
      "
      res = ScopeSchema.execute(query_str, context: ctx)
      res["data"][field_name].map { |i| i["name"] }
    end

    it "applies to lists when scope: true" do
      assert_equal [], get_item_names_with_context({})
      assert_equal ["Trombone"], get_item_names_with_context({french: true})
      assert_equal ["Paperclip"], get_item_names_with_context({english: true})
    end

    it "is bypassed when scope: false" do
      assert_equal ["Trombone", "Paperclip"], get_item_names_with_context({ allow_unscoped: true }, field_name: "unscopedItems")
    end

    it "returns null when the value is nil" do
      query_str = "
      {
        nilItems {
          name
        }
      }
      "
      res = ScopeSchema.execute(query_str)
      refute res.key?("errors")
      assert_nil res.fetch("data").fetch("nilItems")
    end

    it "is inherited" do
      assert_equal ["Trombone"], get_item_names_with_context({}, field_name: "frenchItems")
    end

    it "is called once for connection fields" do
      query_str = "
      {
        itemsConnection {
          edges {
            node {
              name
            }
          }
        }
      }
      "
      res = ScopeSchema.execute(query_str, context: {english: true})
      names = res["data"]["itemsConnection"]["edges"].map { |e| e["node"]["name"] }
      assert_equal ["Paperclip"], names
      assert_equal 1, res.context[:scope_calls]

      query_str = "
      {
        itemsConnection {
          nodes {
            name
          }
        }
      }
      "
      res = ScopeSchema.execute(query_str, context: {english: true})
      names = res["data"]["itemsConnection"]["nodes"].map { |e| e["name"] }
      assert_equal ["Paperclip"], names
      assert_equal 1, res.context[:scope_calls]
    end

    it "works for lazy connection values" do
      ctx = { lazy: true }
      query_str = "
      {
        itemsConnection {
          edges {
            node {
              name
            }
          }
        }
      }
      "
      res = ScopeSchema.execute(query_str, context: ctx)
      names = res["data"]["itemsConnection"]["edges"].map { |e| e["node"]["name"] }
      assert_equal ["Trombone", "Paperclip"], names
      assert_equal true, ctx[:proc_called]
    end

    it "works for lazy returned list values" do
      query_str = "
      {
        lazyItemsConnection {
          edges {
            node {
              name
            }
          }
        }
        lazyItems {
          name
        }
      }
      "
      res = ScopeSchema.execute(query_str, context: { french: true })
      names = res["data"]["lazyItemsConnection"]["edges"].map { |e| e["node"]["name"] }
      assert_equal ["Trombone"], names
      names2 = res["data"]["lazyItems"].map { |e| e["name"] }
      assert_equal ["Trombone"], names2
    end

    it "doesn't shortcut authorization when `reauthorize_scoped_objects(true)`" do
      query_str = "{ reauthorizeItems { name } }"
      res = ScopeSchema.execute(query_str, context: { french: true })
      assert_equal 1, res["data"]["reauthorizeItems"].length
      assert_equal 1, res.context[:scope_calls]
      assert res.context[:was_authorized]
    end

    it "is called for abstract types" do
      query_str = "
      {
        things {
          ... on Item {
            name
          }
          ... on Equipment {
            designation
          }
        }
      }
      "
      res = ScopeSchema.execute(query_str, context: {first_letter: "T"})
      things = res["data"]["things"]
      assert_equal [{ "name" => "Trombone" }, {"designation" => "Turbine"}], things
    end

    it "works with lazy values" do
      ctx = {lazy: true}
      assert_equal ["Trombone", "Paperclip"], get_item_names_with_context(ctx)
      assert_equal true, ctx[:proc_called]
    end
  end

  describe "Schema::Field.scoped?" do
    it "prefers the override value" do
      assert_equal false, ScopeSchema::Query.fields["unscopedItems"].scoped?
    end

    it "defaults to true for lists" do
      assert_equal true, ScopeSchema::Query.fields["items"].type.list?
      assert_equal true, ScopeSchema::Query.fields["items"].scoped?
    end

    it "defaults to true for connections" do
      assert_equal true, ScopeSchema::Query.fields["itemsConnection"].connection?
      assert_equal true, ScopeSchema::Query.fields["itemsConnection"].scoped?
    end

    it "defaults to false for others" do
      assert_equal false, ScopeSchema::Item.fields["name"].scoped?
    end
  end

  describe "ScopeExtension#after_resolve" do
    it "works outside of GraphQL execution" do
      ctx = GraphQL::Query.new(ScopeSchema, "{ __typename }").context
      field = ScopeSchema::Query.fields["items"]
      assert field.resolve(OpenStruct.new(object: { items: [] }), {}, ctx)
    end
  end


  describe "skipping authorization on scoped lists" do
    class SkipAuthSchema < GraphQL::Schema
      class Book < GraphQL::Schema::Object
        def self.authorized?(obj, ctx)
          ctx[:auth_log] << [:authorized?, obj[:title]]
          true
        end

        def self.scope_items(list, ctx)
          ctx[:auth_log] << [:scope_items, list.map { |b| b[:title]}]
          list.dup # Skipping authorized objects requires a new object to be returned
        end

        field :title, String
      end

      class SkipAuthorizationBook < Book
        reauthorize_scoped_objects(false)
      end

      class ReauthorizedBook < Book
        reauthorize_scoped_objects(true)
      end

      class Query < GraphQL::Schema::Object
        field :book, Book

        def book
          { title: "Nonsense Omnibus"}
        end

        field :books, [Book]

        def books
          [{ title: "Jayber Crow" }, { title: "Hannah Coulter" }]
        end

        field :skip_authorization_books, [SkipAuthorizationBook], resolver_method: :books

        field :reauthorized_books, [ReauthorizedBook], resolver_method: :books

        field :skip_authorization_books_connection, SkipAuthorizationBook.connection_type, resolver_method: :books
      end

      query(Query)
    end

    it "runs both authorizations by default" do
      log = []
      SkipAuthSchema.execute("{ book { title } books { title } }", context: { auth_log: log })
      expected_log = [
        [:authorized?, "Nonsense Omnibus"],
        [:scope_items, ["Jayber Crow", "Hannah Coulter"]],
        [:authorized?, "Jayber Crow"],
        [:authorized?, "Hannah Coulter"],
      ]
      assert_equal expected_log, log
    end

    it "skips self.authorized? when configured" do
      log = []
      SkipAuthSchema.execute("{ skipAuthorizationBooks { title } }", context: { auth_log: log })
      assert_equal [[:scope_items, ["Jayber Crow", "Hannah Coulter"]]], log
    end

    it "can be re-enabled in subclasses" do
      log = []
      SkipAuthSchema.execute("{ reauthorizedBooks { title } }", context: { auth_log: log })
      expected_log = [
        [:scope_items, ["Jayber Crow", "Hannah Coulter"]],
        [:authorized?, "Jayber Crow"],
        [:authorized?, "Hannah Coulter"],
      ]

      assert_equal expected_log, log
    end

    it "skips auth in connections" do
      log = []
      SkipAuthSchema.execute("{ skipAuthorizationBooksConnection(first: 10) { nodes { title } } }", context: { auth_log: log })
      assert_equal [[:scope_items, ["Jayber Crow", "Hannah Coulter"]]], log
    end
  end
end
