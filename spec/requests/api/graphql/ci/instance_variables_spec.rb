# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciVariables', feature_category: :pipeline_authoring do
  include GraphqlHelpers

  let(:query) do
    %(
      query {
        ciVariables {
          nodes {
            id
            key
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
      variable = create(:ci_instance_variable, key: 'TEST_VAR', value: 'test',
                                               masked: false, protected: true, raw: true)

      post_graphql(query, current_user: user)

      expect(graphql_data.dig('ciVariables', 'nodes')).to contain_exactly({
        'id' => variable.to_global_id.to_s,
        'key' => 'TEST_VAR',
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

      expect(graphql_data.dig('ciVariables')).to be_nil
    end
  end

  context 'when the user is unauthenticated' do
    let_it_be(:user) { nil }

    it 'returns nothing' do
      create(:ci_instance_variable, value: 'verysecret', masked: true)

      post_graphql(query, current_user: user)

      expect(graphql_data.dig('ciVariables')).to be_nil
    end
  end
end
