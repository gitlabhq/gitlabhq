# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group custom attributes', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:custom_attribute) do
    create(:group_custom_attribute, group: group, key: 'department', value: 'engineering')
  end

  let(:query) do
    graphql_query_for(
      :group,
      { full_path: group.full_path },
      'customAttributes { key value }'
    )
  end

  context 'when user is not an admin' do
    before_all do
      group.add_owner(user)
    end

    it 'returns null for custom attributes' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(:group, :customAttributes)).to be_nil
    end
  end

  context 'when user is an admin', :enable_admin_mode do
    it 'returns custom attributes' do
      post_graphql(query, current_user: admin)

      expect(graphql_data_at(:group, :customAttributes)).to contain_exactly(
        a_hash_including('key' => 'department', 'value' => 'engineering')
      )
    end
  end

  context 'when group has no custom attributes' do
    let_it_be(:empty_group) { create(:group) }

    let(:query) do
      graphql_query_for(
        :group,
        { full_path: empty_group.full_path },
        'customAttributes { key value }'
      )
    end

    it 'returns empty array', :enable_admin_mode do
      post_graphql(query, current_user: admin)

      expect(graphql_data_at(:group, :customAttributes)).to eq([])
    end
  end
end
