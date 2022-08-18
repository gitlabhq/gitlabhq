# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting an work item list for a project' do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, :public, group: group) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:item1) { create(:work_item, project: project, discussion_locked: true, title: 'item1') }
  let_it_be(:item2) { create(:work_item, project: project, title: 'item2') }
  let_it_be(:confidential_item) { create(:work_item, confidential: true, project: project, title: 'item3') }
  let_it_be(:other_item) { create(:work_item) }

  let(:items_data) { graphql_data['project']['workItems']['edges'] }
  let(:item_filter_params) { {} }

  let(:fields) do
    <<~QUERY
    edges {
      node {
        #{all_graphql_fields_for('workItems'.classify, max_depth: 2)}
      }
    }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('workItems', item_filter_params, fields)
    )
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  context 'when the user does not have access to the item' do
    before do
      project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
    end

    it 'returns an empty list' do
      post_graphql(query)

      expect(items_data).to eq([])
    end
  end

  context 'when work_items flag is disabled' do
    before do
      stub_feature_flags(work_items: false)
    end

    it 'returns an empty list' do
      post_graphql(query)

      expect(items_data).to eq([])
    end
  end

  it 'returns only items visible to user' do
    post_graphql(query, current_user: current_user)

    expect(item_ids).to eq([item2.to_global_id.to_s, item1.to_global_id.to_s])
  end

  context 'when the user can see confidential items' do
    before do
      project.add_developer(current_user)
    end

    it 'returns also confidential items' do
      post_graphql(query, current_user: current_user)

      expect(item_ids).to eq([confidential_item.to_global_id.to_s, item2.to_global_id.to_s, item1.to_global_id.to_s])
    end
  end

  describe 'sorting and pagination' do
    let(:data_path) { [:project, :work_items] }

    def pagination_query(params)
      graphql_query_for(
        'project',
        { 'fullPath' => project.full_path },
        query_graphql_field('workItems', params, "#{page_info} nodes { id }")
      )
    end

    before do
      project.add_developer(current_user)
    end

    context 'when sorting by title ascending' do
      it_behaves_like 'sorted paginated query' do
        let(:sort_param) { :TITLE_ASC }
        let(:first_param) { 2 }
        let(:all_records) { [item1, item2, confidential_item].map { |item| item.to_global_id.to_s } }
      end
    end

    context 'when sorting by title descending' do
      it_behaves_like 'sorted paginated query' do
        let(:sort_param) { :TITLE_DESC }
        let(:first_param) { 2 }
        let(:all_records) { [confidential_item, item2, item1].map { |item| item.to_global_id.to_s } }
      end
    end
  end

  def item_ids
    graphql_dig_at(items_data, :node, :id)
  end
end
