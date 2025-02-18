# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.group(fullPath).ciVariables', feature_category: :ci_variables do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:query) do
    %(
      query {
        group(fullPath: "#{group.full_path}") {
          ciVariables {
            limit
            nodes {
              id
              key
              value
              variableType
              protected
              hidden
              masked
              raw
              environmentScope
            }
          }
        }
      }
    )
  end

  context 'when the user can administer the group' do
    before do
      group.add_owner(user)
    end

    it "returns the group's CI variables" do
      variable = create(:ci_group_variable,
        group: group,
        key: 'TEST_VAR',
        value: 'test',
        masked: false,
        protected: true,
        raw: true,
        environment_scope: 'staging')

      post_graphql(query, current_user: user)

      expect(graphql_data.dig('group', 'ciVariables', 'limit')).to be(30000)
      expect(graphql_data.dig('group', 'ciVariables', 'nodes')).to contain_exactly({
        'id' => variable.to_global_id.to_s,
        'key' => 'TEST_VAR',
        'value' => 'test',
        'variableType' => 'ENV_VAR',
        'masked' => false,
        'protected' => true,
        'hidden' => false,
        'raw' => true,
        'environmentScope' => 'staging'
      })
    end

    it "sets the value to null if the variable is hidden" do
      variable = create(:ci_group_variable,
        group: group,
        key: 'TEST_VAR',
        value: 'TestValue',
        masked: true,
        hidden: true,
        protected: true,
        raw: false,
        environment_scope: 'staging')

      post_graphql(query, current_user: user)

      expect(graphql_data.dig('group', 'ciVariables', 'limit')).to be(30000)
      expect(graphql_data.dig('group', 'ciVariables', 'nodes')).to contain_exactly({
        'id' => variable.to_global_id.to_s,
        'key' => 'TEST_VAR',
        'value' => nil,
        'variableType' => 'ENV_VAR',
        'masked' => true,
        'protected' => true,
        'hidden' => true,
        'raw' => false,
        'environmentScope' => 'staging'
      })
    end
  end

  context 'when the user cannot administer the group' do
    it 'returns nothing' do
      create(:ci_group_variable, group: group, value: 'verysecret', masked: true)

      group.add_developer(user)

      post_graphql(query, current_user: user)

      expect(graphql_data.dig('group', 'ciVariables')).to be_nil
    end
  end

  describe 'sorting and pagination' do
    let_it_be(:current_user) { user }
    let_it_be(:data_path) { [:group, :ci_variables] }
    let_it_be(:variables) do
      [
        create(:ci_group_variable, group: group, key: 'd'),
        create(:ci_group_variable, group: group, key: 'a'),
        create(:ci_group_variable, group: group, key: 'c'),
        create(:ci_group_variable, group: group, key: 'e'),
        create(:ci_group_variable, group: group, key: 'b')
      ]
    end

    def pagination_query(params)
      graphql_query_for(
        :group,
        { fullPath: group.full_path },
        query_graphql_field('ciVariables', params, "#{page_info} nodes { id }")
      )
    end

    before do
      group.add_owner(current_user)
    end

    it_behaves_like 'sorted paginated variables'
  end
end
