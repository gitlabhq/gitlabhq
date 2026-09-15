# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a merge request saved view', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:merged_after) { Time.utc(2026, 1, 1) }

  let(:filters) do
    {
      state: 'opened',
      sort: :MERGED_AT_DESC,
      draft: false,
      assignee_usernames: %w[root],
      label_name: %w[bug],
      merged_after: merged_after.iso8601,
      not: { author_username: 'someone-else' }
    }
  end

  let(:input) { { name: 'My reviews', filters: filters } }

  let(:mutation) do
    graphql_mutation(:merge_request_saved_view_create, input) do
      <<~QL
        errors
        savedView {
          id
          name
          filters
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:merge_request_saved_view_create) }

  subject(:request) { post_graphql_mutation(mutation, current_user: current_user) }

  it 'creates a saved view with filters stored under their snake_case names', :aggregate_failures do
    expect { request }.to change { ::MergeRequests::SavedView.count }.by(1)

    saved_view = GlobalID::Locator.locate(mutation_response['savedView']['id'])

    expect(mutation_response['errors']).to be_empty
    expect(mutation_response['savedView']).to match(a_graphql_entity_for(saved_view, name: 'My reviews'))
    expect(saved_view.user).to eq(current_user)
    expect(saved_view.filters).to eq({
      'state' => 'opened',
      'sort' => 'merged_at_desc',
      'draft' => false,
      'assignee_usernames' => ['root'],
      'label_name' => ['bug'],
      'merged_after' => merged_after.iso8601,
      'not' => { 'author_username' => 'someone-else' }
    })
    expect(mutation_response['savedView']['filters']).to eq({
      'state' => 'opened',
      'sort' => 'merged_at_desc',
      'draft' => false,
      'assigneeUsernames' => ['root'],
      'labelName' => ['bug'],
      'mergedAfter' => merged_after.iso8601,
      'not' => { 'authorUsername' => 'someone-else' }
    })
  end

  context 'when no filters are given' do
    let(:input) { { name: 'My reviews' } }

    it 'stores an empty filters hash' do
      request

      expect(::MergeRequests::SavedView.order(:id).last.filters).to eq({})
    end
  end

  context 'when a filter value is explicitly null' do
    let(:filters) { { state: 'opened', author_username: nil, not: { label_name: nil } } }

    it 'strips the null values before persisting' do
      request

      expect(::MergeRequests::SavedView.order(:id).last.filters).to eq({ 'state' => 'opened', 'not' => {} })
    end
  end

  context 'when the name is blank' do
    let(:input) { { name: '' } }

    it 'does not create a record', :aggregate_failures do
      expect { request }.not_to change { ::MergeRequests::SavedView.count }

      expect(mutation_response['savedView']).to be_nil
    end

    it_behaves_like 'a mutation that returns errors in the response', errors: ["Name can't be blank"]
  end

  context 'when the request is anonymous' do
    let(:current_user) { nil }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  it_behaves_like 'a merge request saved views mutation gated by the mr_dashboard_saved_views feature flag'

  describe 'granular PAT authorization' do
    it_behaves_like 'authorizing granular token permissions for GraphQL',
      [:create_saved_view, :read_saved_view] do
      let(:user) { current_user }
      let(:boundary_object) { :user }
      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end
  end
end
