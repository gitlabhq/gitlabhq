# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Subscriptions::BroadcastAnalyzer do
  class BroadcastTestSchema < GraphQL::Schema
    LOG_OUTPUT = StringIO.new
    LOGGER = Logger.new(LOG_OUTPUT)
    LOGGER.formatter = ->(severity, time, progname, msg) { "#{severity}: #{msg}\n"}
    module Throwable
      include GraphQL::Schema::Interface
      field :weight, Integer, null: false
      field :too_heavy_for_viewer, Boolean, null: false, broadcastable: false
      field :split_broadcastable_test, Boolean, null: false
    end

    class BroadcastableConnection < GraphQL::Types::Relay::BaseConnection
      default_broadcastable(true)
    end

    class BroadcastableEdge < GraphQL::Types::Relay::BaseEdge
      default_broadcastable(true)
    end

    class Javelin < GraphQL::Schema::Object
      implements Throwable
      edge_type_class(BroadcastableEdge)
      connection_type_class(BroadcastableConnection)
      field :split_broadcastable_test, Boolean, null: false, broadcastable: false
      field :length, Integer, broadcastable: true
    end

    class Shot < GraphQL::Schema::Object
      implements Throwable
      field :viewer_can_put, Boolean, null: false, broadcastable: false
      field :diameter, Integer, broadcastable: true
    end

    class Query < GraphQL::Schema::Object
      field :throwable, Throwable
    end

    class Mutation < GraphQL::Schema::Object
      field :noop, String
    end

    class Subscription < GraphQL::Schema::Object
      class ThrowableWasThrown < GraphQL::Schema::Subscription
        field :throwable, Throwable, null: false
        field :viewer, String, null: false, broadcastable: false
      end

      field :throwable_was_thrown, subscription: ThrowableWasThrown

      class NewMaxThrowRecord < GraphQL::Schema::Subscription
        field :distance, Integer, null: false, broadcastable: true
      end

      field :new_max_throw_record, subscription: NewMaxThrowRecord, broadcastable: true

      class NewJavelin < GraphQL::Schema::Subscription
        field :javelins, Javelin.connection_type, broadcastable: true
        field :shots, Shot.connection_type, broadcastable: true
      end

      field :new_javelin, subscription: NewJavelin, broadcastable: true
    end

    query(Query)
    mutation(Mutation)
    subscription(Subscription)
    orphan_types(Shot, Javelin)
    use GraphQL::Subscriptions, broadcast: true, default_broadcastable: true
    default_logger(LOGGER)
  end

  # Inheritance doesn't quite work, because the query analyzer is carried over.
  class BroadcastTestDefaultFalseSchema < GraphQL::Schema
    query(BroadcastTestSchema::Query)
    mutation(BroadcastTestSchema::Mutation)
    subscription(BroadcastTestSchema::Subscription)
    orphan_types(BroadcastTestSchema::Shot, BroadcastTestSchema::Javelin)
    use GraphQL::Subscriptions, broadcast: true, default_broadcastable: false
    default_logger(BroadcastTestSchema::LOGGER)
  end

  def broadcastable?(query_str, schema: BroadcastTestSchema)
    schema.subscriptions.broadcastable?(query_str)
  end

  before do
    BroadcastTestSchema::LOG_OUTPUT.rewind
    BroadcastTestSchema::LOG_OUTPUT.string.clear
  end

  it "doesn't run for non-subscriptions" do
    assert_nil broadcastable?("{ __typename }")
    assert_nil broadcastable?("mutation { __typename }")
    assert_equal true, broadcastable?("subscription { __typename }")
  end

  describe "when the default is false" do
    it "applies default false when any field is not tagged" do
      assert_equal false, broadcastable?("subscription { throwableWasThrown { throwable { weight } } }", schema: BroadcastTestDefaultFalseSchema)
    end

    it "returns true when all fields are tagged true" do
      assert_equal true, broadcastable?("subscription { newMaxThrowRecord { distance } }", schema: BroadcastTestDefaultFalseSchema)
    end

    it "treats introspection fields as broadcastable" do
      assert_equal true, broadcastable?("subscription { __typename }", schema: BroadcastTestDefaultFalseSchema)
    end
  end

  describe "when the default is true" do
    it "returns false when any field is tagged false" do
      assert_equal false, broadcastable?("subscription { throwableWasThrown { viewer } }")
      assert_equal false, broadcastable?("subscription { throwableWasThrown { throwable { ... on Shot { viewerCanPut } } } }")
    end

    it "returns true no field is tagged false" do
      assert_equal true, broadcastable?("subscription { throwableWasThrown { throwable { weight } } }")
    end
  end

  describe "nodes field" do
    it "can be broadcastable" do
      query_str = "subscription { newJavelin { javelins { nodes { length } edges { node { length } } pageInfo { hasNextPage } } } }"
      assert broadcastable?(query_str)
      assert broadcastable?(query_str, schema: BroadcastTestDefaultFalseSchema)
    end

    it "follows the default schema setting" do
      query_str = "subscription { newJavelin { shots { nodes { diameter } edges { node { diameter } } pageInfo { hasNextPage } } } }"
      assert broadcastable?(query_str)
      assert_equal BroadcastTestSchema.default_logger, BroadcastTestDefaultFalseSchema.default_logger
      BroadcastTestSchema::LOG_OUTPUT.string.clear
      BroadcastTestSchema::LOG_OUTPUT.rewind
      refute broadcastable?(query_str, schema: BroadcastTestDefaultFalseSchema)
      assert_equal "DEBUG: `broadcastable: nil` for field: ShotConnection.nodes\n", BroadcastTestSchema::LOG_OUTPUT.string
    end
  end

  describe "abstract types" do
    describe "when a field returns an interface" do
      it "observes the interface-defined configuration" do
        assert_equal false, broadcastable?("subscription { throwableWasThrown { throwable { tooHeavyForViewer } } }")
      end

      it "requires all object type fields to be broadcastable" do
        query_str = <<-GRAPHQL
        subscription {
          throwableWasThrown {
            throwable {
              # this is configured `false` for Javelin
              splitBroadcastableTest
            }
          }
        }
        GRAPHQL
        assert_equal false, broadcastable?(query_str)
      end

      it "is ok if all explicitly-named object fields are broadcastable" do
        query_str = <<-GRAPHQL
        subscription {
          throwableWasThrown {
            throwable {
              # Although this is false on Javelin, it's not overridden on Shot,
              # so it should use the default of `true`
              ...on Shot {
                splitBroadcastableTest
              }
            }
          }
        }
        GRAPHQL
        assert_equal true, broadcastable?(query_str)
      end

      it "is false if any explicitly-named object fields are broadcastable" do
        query_str = <<-GRAPHQL
        subscription {
          throwableWasThrown {
            throwable {
              ...on Shot {
                splitBroadcastableTest
              }
              ... on Javelin {
                # Explicitly-named Javelin has it configured `false`
                splitBroadcastableTest
              }
            }
          }
        }
        GRAPHQL
        assert_equal false, broadcastable?(query_str)
      end
    end
  end
end
