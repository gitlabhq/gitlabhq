# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'find work items by reference', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:group2) { create(:group, :public) }
  let_it_be(:project2) { create(:project, :repository, :public, group: group2) }
  let_it_be(:private_project2) { create(:project, :repository, :private, group: group2) }
  let_it_be(:work_item) { create(:work_item, :task, project: project2) }
  let_it_be(:private_work_item) { create(:work_item, :task, project: private_project2) }

  let(:path) { project.full_path }

  let(:references) { [work_item.to_reference(full: true), private_work_item.to_reference(full: true)] }

  shared_examples 'response with matching work items' do
    it 'returns accessible work item' do
      post_graphql(query, current_user: current_user)

      expected_items = items.map { |item| a_graphql_entity_for(item) }
      expect(graphql_data_at('workItemsByReference', 'nodes')).to match(expected_items)
    end
  end

  context 'when user has access only to public work items' do
    it_behaves_like 'a working graphql query that returns data' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it_behaves_like 'response with matching work items' do
      let(:items) { [work_item] }
    end

    it 'avoids N+1 queries', :use_sql_query_cache do
      post_graphql(query, current_user: current_user) # warm up

      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql(query, current_user: current_user)
      end

      expect(graphql_data_at('workItemsByReference', 'nodes').size).to eq(1)

      extra_work_items = create_list(:work_item, 2, :task, project: project2)
      refs = references + extra_work_items.map { |item| item.to_reference(full: true) }

      expect do
        post_graphql(query(refs: refs), current_user: current_user)
      end.not_to exceed_all_query_limit(control_count)
      expect(graphql_data_at('workItemsByReference', 'nodes').size).to eq(3)
    end
  end

  context 'when user has access to work items in private project' do
    before_all do
      private_project2.add_guest(current_user)
    end

    it_behaves_like 'response with matching work items' do
      let(:items) { [private_work_item, work_item] }
    end
  end

  context 'when refs includes links' do
    let_it_be(:work_item_with_url) { create(:work_item, :task, project: project2) }
    let(:references) { [work_item.to_reference(full: true), Gitlab::UrlBuilder.build(work_item_with_url)] }

    it_behaves_like 'response with matching work items' do
      let(:items) { [work_item_with_url, work_item] }
    end
  end

  context 'when refs includes a short reference present in the context project' do
    let_it_be(:same_project_work_item) { create(:work_item, :task, project: project) }
    let(:references) { ["##{same_project_work_item.iid}"] }

    it_behaves_like 'response with matching work items' do
      let(:items) { [same_project_work_item] }
    end
  end

  context 'when user cannot access context namespace' do
    it 'returns error' do
      post_graphql(query(namespace_path: private_project2.full_path), current_user: current_user)

      expect(graphql_data_at('workItemsByReference')).to be_nil
      expect(graphql_errors).to contain_exactly(a_hash_including(
        'message' => a_string_including("you don't have permission to perform this action"),
        'path' => %w[workItemsByReference]
      ))
    end
  end

  context 'when the context is a group' do
    let_it_be(:task) { create(:work_item, :task, project: project2) }

    let(:references) { [work_item.to_reference(full: true), Gitlab::UrlBuilder.build(task)] }
    let(:path) { group2.path }

    it_behaves_like 'response with matching work items' do
      let(:items) { [task, work_item] }
    end
  end

  context 'when there are more than the max allowed references' do
    let(:references_limit) { ::Resolvers::WorkItemReferencesResolver::REFERENCES_LIMIT }
    let(:references) { (0..references_limit).map { |n| "##{n}" } }
    let(:error_msg) do
      "Number of references exceeds the limit. " \
        "Please provide no more than #{references_limit} references at the same time."
    end

    it 'returns an error message' do
      post_graphql(query, current_user: current_user)

      expect_graphql_errors_to_include(error_msg)
    end
  end

  def query(namespace_path: path, refs: references)
    fields = <<~GRAPHQL
      nodes {
        #{all_graphql_fields_for('WorkItem', max_depth: 2)}
      }
    GRAPHQL

    graphql_query_for('workItemsByReference', { contextNamespacePath: namespace_path, refs: refs }, fields)
  end
end
