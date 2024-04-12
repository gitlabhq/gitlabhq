# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a single work item associated with a group', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:reporter) { create(:user, reporter_of: group) }

  let_it_be(:group_work_item) do
    create(
      :work_item,
      namespace: group,
      author: reporter
    )
  end

  let_it_be(:confidential_work_item) do
    create(:work_item, :confidential, namespace: group, author: reporter)
  end

  let(:work_item_data) { graphql_data.dig('group', 'workItem') }
  let(:query_group) { group }
  let(:query_work_item) { group_work_item }
  let(:params) { { iid: query_work_item.iid.to_s } }
  let(:query) do
    graphql_query_for(
      'group',
      { 'fullPath' => query_group.full_path },
      query_graphql_field('workItem', params, all_graphql_fields_for('workItems'.classify, max_depth: 2))
    )
  end

  context 'when the user cannot read the work item' do
    let(:current_user) { user }
    let(:query_work_item) { confidential_work_item }

    it 'returns does not return the work item' do
      post_graphql(query, current_user: current_user)

      expect(work_item_data).to be_nil
    end
  end

  context 'when the user can read the work item' do
    let(:current_user) { reporter }

    it 'returns the work item' do
      post_graphql(query, current_user: current_user)

      expect(work_item_data).to include(
        'id' => query_work_item.to_gid.to_s,
        'iid' => query_work_item.iid.to_s
      )
    end

    context 'when the namespace_level_work_items feature flag is disabled' do
      before do
        stub_feature_flags(namespace_level_work_items: false)
      end

      it 'does not return the work item' do
        post_graphql(query, current_user: current_user)

        expect(work_item_data).to be_nil
      end
    end
  end
end
