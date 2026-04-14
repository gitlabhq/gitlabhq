# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.mergeRequest.linkedWorkItems', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be_with_reload(:project) { create(:project, :public, :repository) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }

  let_it_be(:closing_issue) { create(:issue, project: project) }
  let_it_be(:confidential_issue) { create(:issue, :confidential, project: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let_it_be(:closing_link1) do
    create(:merge_requests_closing_issues, issue: closing_issue, merge_request: merge_request)
  end

  let_it_be(:closing_link2) do
    create(:merge_requests_closing_issues, issue: confidential_issue, merge_request: merge_request)
  end

  let(:current_user) { developer }
  let(:linked_work_items_data) { graphql_data_at(:merge_request, :linked_work_items) }
  let(:merge_request_params) { { 'id' => global_id_of(merge_request) } }

  let(:linked_work_items_fields) do
    <<~GRAPHQL
      linkedWorkItems {
        linkType
        workItem { id title }
        externalIssue { reference title }
      }
    GRAPHQL
  end

  let(:query) do
    graphql_query_for('mergeRequest', merge_request_params, linked_work_items_fields)
  end

  before do
    post_graphql(query, current_user: current_user)
  end

  context 'when filtering by CLOSES type' do
    let(:linked_work_items_fields) do
      <<~GRAPHQL
        linkedWorkItems(types: [CLOSES]) {
          linkType
          workItem { id title }
        }
      GRAPHQL
    end

    it 'returns only closing work items' do
      work_item_ids = linked_work_items_data.pluck('workItem').pluck('id')

      expect(work_item_ids).to contain_exactly(
        global_id_of(closing_issue, model_name: 'WorkItem').to_s,
        global_id_of(confidential_issue, model_name: 'WorkItem').to_s
      )

      expect(linked_work_items_data.pluck('linkType')).to all(eq('CLOSES'))
    end
  end

  context 'when filtering by MENTIONED type' do
    let_it_be(:project_with_repo) { create(:project, :public, :repository, developers: developer) }
    let_it_be(:issue_to_mention) { create(:issue, project: project_with_repo) }

    let_it_be(:mr_with_mentioned_issue) do
      create(:merge_request, :simple,
        source_project: project_with_repo,
        description: "Related to #{issue_to_mention.to_reference}"
      )
    end

    let(:merge_request_params) { { 'id' => global_id_of(mr_with_mentioned_issue) } }

    let(:linked_work_items_fields) do
      <<~GRAPHQL
        linkedWorkItems(types: [MENTIONED]) {
          linkType
          workItem { id title }
        }
      GRAPHQL
    end

    it 'returns only mentioned work items' do
      work_item_ids = linked_work_items_data.pluck('workItem').pluck('id')

      expect(work_item_ids).to contain_exactly(
        global_id_of(issue_to_mention, model_name: 'WorkItem').to_s
      )
      expect(linked_work_items_data.pluck('linkType')).to all(eq('MENTIONED'))
    end
  end

  context 'when mentioned issues include external issues' do
    let_it_be(:project_with_jira) do
      create(:project, :public, :repository, :with_jira_integration, developers: developer)
    end

    let_it_be(:internal_issue) { create(:issue, project: project_with_jira) }

    let_it_be(:mr_with_external_issue) do
      create(:merge_request, :simple,
        source_project: project_with_jira,
        description: "Mentions JIRA-123 and #{internal_issue.to_reference}"
      )
    end

    let(:merge_request_params) { { 'id' => global_id_of(mr_with_external_issue) } }

    let(:linked_work_items_fields) do
      <<~GRAPHQL
        linkedWorkItems(types: [MENTIONED]) {
          linkType
          workItem { id }
          externalIssue { reference title webUrl }
        }
      GRAPHQL
    end

    it 'returns internal issues via workItem and external issues via externalIssue' do
      internal_items = linked_work_items_data.select { |item| item['workItem'].present? }
      external_items = linked_work_items_data.select { |item| item['externalIssue'].present? }

      expect(internal_items.size).to eq(1)
      expect(internal_items.first.dig('workItem', 'id')).to eq(
        global_id_of(internal_issue, model_name: 'WorkItem').to_s
      )
      expect(internal_items.first['externalIssue']).to be_nil

      expect(external_items.size).to eq(1)
      expect(external_items.first.dig('externalIssue', 'reference')).to eq('JIRA-123')
      expect(external_items.first.dig('externalIssue', 'webUrl')).to eq('https://jira.example.com/browse/JIRA-123')
      expect(external_items.first['workItem']).to be_nil

      expect(linked_work_items_data.pluck('linkType')).to all(eq('MENTIONED'))
    end
  end

  context 'when an issue is both mentioned and closing' do
    let(:merge_request_params) { { 'id' => global_id_of(merge_request_with_mixed_links) } }
    let_it_be(:project_with_repo) { create(:project, :public, :repository, developers: developer) }
    let_it_be(:issue_mentioned_and_closing) { create(:issue, project: project_with_repo) }
    let_it_be(:issue_only_mentioned) { create(:issue, project: project_with_repo) }

    let_it_be(:merge_request_with_mixed_links) do
      description = "Mentions #{issue_mentioned_and_closing.to_reference} " \
        "and also #{issue_only_mentioned.to_reference}"

      create(:merge_request, :simple, source_project: project_with_repo, description: description)
    end

    before_all do
      create(:merge_requests_closing_issues,
        issue: issue_mentioned_and_closing,
        merge_request: merge_request_with_mixed_links
      )
    end

    it 'returns the closing issue exactly once with CLOSES type and excludes it from mentioned' do
      items = linked_work_items_data

      closing_id = global_id_of(issue_mentioned_and_closing, model_name: 'WorkItem').to_s
      mentioned_id = global_id_of(issue_only_mentioned, model_name: 'WorkItem').to_s

      closing_item = items.find { |i| i.dig('workItem', 'id') == closing_id }
      mentioned_item = items.find { |i| i.dig('workItem', 'id') == mentioned_id }

      expect(items.size).to eq(2)
      expect(closing_item['linkType']).to eq('CLOSES')
      expect(mentioned_item['linkType']).to eq('MENTIONED')
    end
  end

  context 'when user cannot see confidential issues' do
    let(:current_user) { guest }

    let(:linked_work_items_fields) do
      <<~GRAPHQL
        linkedWorkItems(types: [CLOSES]) {
          linkType
          workItem { id }
        }
      GRAPHQL
    end

    it 'excludes confidential issues' do
      work_item_ids = linked_work_items_data.pluck('workItem').pluck('id')

      expect(work_item_ids).to contain_exactly(
        global_id_of(closing_issue, model_name: 'WorkItem').to_s
      )
    end
  end

  context 'when user is not authenticated' do
    let(:current_user) { nil }

    let(:linked_work_items_fields) do
      <<~GRAPHQL
        linkedWorkItems(types: [CLOSES]) {
          linkType
          workItem { id }
        }
      GRAPHQL
    end

    it 'returns only public issues' do
      work_item_ids = linked_work_items_data.pluck('workItem').pluck('id')

      expect(work_item_ids).to contain_exactly(
        global_id_of(closing_issue, model_name: 'WorkItem').to_s
      )
    end
  end

  context 'when project has autoclose_referenced_issues disabled' do
    let(:linked_work_items_fields) do
      <<~GRAPHQL
        linkedWorkItems(types: [CLOSES]) {
          linkType
          workItem { id }
        }
      GRAPHQL
    end

    before do
      project.update!(autoclose_referenced_issues: false)
      post_graphql(query, current_user: current_user)
    end

    it 'excludes issues from projects with autoclose disabled' do
      expect(linked_work_items_data).to be_empty
    end
  end

  context 'when no types filter is provided' do
    it 'returns all linked work items' do
      work_item_ids = linked_work_items_data.pluck('workItem').compact.pluck('id')

      expect(work_item_ids).to include(
        global_id_of(closing_issue, model_name: 'WorkItem').to_s,
        global_id_of(confidential_issue, model_name: 'WorkItem').to_s
      )
    end
  end
end
