# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.mergeRequest.resourceLabelEvents', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:label) { create(:label, project: project) }

  let_it_be(:add_event) do
    create(:resource_label_event, merge_request: merge_request, label: label, action: :add)
  end

  let_it_be(:remove_event) do
    create(:resource_label_event, merge_request: merge_request, label: label, action: :remove)
  end

  let(:current_user) { developer }
  let(:events_data) { graphql_data_at(:merge_request, :resource_label_events, :nodes) }
  let(:merge_request_params) { { 'id' => global_id_of(merge_request) } }

  let(:events_fields) do
    <<~GRAPHQL
      resourceLabelEvents {
        nodes {
          id
          action
          createdAt
          label { id }
          user { id }
        }
      }
    GRAPHQL
  end

  let(:query) do
    graphql_query_for('mergeRequest', merge_request_params, events_fields)
  end

  it 'returns the label events for the merge request in creation order', :aggregate_failures do
    post_graphql(query, current_user: current_user)

    expect(events_data.pluck('id')).to eq(
      [global_id_of(add_event).to_s, global_id_of(remove_event).to_s]
    )
    expect(events_data.pluck('action')).to eq(%w[ADD REMOVE])
    expect(events_data.pluck('label')).to all(eq({ 'id' => global_id_of(label).to_s }))
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :read_merge_request_label_event do
    let(:user) { developer }
    let(:boundary_object) { project }
    let(:request) { post_graphql(query, token: { personal_access_token: pat }) }
  end

  context 'when a label event references a deleted label' do
    before do
      label.destroy!
      add_event.reload
    end

    it 'returns the event with a null label' do
      post_graphql(query, current_user: current_user)

      event = events_data.find { |node| node['id'] == global_id_of(add_event).to_s }

      expect(event['label']).to be_nil
    end
  end

  context 'when the user cannot read the merge request' do
    let_it_be(:private_project) { create(:project, :private, :repository) }
    let_it_be(:private_merge_request) { create(:merge_request, source_project: private_project) }

    let(:current_user) { create(:user) }
    let(:merge_request_params) { { 'id' => global_id_of(private_merge_request) } }

    before do
      post_graphql(query, current_user: current_user)
    end

    it 'returns null' do
      expect(graphql_data_at(:merge_request)).to be_nil
    end
  end

  describe 'avoiding N+1 queries' do
    def add_events(count)
      Array.new(count) { create(:resource_label_event, merge_request: merge_request, label: label) }
    end

    it 'does not run more queries as the number of events grows' do
      add_events(2)

      warmup_user = create(:user)
      control_user = create(:user)
      final_user = create(:user)

      post_graphql(query, current_user: warmup_user)
      control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: control_user) }

      add_events(18)

      expect { post_graphql(query, current_user: final_user) }.not_to exceed_query_limit(control)
    end
  end
end
