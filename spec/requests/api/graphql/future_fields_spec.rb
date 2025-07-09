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
        post_graphql(query, current_user: current_user)

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
end
