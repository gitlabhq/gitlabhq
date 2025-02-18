# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciVariables', feature_category: :ci_variables do
  include GraphqlHelpers

  let(:query) do
    %(
      query {
        ciVariables {
          nodes {
            id
            key
            description
            value
            variableType
            protected
            masked
            raw
            environmentScope
          }
        }
      }
    )
  end

  context 'when the user is an admin' do
    let_it_be(:user) { create(:admin) }

    it "returns the instance's CI variables" do
      variable = create(
        :ci_instance_variable,
        key: 'TEST_VAR',
        value: 'test',
        masked: false,
        protected: true,
        raw: true
      )

      post_graphql(query, current_user: user)

      expect(graphql_data.dig('ciVariables', 'nodes')).to contain_exactly({
        'id' => variable.to_global_id.to_s,
        'key' => 'TEST_VAR',
        'description' => nil,
        'value' => 'test',
        'variableType' => 'ENV_VAR',
        'masked' => false,
        'protected' => true,
        'raw' => true,
        'environmentScope' => nil
      })
    end
  end

  context 'when the user is not an admin' do
    let_it_be(:user) { create(:user) }

    it 'returns nothing' do
      create(:ci_instance_variable, value: 'verysecret', masked: true)

      post_graphql(query, current_user: user)

      expect(graphql_data['ciVariables']).to be_nil
    end
  end

  context 'when the user is unauthenticated' do
    let_it_be(:user) { nil }

    it 'returns nothing' do
      create(:ci_instance_variable, value: 'verysecret', masked: true)

      post_graphql(query, current_user: user)

      expect(graphql_data['ciVariables']).to be_nil
    end
  end

  describe 'sorting and pagination' do
    let_it_be(:current_user) { create(:admin) }
    let_it_be(:data_path) { [:ci_variables] }
    let_it_be(:variables) do
      [
        create(:ci_instance_variable, key: 'd'),
        create(:ci_instance_variable, key: 'a'),
        create(:ci_instance_variable, key: 'c'),
        create(:ci_instance_variable, key: 'e'),
        create(:ci_instance_variable, key: 'b')
      ]
    end

    def pagination_query(params)
      graphql_query_for(
        :ci_variables,
        params,
        "#{page_info} nodes { id }"
      )
    end

    it_behaves_like 'sorted paginated variables'
  end
end
