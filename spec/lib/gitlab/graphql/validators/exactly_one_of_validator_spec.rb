# frozen_string_literal: true

require 'fast_spec_helper'
require 'graphql'

RSpec.describe Gitlab::Graphql::Validators::ExactlyOneOfValidator, feature_category: :integrations do
  let(:schema) do
    Class.new(GraphQL::Schema) do
      query(Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'

        field :find_user, GraphQL::Types::String, null: true do
          argument :username, GraphQL::Types::String, required: false
          argument :user_id, GraphQL::Types::String, required: false

          validates({ Gitlab::Graphql::Validators::ExactlyOneOfValidator => [:username, :user_id] })
        end

        def find_user(**args)
          args[:username] || args[:user_id]
        end
      end)
    end
  end

  def execute_query(query)
    GraphQL::Query.new(schema, document: GraphQL.parse(query)).result
  end

  it 'raises an error when both arguments are provided' do
    query = <<-GRAPHQL
      query {
        findUser(username: "user1", userId: "1")
      }
    GRAPHQL

    result = execute_query(query)

    expect(result['errors']).to include(
      a_hash_including('message' => 'One and only one of [username, userId] arguments is required.')
    )
  end

  it 'does not raise an error when only one argument is provided' do
    query = <<-GRAPHQL
      query {
        findUser(username: "user1")
      }
    GRAPHQL

    result = execute_query(query)

    expect(result.dig('data', 'findUser')).to eq('user1')
  end

  it 'raises an error when no argument is provided' do
    query = <<-GRAPHQL
      query {
        findUser
      }
    GRAPHQL

    result = execute_query(query)

    expect(result['errors']).to include(
      a_hash_including('message' => 'One and only one of [username, userId] arguments is required.')
    )
  end

  context 'when on an InputObject' do
    let(:schema) do
      Class.new(GraphQL::Schema) do
        query(Class.new(GraphQL::Schema::Object) do
          graphql_name 'Query'

          user_input = Class.new(GraphQL::Schema::InputObject) do
            graphql_name 'UserInput'

            argument :username, GraphQL::Types::String, required: false
            argument :user_id, GraphQL::Types::String, required: false

            validates({ Gitlab::Graphql::Validators::ExactlyOneOfValidator => [:username, :user_id] })
          end

          field :find_user, GraphQL::Types::String, null: true do
            argument :user, user_input, required: false
          end

          def find_user(**args)
            args.dig(:user, :username) || args.dig(:user, :user_id)
          end
        end)
      end
    end

    it 'raises an error when both arguments are provided' do
      query = <<-GRAPHQL
        query {
          findUser(user: { username: "user1", userId: "1" })
        }
      GRAPHQL

      result = execute_query(query)

      expect(result['errors']).to include(
        a_hash_including('message' => 'One and only one of [username, userId] arguments is required.')
      )
    end

    it 'does not raise an error when only one argument is provided' do
      query = <<-GRAPHQL
        query {
          findUser(user: { username: "user1" })
        }
      GRAPHQL

      result = execute_query(query)

      expect(result.dig('data', 'findUser')).to eq('user1')
    end

    it 'raises an error when no argument is provided' do
      query = <<-GRAPHQL
        query {
          findUser(user: { })
        }
      GRAPHQL

      result = execute_query(query)

      expect(result['errors']).to include(
        a_hash_including('message' => 'One and only one of [username, userId] arguments is required.')
      )
    end
  end
end
