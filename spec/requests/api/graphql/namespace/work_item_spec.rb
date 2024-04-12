# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a single work item associated with a group', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:guest) { create(:user, guest_of: group) }
  let_it_be(:reporter) { create(:user, reporter_of: group) }

  let(:work_item_data) { graphql_data.dig('namespace', 'workItem') }
  let(:params) { { iid: query_work_item.iid.to_s } }
  let(:query) do
    graphql_query_for(
      'namespace',
      { 'fullPath' => full_path },
      query_graphql_field('workItem', params, all_graphql_fields_for('workItems'.classify, max_depth: 2))
    )
  end

  RSpec.shared_examples 'identifies work item at namespace level' do
    context 'when the user cannot read the work item' do
      let(:current_user) { guest }
      let(:query_work_item) { confidential_work_item }

      it 'returns does not return the work item' do
        post_graphql(query, current_user: current_user)

        expect(work_item_data).to be_nil
      end
    end

    context 'when the user can read the work item' do
      it 'returns the work item' do
        post_graphql(query, current_user: current_user)

        expect(work_item_data).to include(
          'id' => query_work_item.to_gid.to_s,
          'iid' => query_work_item.iid.to_s
        )
      end
    end
  end

  context 'when namespace is a group' do
    let_it_be(:group_work_item) { create(:work_item, :group_level, namespace: group, author: reporter) }
    let_it_be(:confidential_work_item) { create(:work_item, :confidential, namespace: group, author: reporter) }

    let(:query_work_item) { group_work_item }
    let(:full_path) { group.full_path }
    let(:current_user) { reporter }

    it_behaves_like 'identifies work item at namespace level'

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

  context 'when namespace is a project' do
    let_it_be(:project_work_item) { create(:work_item, project: project, author: reporter) }
    let_it_be(:confidential_work_item) { create(:work_item, :confidential, project: project, author: reporter) }

    let(:query_work_item) { project_work_item }
    let(:full_path) { project.full_path }
    let(:current_user) { reporter }

    it_behaves_like 'identifies work item at namespace level'
  end
end
