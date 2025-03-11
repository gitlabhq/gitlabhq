# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Dataloader::AsyncDataloader do
  class RailsAsyncSchema < GraphQL::Schema
    class CustomAsyncDataloader < GraphQL::Dataloader::AsyncDataloader
      def cleanup_fiber
      end

      def get_fiber_variables
        vars = super
        vars[:connected_to] = {
          role: StarWars::StarWarsModel.current_role,
          shard: StarWars::StarWarsModel.current_shard,
          prevent_writes: StarWars::StarWarsModel.current_preventing_writes
        }
        vars
      end

      def set_fiber_variables(vars)
        connection_config = vars.delete(:connected_to)
        StarWars::StarWarsModel.connecting_to(**connection_config)
        super(vars)
      end
    end

    class BaseSource < GraphQL::Dataloader::Source
      def fetch(ids)
        bases = StarWars::Base.where(id: ids)
        ids.map { |id| bases.find { |b| b.id == id } }
      end
    end

    class SelfSource < GraphQL::Dataloader::Source
      def fetch(ids)
        ids
      end
    end

    class Query < GraphQL::Schema::Object
      field :base_name, String do
        argument :id, Int
      end

      def base_name(id:)
        base = dataloader.with(BaseSource).load(id)
        base&.name
      end

      field :query, Query

      field :inline_base_name, String do
        argument :id, Int
      end

      def inline_base_name(id:)
        StarWars::Base.where(id: id).first&.name
      end

      def query
        dataloader.with(SelfSource).load(:query)
      end

      field :role, String

      def role
        StarWars::StarWarsModel.current_role.to_s
      end
    end

    query(Query)
    use CustomAsyncDataloader
  end

  before {
    skip("Only test when isolation_level = :fiber") unless ENV["ISOLATION_LEVEL_FIBER"]
  }

  it "cleans up database connections" do
    starting_connections = ActiveRecord::Base.connection_pool.connections.size
    query_str = "{
      b1: baseName(id: 1) b2: baseName(id: 2)
      ib1: inlineBaseName(id: 1)
      query {
        b3: baseName(id: 3)
        query {
          b4: baseName(id: 4)
          ib2: inlineBaseName(id: 2)
        }
      }
    }"
    res = RailsAsyncSchema.execute(query_str)
    assert_equal({
      "b1" => "Yavin", "b2" => "Echo Base", "ib1" => "Yavin",
      "query" => {
        "b3" => "Secret Hideout",
        "query" => { "b4" => "Death Star", "ib2" => "Echo Base" }
      }
    }, res["data"])

    RailsAsyncSchema.execute(query_str)
    RailsAsyncSchema.execute(query_str)

    ending_connections = ActiveRecord::Base.connection_pool.connections.size
    retained_connections = ending_connections - starting_connections
    assert_equal 0, retained_connections, "No connections are retained by GraphQL"
  end

  it "uses the `connected_to` role" do
    query_str = "{ role query { role } }"
    result = StarWars::StarWarsModel.connected_to(role: :reading) do
      RailsAsyncSchema.execute(query_str)
    end
    expected_res = { "role" => "reading", "query" => { "role" => "reading" }}
    assert_equal expected_res, result["data"]
  end
end
