# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a work_item list for a group', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:sub_group) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, :repository, :public, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:reporter) { create(:user, reporter_of: group) }

  let_it_be(:project_work_item) { create(:work_item, project: project) }
  let_it_be(:sub_group_work_item) do
    create(
      :work_item,
      namespace: sub_group,
      author: reporter
    )
  end

  let_it_be(:group_work_item) do
    create(
      :work_item,
      namespace: group,
      author: reporter,
      title: 'search_term'
    )
  end

  let_it_be(:confidential_work_item) do
    create(:work_item, :confidential, namespace: group, author: reporter)
  end

  let_it_be(:other_work_item) { create(:work_item) }

  let(:work_items_data) { graphql_data['group']['workItems']['nodes'] }
  let(:item_filter_params) { {} }
  let(:current_user) { user }
  let(:query_group) { group }

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('workItems'.classify, max_depth: 2)}
      }
    QUERY
  end

  it_behaves_like 'graphql work item list request spec' do
    let_it_be(:container_build_params) { { namespace: group } }
    let(:work_item_node_path) { %w[group workItems nodes] }

    def post_query(request_user = current_user)
      post_graphql(query, current_user: request_user)
    end
  end

  context 'when filtering by search' do
    let(:item_filter_params) { { search: 'search_term' } }

    it 'returns matching work items' do
      post_graphql(query, current_user: current_user)

      expect(work_item_ids).to contain_exactly(group_work_item.to_global_id.to_s)
    end
  end

  context 'when the user can not see confidential work_items' do
    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it 'does not return confidential issues' do
      post_graphql(query, current_user: current_user)

      expect(work_item_ids).to contain_exactly(
        project_work_item.to_global_id.to_s,
        group_work_item.to_global_id.to_s
      )
    end
  end

  context 'when the user can see confidential work_items' do
    let(:current_user) { reporter }

    it 'returns also confidential work_items' do
      post_graphql(query, current_user: current_user)

      expect(work_item_ids).to contain_exactly(
        project_work_item.to_global_id.to_s,
        confidential_work_item.to_global_id.to_s,
        group_work_item.to_global_id.to_s
      )
    end

    context 'when the namespace_level_work_items feature flag is disabled' do
      before do
        stub_feature_flags(namespace_level_work_items: false)
        post_graphql(query, current_user: current_user)
      end

      it 'returns null in the workItems field' do
        expect(graphql_data['group']['workItems']).to be_nil
      end
    end
  end

  def work_item_ids
    graphql_dig_at(work_items_data, :id)
  end

  def query(params = item_filter_params)
    graphql_query_for(
      'group',
      { 'fullPath' => query_group.full_path },
      query_graphql_field('workItems', params, fields)
    )
  end
end
