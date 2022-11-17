# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a work item list for a project' do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, :public, group: group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:label1) { create(:label, project: project) }
  let_it_be(:label2) { create(:label, project: project) }
  let_it_be(:milestone1) { create(:milestone, project: project) }
  let_it_be(:milestone2) { create(:milestone, project: project) }

  let_it_be(:item1) { create(:work_item, project: project, discussion_locked: true, title: 'item1', labels: [label1]) }
  let_it_be(:item2) do
    create(
      :work_item,
      project: project,
      title: 'item2',
      last_edited_by: current_user,
      last_edited_at: 1.day.ago,
      labels: [label2],
      milestone: milestone1
    )
  end

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

  shared_examples 'work items resolver without N + 1 queries' do
    it 'avoids N+1 queries' do
      post_graphql(query, current_user: current_user) # warm-up

      control = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: current_user)
      end

      expect_graphql_errors_to_be_empty

      create_list(
        :work_item, 3,
        :task,
        :last_edited_by_user,
        last_edited_at: 1.week.ago,
        project: project,
        labels: [label1, label2],
        milestone: milestone2
      )

      expect_graphql_errors_to_be_empty
      expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(control)
    end
  end

  describe 'N + 1 queries' do
    context 'when querying root fields' do
      it_behaves_like 'work items resolver without N + 1 queries'
    end

    # We need a separate example since all_graphql_fields_for will not fetch fields from types
    # that implement the widget interface. Only `type` for the widgets field.
    context 'when querying the widget interface' do
      let(:fields) do
        <<~GRAPHQL
          nodes {
            widgets {
              type
              ... on WorkItemWidgetDescription {
                edited
                lastEditedAt
                lastEditedBy {
                  webPath
                  username
                }
              }
              ... on WorkItemWidgetAssignees {
                assignees { nodes { id } }
              }
              ... on WorkItemWidgetHierarchy {
                parent { id }
              }
              ... on WorkItemWidgetLabels {
                labels { nodes { id } }
                allowsScopedLabels
              }
              ... on WorkItemWidgetMilestone {
                milestone {
                  id
                }
              }
            }
          }
        GRAPHQL
      end

      it_behaves_like 'work items resolver without N + 1 queries'
    end
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

  context 'when filtering by search' do
    it_behaves_like 'query with a search term' do
      let(:issuable_data) { items_data }
      let(:user) { current_user }
      let_it_be(:issuable) { create(:work_item, project: project, description: 'bar') }
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

  def query(params = item_filter_params)
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('workItems', params, fields)
    )
  end
end
