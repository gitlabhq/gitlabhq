# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Future fields', feature_category: :shared do
  include GraphqlHelpers
  include VersionMilestoneHelpers

  let_it_be(:current_user) { create(:user) }

  shared_examples 'future fields on graphql' do
    context 'when the field was introduced in a past milestone' do
      let(:version) { previous_milestone(Gitlab.version_info).to_s }

      it 'returns an error' do
        post_graphql(query, current_user: current_user)

        expect_graphql_errors_to_include(
          "Field 'futureField' doesn't exist on type 'Query'"
        )
      end
    end

    context 'when the field was introduced in the current milestone' do
      let(:version) { Gitlab.version_info.to_s }

      it 'returns null as a fallback value' do
        expect_next_instance_of(Types::QueryType) do |instance|
          expect(instance).not_to receive(:futureField)
        end

        post_graphql(query, current_user: current_user)

        expect(graphql_data).to have_key('futureField')
        expect(graphql_data['futureField']).to be_nil
      end
    end

    context 'when the field was introduced in a future milestone' do
      let(:version) do
        current = Gitlab.version_info
        Gitlab::VersionInfo
          .new(current.major, current.minor + 1, 0)
          .to_s
      end

      it 'returns null as a fallback value' do
        expect_next_instance_of(Types::QueryType) do |instance|
          expect(instance).not_to receive(:futureField)
        end

        post_graphql(query, current_user: current_user)

        expect(graphql_data).to have_key('futureField')
        expect(graphql_data['futureField']).to be_nil
      end
    end
  end

  context 'when using directive on a future field' do
    let(:query) do
      format(<<~GRAPHQL, version: version)
      query fetchData {
        __typename
        futureField @gl_introduced(version: "%{version}")
      }
      GRAPHQL
    end

    it_behaves_like 'future fields on graphql'
  end

  context 'when using directive on a future object' do
    let(:query) do
      format(<<~GRAPHQL, version: version)
      query fetchData {
        __typename
        futureField @gl_introduced(version: "%{version}") {
          id
        }
      }
      GRAPHQL
    end

    it_behaves_like 'future fields on graphql'
  end

  context 'when using directive on a fragment with future field' do
    let(:query) do
      format(<<~GRAPHQL, version: version)
      fragment fragmentWithFutureField on Query {
        futureField @gl_introduced(version: "%{version}")
      }

      query fetchData {
        ... fragmentWithFutureField
      }
      GRAPHQL
    end

    it_behaves_like 'future fields on graphql'
  end

  context 'when the tagged field exists in the schema' do
    let(:query) do
      format(<<~GRAPHQL, version: Gitlab.version_info.to_s)
      query fetchData {
        __typename
        echo(text: "Hello") @gl_introduced(version: "%{version}")
      }
      GRAPHQL
    end

    it 'resolves the field normally' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['echo']).to eq("#{current_user.username.inspect} says: Hello")
    end
  end

  context 'when the query also contains an untagged missing field' do
    let(:query) do
      format(<<~GRAPHQL, version: Gitlab.version_info.to_s)
      query fetchData {
        __typename
        futureField @gl_introduced(version: "%{version}")
        typoField
      }
      GRAPHQL
    end

    it 'returns an error for the untagged field' do
      post_graphql(query, current_user: current_user)

      expect_graphql_errors_to_include(
        "Field 'typoField' doesn't exist on type 'Query'"
      )
    end
  end

  context 'when using directive on an inline fragment' do
    let(:query) do
      format(<<~GRAPHQL, version: Gitlab.version_info.to_s)
      query fetchData {
        __typename
        ... on Query @gl_introduced(version: "%{version}") {
          futureField
        }
      }
      GRAPHQL
    end

    it 'returns null for the missing fields inside it' do
      post_graphql(query, current_user: current_user)

      expect(graphql_errors).to be_blank
      expect(graphql_data['futureField']).to be_nil
    end
  end

  context 'when the tagged field exists and has a subtree' do
    let(:query) do
      format(<<~GRAPHQL, version: Gitlab.version_info.to_s)
      query fetchData {
        currentUser @gl_introduced(version: "%{version}") {
          username
        }
      }
      GRAPHQL
    end

    it 'resolves the subtree normally' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data.dig('currentUser', 'username')).to eq(current_user.username)
    end
  end

  context 'when the version argument is not a string' do
    let(:query) do
      <<~GRAPHQL
      query fetchData {
        __typename
        futureField @gl_introduced(version: 123)
      }
      GRAPHQL
    end

    it 'returns a validation error instead of crashing' do
      post_graphql(query, current_user: current_user)

      expect(graphql_errors).to be_present
    end
  end

  describe 'query analysis' do
    it 'counts tagged existing fields toward depth limits' do
      query = format(<<~GRAPHQL, version: Gitlab.version_info.to_s)
      query fetchData {
        currentUser @gl_introduced(version: "%{version}") {
          groups {
            nodes {
              id
            }
          }
        }
      }
      GRAPHQL

      result = GitlabSchema.execute(query, context: { current_user: current_user }, max_depth: 3)

      expect(result['errors'].pluck('message')).to include(a_string_matching(/exceeds max depth/))
    end

    it 'analyzes a missing tagged field with a subtree without errors' do
      query = format(<<~GRAPHQL, version: Gitlab.version_info.to_s)
      query fetchData {
        __typename
        futureField @gl_introduced(version: "%{version}") {
          childField {
            grandchildField
          }
        }
      }
      GRAPHQL

      result = GitlabSchema.execute(query, context: { current_user: current_user }, max_depth: 10)

      expect(result['errors']).to be_nil
      expect(result['data']['futureField']).to be_nil
    end
  end

  context 'when a fragment is spread only inside a tagged missing subtree' do
    let(:query) do
      format(<<~GRAPHQL, version: Gitlab.version_info.to_s)
      query fetchData {
        __typename
        futureField @gl_introduced(version: "%{version}") {
          ...userFields
        }
      }

      fragment userFields on User {
        username
      }
      GRAPHQL
    end

    it 'returns null without unused-fragment errors' do
      post_graphql(query, current_user: current_user)

      expect(graphql_errors).to be_blank
      expect(graphql_data['futureField']).to be_nil
    end
  end

  context 'when a variable is used only inside a tagged missing field' do
    let(:query) do
      format(<<~GRAPHQL, version: Gitlab.version_info.to_s)
      query fetchData($text: String!) {
        __typename
        futureField(text: $text) @gl_introduced(version: "%{version}")
      }
      GRAPHQL
    end

    it 'returns null without unused-variable errors' do
      post_graphql(query, current_user: current_user, variables: { text: 'Hello' })

      expect(graphql_errors).to be_blank
      expect(graphql_data['futureField']).to be_nil
    end
  end

  context 'when the tagged missing field is the only selection' do
    let(:query) do
      format(<<~GRAPHQL, version: Gitlab.version_info.to_s)
      query fetchData {
        futureField @gl_introduced(version: "%{version}")
      }
      GRAPHQL
    end

    it 'returns null' do
      post_graphql(query, current_user: current_user)

      expect(graphql_errors).to be_blank
      expect(graphql_data['futureField']).to be_nil
    end
  end

  context 'with multiplexed queries' do
    let(:version) do
      current = Gitlab.version_info
      Gitlab::VersionInfo
        .new(current.major, current.minor, current.patch + 1)
        .to_s
    end

    let(:future_field_query) do
      format(<<~GRAPHQL, version: version)
      query fetchData {
        __typename
        futureField @gl_introduced(version: "%{version}")
      }
      GRAPHQL
    end

    let(:regular_query) do
      <<~GRAPHQL
      query working($text: String!) {
        echo(text: $text)
      }
      GRAPHQL
    end

    it 'executes each query with its own document' do
      queries = [
        { query: future_field_query },
        { query: regular_query, variables: { 'text' => 'Hello' } }
      ]

      post_multiplex(queries, current_user: current_user)

      future_field_response = json_response.first['data']
      regular_response = json_response.last['data']

      expect(future_field_response).to have_key('futureField')
      expect(future_field_response['futureField']).to be_nil
      expect(regular_response['echo']).to eq("#{current_user.username.inspect} says: Hello")
    end
  end
end
