# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.mergeRequest.workItemRelations', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }

  let_it_be(:closing_issue) { create(:issue, project: project) }
  let_it_be(:confidential_issue) { create(:issue, :confidential, project: project) }
  let_it_be(:mentioned_issue) { create(:issue, project: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let_it_be(:closing_relation) do
    create(:merge_requests_closing_issues,
      issue: closing_issue, merge_request: merge_request, link_type: :closes, from_mr_description: true)
  end

  let_it_be(:confidential_relation) do
    create(:merge_requests_closing_issues,
      issue: confidential_issue, merge_request: merge_request, link_type: :closes, from_mr_description: true)
  end

  let_it_be(:mentioned_relation) do
    create(:merge_requests_closing_issues,
      issue: mentioned_issue, merge_request: merge_request, link_type: :mentioned, from_mr_description: false)
  end

  let(:current_user) { developer }
  let(:relations_data) { graphql_data_at(:merge_request, :work_item_relations, :nodes) }
  let(:merge_request_params) { { 'id' => global_id_of(merge_request) } }
  let(:types_arg) { '' }

  let(:relations_fields) do
    <<~GRAPHQL
      workItemRelations#{types_arg} {
        nodes {
          id
          linkType
          fromMrDescription
          workItem { id title }
        }
      }
    GRAPHQL
  end

  let(:query) do
    graphql_query_for('mergeRequest', merge_request_params, relations_fields)
  end

  before do
    post_graphql(query, current_user: current_user)
  end

  it 'returns persisted relations with their link type and origin', :aggregate_failures do
    work_item_ids = relations_data.pluck('workItem').compact.pluck('id')

    expect(work_item_ids).to contain_exactly(
      global_id_of(closing_issue, model_name: 'WorkItem').to_s,
      global_id_of(confidential_issue, model_name: 'WorkItem').to_s,
      global_id_of(mentioned_issue, model_name: 'WorkItem').to_s
    )

    mentioned_gid = global_id_of(mentioned_issue, model_name: 'WorkItem').to_s
    mentioned_node = relations_data.find { |n| n.dig('workItem', 'id') == mentioned_gid }
    expect(mentioned_node['linkType']).to eq('MENTIONED')
    expect(mentioned_node['fromMrDescription']).to be(false)
  end

  context 'when filtering by MENTIONED type' do
    let(:types_arg) { '(types: [MENTIONED])' }

    it 'returns only mentioned relations' do
      expect(relations_data.pluck('linkType')).to all(eq('MENTIONED'))
    end
  end

  context 'when the user cannot read confidential issues' do
    let(:current_user) { guest }
    let(:types_arg) { '(types: [CLOSES])' }

    it 'excludes relations the user cannot read' do
      work_item_ids = relations_data.pluck('workItem').compact.pluck('id')

      expect(work_item_ids).to contain_exactly(
                                 global_id_of(closing_issue, model_name: 'WorkItem').to_s
                               )
    end
  end

  context 'when the user is not authenticated' do
    let(:current_user) { nil }
    let(:types_arg) { '(types: [CLOSES])' }

    it 'returns only public relations' do
      work_item_ids = relations_data.pluck('workItem').compact.pluck('id')

      expect(work_item_ids).to contain_exactly(
                                 global_id_of(closing_issue, model_name: 'WorkItem').to_s
                               )
    end
  end

  context 'when the feature flag is disabled' do
    before do
      stub_feature_flags(explicit_mr_work_item_relations: false)
      post_graphql(query, current_user: current_user)
    end

    it 'returns null' do
      expect(graphql_data_at(:merge_request, :work_item_relations)).to be_nil
    end
  end

  describe 'avoiding N+1 queries on the connection authorization' do
    def add_relations(count)
      Array.new(count) do
        create(:merge_requests_closing_issues,
          issue: create(:issue, project: project), merge_request: merge_request,
          link_type: :related, from_mr_description: false)
      end
    end

    it 'does not run more queries as the number of relations grows' do
      add_relations(2)

      post_graphql(query, current_user: create(:user))
      control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: create(:user)) }

      add_relations(18)

      expect { post_graphql(query, current_user: create(:user)) }.not_to exceed_query_limit(control)
    end
  end
end
