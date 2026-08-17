# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Future fields', feature_category: :shared do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  shared_examples 'future fields on graphql' do
    context 'when future field was deployed on the backend' do
      let(:version) { Gitlab.version_info.to_s }

      it 'returns an error' do
        post_graphql(query, current_user: current_user)

        expect_graphql_errors_to_include(
          "Field 'futureField' doesn't exist on type 'Query'"
        )
      end
    end

    context 'when future field was not deployed on the backend' do
      let(:version) do
        current = Gitlab.version_info
        Gitlab::VersionInfo
          .new(current.major, current.minor, current.patch + 1)
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
