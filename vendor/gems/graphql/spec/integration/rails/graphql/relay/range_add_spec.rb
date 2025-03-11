# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Relay::RangeAdd do
  # Make sure that the encoder is found through `ctx.schema`:
  module PassThroughEncoder
    def self.encode(unencoded_text, nonce: false)
      "__#{unencoded_text}"
    end

    def self.decode(encoded_text, nonce: false)
      encoded_text[2..-1]
    end
  end

  let(:schema) {
    menus = [
      OpenStruct.new(
        name: "Los Primos",
        items: [
          OpenStruct.new(name: "California Burrito", price: 699),
          OpenStruct.new(name: "Fish Taco", price: 399),
        ]
      )
    ]

    item = Class.new(GraphQL::Schema::Object) do
      graphql_name "Item"
      field :price, Integer, null: false
      field :name, String, null: false
    end

    menu = Class.new(GraphQL::Schema::Object) do
      graphql_name "Menu"
      field :name, String, null: false
      field :items, item.connection_type, null: false
    end

    query = Class.new(GraphQL::Schema::Object) do
      graphql_name "Query"
      field :menus, [menu], null: false
      define_method :menus do
        menus
      end
    end

    add_item = Class.new(GraphQL::Schema::RelayClassicMutation) do
      graphql_name "AddItem"
      argument :name, String
      argument :price, Integer
      argument :menu_idx, Integer

      field :item_edge, item.edge_type, null: false
      field :items, item.connection_type, null: false
      field :menu, menu, null: false

      define_method :resolve do |input|
        this_menu = menus[input[:menu_idx]]
        new_item = OpenStruct.new(name: input[:name], price: input[:price])
        this_menu.items << new_item
        range_add = GraphQL::Relay::RangeAdd.new(
          parent: this_menu,
          item: new_item,
          collection: this_menu.items,
          context: context,
        )

        {
          menu: range_add.parent,
          items: range_add.connection,
          item_edge: range_add.edge,
        }
      end
    end

    mutation = Class.new(GraphQL::Schema::Object) do
      graphql_name "Mutation"
      field :add_item, mutation: add_item
    end

    Class.new(GraphQL::Schema) do
      self.query(query)
      self.mutation(mutation)

      self.cursor_encoder(PassThroughEncoder)
    end
  }


  describe "returning Relay objects" do
    let(:query_str) { <<-GRAPHQL
    mutation {
      addItem(input: {name: "Chilaquiles", price: 699, menuIdx: 0}) {
        menu {
          name
        }
        itemEdge {
          node {
            name
            price
          }
        }
        items {
          edges {
            node {
              name
            }
            cursor
          }
        }
      }
    }
    GRAPHQL
    }

    it "returns a connection and an edge" do
      res = schema.execute(query_str)

      mutation_res = res["data"]["addItem"]
      assert_equal("Los Primos", mutation_res["menu"]["name"])
      assert_equal({"name"=>"Chilaquiles", "price"=>699}, mutation_res["itemEdge"]["node"])
      assert_equal(["California Burrito", "Fish Taco", "Chilaquiles"], mutation_res["items"]["edges"].map { |e| e["node"]["name"] })
      assert_equal(["__1", "__2", "__3"], mutation_res["items"]["edges"].map { |e| e["cursor"] })
    end
  end
end
