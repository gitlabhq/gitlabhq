# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.group(fullPath).ciVariables' do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:query) do
    %(
      query {
        group(fullPath: "#{group.full_path}") {
          ciVariables {
            nodes {
              id
              key
              value
              variableType
              protected
              masked
              raw
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
      variable = create(:ci_group_variable, group: group, key: 'TEST_VAR', value: 'test',
                        masked: false, protected: true, raw: true)

      post_graphql(query, current_user: user)

      expect(graphql_data.dig('group', 'ciVariables', 'nodes')).to contain_exactly({
        'id' => variable.to_global_id.to_s,
        'key' => 'TEST_VAR',
        'value' => 'test',
        'variableType' => 'ENV_VAR',
        'masked' => false,
        'protected' => true,
        'raw' => true
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
end
