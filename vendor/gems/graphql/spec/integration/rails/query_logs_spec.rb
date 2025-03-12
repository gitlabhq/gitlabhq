# frozen_string_literal: true
require "spec_helper"

describe "Integration with ActiveRecord::QueryLogs" do
  class QueryLogSchema < GraphQL::Schema
    class Thing < ActiveRecord::Base
      belongs_to :other_thing, class_name: "Thing"
    end

    class ThingSource < GraphQL::Dataloader::Source
      def fetch(ids)
        things = Thing.where(id: ids)
        ids.map { |id| things.find { |t| t.id == id } }
      end
    end

    class OtherThingSource < GraphQL::Dataloader::Source
      def fetch(ids)
        things = dataloader.with(ThingSource).load_all(ids).compact
        ot_ids = things.map(&:other_thing_id).compact
        ots = Thing.where(id: ot_ids).compact
        ids.map { |tid|
          if (thing = things.find { |t| t.id == tid })
            ots.find { |ot| ot.id == thing.other_thing_id }
          end
        }
      end
    end

    class ThingType < GraphQL::Schema::Object
      field :name, String
      field :other_thing, self
    end

    class Query < GraphQL::Schema::Object
      field :some_thing, ThingType

      def some_thing
        Thing.find(2)
      end

      field :thing, ThingType do
        argument :id, ID
      end

      def thing(id:)
        dataloader.with(ThingSource).load(id.to_i)
      end

      field :other_thing, ThingType do
        argument :thing_id, ID
      end

      def other_thing(thing_id:)
        dataloader.with(OtherThingSource).load(thing_id.to_i)
      end
    end

    query(Query)
    use GraphQL::Dataloader
  end

  t1 = QueryLogSchema::Thing.create!(name: "Fork")
  QueryLogSchema::Thing.create!(name: "Spoon", other_thing: t1)
  QueryLogSchema::Thing.create!(name: "Knife")

  before do
    @prev_tags = ActiveRecord::QueryLogs.tags
    ActiveRecord.query_transformers << ActiveRecord::QueryLogs
    ActiveRecord::QueryLogs.tags = [{
      current_graphql_operation: -> { GraphQL::Current.operation_name },
      current_graphql_field: -> { GraphQL::Current.field&.path },
      current_dataloader_source: -> { GraphQL::Current.dataloader_source_class },
    }]
  end

  after do
    ActiveRecord::QueryLogs.tags = @prev_tags
    ActiveRecord.query_transformers.delete(ActiveRecord::QueryLogs)
  end

  def exec_query(str)
    QueryLogSchema.execute(str)
  end

  it "includes operation_name and field_name when configured" do
    res = nil
    log = with_active_record_log(colorize: false) do
      res = exec_query("query OtherThingName { someThing { otherThing { name } } }")
    end
    assert_equal "Fork", res["data"]["someThing"]["otherThing"]["name"]
    # These can appear in different orders in the SQL comment:
    assert_includes log, "current_graphql_operation:OtherThingName"
    assert_includes log, "current_graphql_field:Query.someThing"
    assert_includes log, "current_graphql_field:Thing.otherThing"
  end

  it "includes dataloader source when configured" do
    res = nil
    log = with_active_record_log(colorize: false) do
      res = exec_query("query GetThingNames { t1: thing(id: 1) { name } t2: thing(id: 2) { name } }")
    end
    assert_equal ["Fork", "Spoon"], [res["data"]["t1"]["name"], res["data"]["t2"]["name"]]
    assert_includes log, 'SELECT "things".* FROM "things" WHERE "things"."id" IN (?, ?) '
    assert_includes log, 'current_dataloader_source:QueryLogSchema::ThingSource'
    assert_includes log, 'current_graphql_operation:GetThingNames'
  end

  it "works for nested dataloader sources" do
    res = nil
    log = with_active_record_log(colorize: false) do
      res = exec_query("{ t1: otherThing(thingId: 1) { name } t2: otherThing(thingId: 2) { name } t5: otherThing(thingId: 5) { name } }")
    end

    assert_equal [nil, "Fork", nil], [res.dig("data", "t1", "name"), res.dig("data", "t2", "name"), res.dig("data", "t5")]
    assert_includes log, 'SELECT "things".* FROM "things" WHERE "things"."id" IN (?, ?, ?) /*current_dataloader_source:QueryLogSchema::ThingSource*/'
    assert_includes log, 'SELECT "things".* FROM "things" WHERE "things"."id" = ? /*current_dataloader_source:QueryLogSchema::OtherThingSource*/'
  end
end
