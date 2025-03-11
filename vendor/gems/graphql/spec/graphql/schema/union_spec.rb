# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Union do
  let(:union) { Jazz::PerformingAct }

  describe ".path" do
    it "is the name" do
      assert_equal "PerformingAct", union.path
    end
  end

  describe "type info" do
    it "has some" do
      assert_equal 2, union.possible_types.size
    end
  end

  describe "filter_possible_types" do
    it "filters types" do
      assert_equal [Jazz::Musician], union.possible_types(context: { hide_ensemble: true })
    end
  end

  describe "in queries" do
    it "works" do
      query_str = <<-GRAPHQL
      {
        nowPlaying {
          ... on Musician {
            name
            instrument {
              family
            }
          }
          ... on Ensemble {
            name
          }
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      expected_data = { "name" => "Bela Fleck and the Flecktones" }
      assert_equal expected_data, res["data"]["nowPlaying"]
    end

    it "does not allow querying filtered types" do
      query_str = <<-GRAPHQL
      {
        nowPlaying {
          ... on Musician {
            name
            instrument {
              family
            }
          }
          ... on Ensemble {
            name
          }
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str, context: { hide_ensemble: true })
      assert_equal 1, res.to_h["errors"].count
      assert_equal "Fragment on Ensemble can't be spread inside PerformingAct", res.to_h["errors"].first["message"]
    end

    describe "type resolution" do
      Box = Struct.new(:value)

      class Schema < GraphQL::Schema
        class A < GraphQL::Schema::Object
          field :a, String, null: false, method: :itself
        end

        class B < GraphQL::Schema::Object
          field :b, String, method: :itself
        end

        class C < GraphQL::Schema::Object
          field :c, Boolean, method: :itself
        end

        class UnboxedUnion < GraphQL::Schema::Union
          possible_types A, C

          def self.resolve_type(object, ctx)
            case object
            when FalseClass
              C
            else
              A
            end
          end
        end

        class BoxedUnion < GraphQL::Schema::Union
          possible_types A, B, C

          def self.resolve_type(object, ctx)
            case object.value
            when "return-nil"
              [B, nil]
            when FalseClass
              [C, object.value]
            else
              [A, object.value]
            end
          end
        end

        class Query < GraphQL::Schema::Object
          field :boxed_union, BoxedUnion

          def boxed_union
            Box.new(context[:value])
          end

          field :unboxed_union, UnboxedUnion

          def unboxed_union
            context[:value]
          end
        end

        query(Query)
      end

      describe "two-value resolution" do
        it "can cast the object after resolving the type" do

          query_str = <<-GRAPHQL
          {
            boxedUnion {
              ... on A { a }
            }
          }
          GRAPHQL

          res = Schema.execute(query_str, context: { value: "unwrapped" })

          assert_equal({
            'data' => { 'boxedUnion' => { 'a' => 'unwrapped' } }
          }, res.to_h)
        end

        it "uses `false` when returned from resolve_type" do
          query_str = <<-GRAPHQL
          {
            boxedUnion {
              ... on C { c }
            }
          }
          GRAPHQL

          res = Schema.execute(query_str, context: { value: false })

          assert_equal({
            'data' => { 'boxedUnion' => { 'c' => false } }
          }, res.to_h)
        end

        it "uses `nil` when returned from resolve_type" do
          query_str = <<-GRAPHQL
          {
            boxedUnion {
              ... on B { b }
            }
          }
          GRAPHQL

          res = Schema.execute(query_str, context: { value: "return-nil" })

          assert_equal({
            'data' => { 'boxedUnion' => { 'b' => nil } }
          }, res.to_h)
        end
      end

      describe "single-value resolution" do
        it "can cast the object after resolving the type" do

          query_str = <<-GRAPHQL
          {
            unboxedUnion {
              ... on A { a }
            }
          }
          GRAPHQL

          res = Schema.execute(query_str, context: { value: "string" })

          assert_equal({
            'data' => { 'unboxedUnion' => { 'a' => 'string' } }
          }, res.to_h)
        end

        it "works with literal false values" do
          query_str = <<-GRAPHQL
          {
            unboxedUnion {
              ... on C { c }
            }
          }
          GRAPHQL

          res = Schema.execute(query_str, context: { value: false })

          assert_equal({
            'data' => { 'unboxedUnion' => { 'c' => false } }
          }, res.to_h)
        end
      end
    end
  end

  it "doesn't allow adding non-object types" do
    object_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "SomeObject"
    end

    err = assert_raises ArgumentError do
      Class.new(GraphQL::Schema::Union) do
        graphql_name "SomeUnion"
        possible_types object_type, GraphQL::Types::Int
      end
    end
    expected_message = "Union possible_types can only be object types (not SCALAR, "
    assert_includes err.message, expected_message

    input_type = Class.new(GraphQL::Schema::InputObject) do
      graphql_name "SomeInput"
      argument :arg, GraphQL::Types::Int
    end

    err = assert_raises ArgumentError do
      Class.new(GraphQL::Schema::Union) do
        graphql_name "SomeUnion"
        possible_types object_type, input_type
      end
    end

    expected_message = "Union possible_types can only be object types (not INPUT_OBJECT, "
    assert_includes err.message, expected_message

    err = assert_raises ArgumentError do
      Class.new(GraphQL::Schema::Union) do
        graphql_name "SomeUnion"
        possible_types object_type, 1234
      end
    end

    expected_message = "Union possible_types can only be class-based GraphQL types (not 1234 (Integer))."
    assert_includes err.message, expected_message
  end

  it "doesn't allow adding interface" do
    object_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "SomeObject"
    end

    interface_type = Module.new {
      include GraphQL::Schema::Interface
      graphql_name "SomeInterface"
    }

    err = assert_raises ArgumentError do
      Class.new(GraphQL::Schema::Union) do
        graphql_name "SomeUnion"
        possible_types object_type, interface_type
      end
    end

    expected_message = /Union possible_types can only be object types \(not interface types\), remove SomeInterface \(#<Module:0x[a-f0-9]+>\)/

    assert_match expected_message, err.message

    union_type = Class.new(GraphQL::Schema::Union) do
      graphql_name "SomeUnion"
      possible_types object_type, GraphQL::Schema::LateBoundType.new("SomeInterface")
    end

    object_type.field(:u, union_type)
    object_type.field(:i, interface_type)

    err2 = assert_raises ArgumentError do
      Class.new(GraphQL::Schema) do
        query(object_type)
      end.to_definition
    end

    assert_match expected_message, err2.message
  end

  describe "migrate legacy tests" do
    describe "#resolve_type" do
      let(:result) { Dummy::Schema.execute(query_string) }
      let(:query_string) {%|
        {
          allAnimal {
            type: __typename
            ... on Cow {
              cowName: name
            }
            ... on Goat {
              goatName: name
            }
          }

          allAnimalAsCow {
            type: __typename
            ... on Cow {
              name
            }
          }
        }
      |}

      it 'returns correct types for general schema and specific union' do
        expected_result = {
          # When using Query#resolve_type
          "allAnimal" => [
            { "type" => "Cow", "cowName" => "Billy" },
            { "type" => "Goat", "goatName" => "Gilly" }
          ],

          # When using UnionType#resolve_type
          "allAnimalAsCow" => [
            { "type" => "Cow", "name" => "Billy" },
            { "type" => "Cow", "name" => "Gilly" }
          ]
        }
        assert_equal expected_result, result["data"]
      end
    end

    describe "typecasting from union to union" do
      let(:result) { Dummy::Schema.execute(query_string) }
      let(:query_string) {%|
        {
          allDairy {
            dairyName: __typename
            ... on Beverage {
              bevName: __typename
              ... on Milk {
                flavors
              }
            }
          }
        }
      |}

      it "casts if the object belongs to both unions" do
        expected_result = [
          {"dairyName"=>"Cheese"},
          {"dairyName"=>"Cheese"},
          {"dairyName"=>"Cheese"},
          {"dairyName"=>"Milk", "bevName"=>"Milk", "flavors"=>["Natural", "Chocolate", "Strawberry"]},
        ]
        assert_equal expected_result, result["data"]["allDairy"]
      end
    end

    describe "list of union type" do
      describe "fragment spreads" do
        let(:result) { Dummy::Schema.execute(query_string) }
        let(:query_string) {%|
          {
            allDairy {
              __typename
              ... milkFields
              ... cheeseFields
            }
          }
          fragment milkFields on Milk {
            id
            source
            origin
            flavors
          }

          fragment cheeseFields on Cheese {
            id
            source
            origin
            flavor
          }
        |}

        it "resolves the right fragment on the right item" do
          all_dairy = result["data"]["allDairy"]
          cheeses = all_dairy.first(3)
          cheeses.each do |cheese|
            assert_equal "Cheese", cheese["__typename"]
            assert_equal ["__typename", "id", "source", "origin", "flavor"], cheese.keys
          end

          milks = all_dairy.last(1)
          milks.each do |milk|
            assert_equal "Milk", milk["__typename"]
            assert_equal ["__typename", "id", "source", "origin", "flavors"], milk.keys
          end
        end
      end
    end
  end

  describe "use with loads:" do
    class UnionLoadsSchema < GraphQL::Schema
      class Image < GraphQL::Schema::Object
        field :title, String
      end

      class Video < GraphQL::Schema::Object
        field :title, String
      end

      class Post < GraphQL::Schema::Object
        field :title, String
      end

      class MediaItem < GraphQL::Schema::Union
        possible_types Image, Video
      end

      class Query < GraphQL::Schema::Object
        field :media_item_type, String do
          argument :id, ID, loads: MediaItem, as: :media_item
        end

        def media_item_type(media_item:)
          media_item[:type]
        end
      end

      query(Query)

      def self.object_from_id(id, ctx)
        type, title = id.split("/")
        { type: type, title: title }
      end

      def self.resolve_type(abs_type, obj, ctx)
        UnionLoadsSchema.const_get(obj[:type])
      end
    end

    it "restricts to members of the union" do
      query_str = "query($mediaId: ID!) { mediaItemType(id: $mediaId) }"
      res = UnionLoadsSchema.execute(query_str, variables: { mediaId: "Image/Family Photo" })
      assert_equal "Image", res["data"]["mediaItemType"]

      res = UnionLoadsSchema.execute(query_str, variables: { mediaId: "Video/Christmas Pageant" })
      assert_equal "Video", res["data"]["mediaItemType"]

      res = UnionLoadsSchema.execute(query_str, variables: { mediaId: "Post/Year in Review" })
      assert_nil res["data"]["mediaItemType"]
      assert_equal ["No object found for `id: \"Post/Year in Review\"`"], res["errors"].map { |e| e["message"] }
    end
  end
end
