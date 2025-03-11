# frozen_string_literal: true
module BatchLoading
  class GraphQLBatchSchema < GraphQL::Schema
    DATA = [
      { id: "1", name: "Bulls", player_ids: ["2", "3"] },
      { id: "2", name: "Michael Jordan", team_id: "1" },
      { id: "3", name: "Scottie Pippin", team_id: "1" },
      { id: "4", name: "Braves", player_ids: ["5", "6"] },
      { id: "5", name: "Chipper Jones", team_id: "4" },
      { id: "6", name: "Tom Glavine", team_id: "4" },
    ]

    class DataLoader < GraphQL::Batch::Loader
      def initialize(column: :id)
        @column = column
      end

      def perform(keys)
        keys.each do |key|
          record = DATA.find { |d| d[@column] == key }
          fulfill(key, record)
        end
      end
    end

    class Team < GraphQL::Schema::Object
      field :name, String, null: false
      field :players, "[BatchLoading::GraphQLBatchSchema::Player]", null: false

      def players
        DataLoader.load_many(object[:player_ids])
      end
    end

    class Player < GraphQL::Schema::Object
      field :name, String, null: false
      field :team, Team, null: false

      def team
        DataLoader.load(object[:team_id])
      end
    end

    class Query < GraphQL::Schema::Object
      field :team, Team do
        argument :name, String
      end

      def team(name:)
        DataLoader.for(column: :name).load(name)
      end
    end

    query(Query)
    use GraphQL::Batch
  end

  class GraphQLDataloaderSchema < GraphQL::Schema
    class DataSource < GraphQL::Dataloader::Source
      def initialize(options = {column: :id})
        @column = options[:column]
      end

      def fetch(keys)
        keys.map { |key|
          d = GraphQLBatchSchema::DATA.find { |d| d[@column] == key }
          # p [key, @column, d]
          d
        }
      end
    end

    class Team < GraphQL::Schema::Object
      field :name, String, null: false
      field :players, "[BatchLoading::GraphQLDataloaderSchema::Player]", null: false

      def players
        dataloader.with(DataSource).load_all(object[:player_ids])
      end
    end

    class Player < GraphQL::Schema::Object
      field :name, String, null: false
      field :team, Team, null: false

      def team
        dataloader.with(DataSource).load(object[:team_id])
      end
    end

    class Query < GraphQL::Schema::Object
      field :team, Team do
        argument :name, String
      end

      def team(name:)
        dataloader.with(DataSource, column: :name).load(name)
      end
    end

    query(Query)
    use GraphQL::Dataloader
  end

  class GraphQLNoBatchingSchema < GraphQL::Schema
    DATA = GraphQLBatchSchema::DATA

    class Team < GraphQL::Schema::Object
      field :name, String, null: false
      field :players, "[BatchLoading::GraphQLNoBatchingSchema::Player]", null: false

      def players
        object[:player_ids].map { |id| DATA.find { |d| d[:id] == id } }
      end
    end

    class Player < GraphQL::Schema::Object
      field :name, String, null: false
      field :team, Team, null: false

      def team
        DATA.find { |d| d[:id] == object[:team_id] }
      end
    end

    class Query < GraphQL::Schema::Object
      field :team, Team do
        argument :name, String
      end

      def team(name:)
        DATA.find { |d| d[:name] == name }
      end
    end

    query(Query)
  end
end
