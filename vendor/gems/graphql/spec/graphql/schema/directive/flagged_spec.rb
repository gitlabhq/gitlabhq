# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Directive::Flagged do
  class FlaggedSchema < GraphQL::Schema
    use GraphQL::Schema::Warden if ADD_WARDEN
    module Animal
      include GraphQL::Schema::Interface
      if GraphQL::Schema.use_visibility_profile?
        # It won't check possible types, so it needs this directly
        directive GraphQL::Schema::Directive::Flagged, by: ["northPole", "southPole"]
      end
    end

    class PolarBear < GraphQL::Schema::Object
      implements Animal
      directive GraphQL::Schema::Directive::Flagged, by: ["northPole"]
      field :name, String, null: false
    end

    class Penguin < GraphQL::Schema::Object
      implements Animal
      directive GraphQL::Schema::Directive::Flagged, by: ["southPole"]
      field :name, String, null: false
    end

    class Query < GraphQL::Schema::Object
      field :animals, [Animal], null: false

      def animals
        [
          context[:flags].include?("southPole") ? { type: "Penguin", name: "King Dedede" } : nil,
          context[:flags].include?("northPole") ? { type: "PolarBear", name: "Iorek" } : nil,
        ].compact
      end

      field :antarctica, Boolean, null: false,
        directives: { GraphQL::Schema::Directive::Flagged => { by: ["southPole"] } }
      def antarctica; true; end

      field :santas_workshop, Boolean, null: false,
        directives: { GraphQL::Schema::Directive::Flagged => { by: ["northPole"] } }
      def santas_workshop; true; end

      field :something_not_flagged, String
    end

    query(Query)
    orphan_types(PolarBear, Penguin)

    def self.resolve_type(abs_type, obj, ctx)
      case obj[:type]
      when "Penguin"
        Penguin
      when "PolarBear"
        PolarBear
      else
        raise "Unknown: #{obj}"
      end
    end
  end

  def exec_query(str, context: {})
    FlaggedSchema.execute(str, context: context)
  end

  def error_messages(res)
    res["errors"].map { |e| e["message"] }
  end

  it "hides fields when the required flags are not present" do
    res = exec_query("{ __typename }")
    assert_equal "Query", res["data"]["__typename"]

    res = exec_query("{ antarctica }")
    assert_equal ["Field 'antarctica' doesn't exist on type 'Query'"], error_messages(res)

    res = exec_query("{ antarctica }", context: { flags: ["southPole"] })
    assert_equal true, res["data"]["antarctica"]

    res = exec_query("{ antarctica santasWorkshop }", context: { flags: ["southPole"] })
    assert_equal ["Field 'santasWorkshop' doesn't exist on type 'Query'"], error_messages(res)

    res = exec_query("{ antarctica santasWorkshop }", context: { flags: ["southPole", "northPole"] })
    assert_equal true, res["data"]["antarctica"]
    assert_equal true, res["data"]["santasWorkshop"]
  end

  it "hides types when the required flags are not present" do
    res = exec_query("{ animals { __typename } }")
    assert_equal ["Field 'animals' doesn't exist on type 'Query'"], error_messages(res), "All implementers are hidden"

    res = exec_query("{ animals { ... on Penguin { name } } }", context: { flags: ["southPole"] })
    assert_equal ["King Dedede"], res["data"]["animals"].map { |a| a["name"] }

    res = exec_query("{ animals { ... on Penguin { name } ... on PolarBear { name }} }", context: { flags: ["southPole"] })
    assert_equal ["No such type PolarBear, so it can't be a fragment condition"], error_messages(res)

    res = exec_query("{ animals { ... on Penguin { name } ... on PolarBear { name }} }", context: { flags: ["southPole", "northPole"] })
    assert_equal ["King Dedede", "Iorek"], res["data"]["animals"].map { |a| a["name"] }
  end
end
