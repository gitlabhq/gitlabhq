# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating a merge request saved view', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be_with_reload(:saved_view) do
    create(:merge_request_saved_view, :with_filters, user: current_user, name: 'My reviews')
  end

  let(:input) { { id: global_id_of(saved_view), name: 'Renamed' } }

  let(:mutation) do
    graphql_mutation(:merge_request_saved_view_update, input) do
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

  let(:mutation_response) { graphql_mutation_response(:merge_request_saved_view_update) }

  subject(:request) { post_graphql_mutation(mutation, current_user: current_user) }

  it 'renames the saved view and leaves the filters untouched', :aggregate_failures do
    request

    expect(mutation_response['errors']).to be_empty
    expect(mutation_response['savedView']).to match(a_graphql_entity_for(saved_view, name: 'Renamed'))
    expect(saved_view.reload.name).to eq('Renamed')
    expect(saved_view.filters).to include('state' => 'opened')
  end

  context 'when filters are given' do
    let(:input) do
      { id: global_id_of(saved_view), filters: { state: 'merged', not: { target_branches: %w[main] } } }
    end

    it 'replaces the stored filters entirely' do
      request

      expect(saved_view.reload.filters).to eq({
        'state' => 'merged',
        'not' => { 'target_branches' => ['main'] }
      })
    end
  end

  context 'when an empty filter object is given' do
    let(:input) { { id: global_id_of(saved_view), filters: {} } }

    it 'clears the stored filters' do
      request

      expect(saved_view.reload.filters).to eq({})
    end
  end

  context 'when the name is blank' do
    let(:input) { { id: global_id_of(saved_view), name: '' } }

    it 'does not update the record', :aggregate_failures do
      request

      expect(mutation_response['savedView']).to be_nil
      expect(saved_view.reload.name).to eq('My reviews')
    end

    it_behaves_like 'a mutation that returns errors in the response', errors: ["Name can't be blank"]
  end

  context 'when the saved view belongs to another user' do
    let_it_be(:other_saved_view) { create(:merge_request_saved_view, user: other_user, name: 'Other reviews') }

    let(:input) { { id: global_id_of(other_saved_view), name: 'Renamed' } }

    it 'does not change the name' do
      request

      expect(other_saved_view.reload.name).to eq('Other reviews')
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  it_behaves_like 'a merge request saved views mutation gated by the mr_dashboard_saved_views feature flag'

  describe 'granular PAT authorization' do
    it_behaves_like 'authorizing granular token permissions for GraphQL',
      [:update_saved_view, :read_saved_view] do
      let(:user) { current_user }
      let(:boundary_object) { :user }
      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end
  end
end
