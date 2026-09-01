# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deleting a merge request saved view', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:saved_view) { create(:merge_request_saved_view, user: current_user, name: 'My reviews') }

  let(:input) { { id: global_id_of(saved_view) } }

  let(:mutation) do
    graphql_mutation(:merge_request_saved_view_delete, input) do
      <<~QL
        errors
        savedView {
          id
          name
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:merge_request_saved_view_delete) }

  subject(:request) { post_graphql_mutation(mutation, current_user: current_user) }

  it 'deletes the saved view and returns it', :aggregate_failures do
    expect { request }.to change { ::MergeRequests::SavedView.count }.by(-1)

    expect(mutation_response['errors']).to be_empty
    expect(mutation_response['savedView']).to match(a_graphql_entity_for(saved_view, name: 'My reviews'))
    expect(::MergeRequests::SavedView.find_by_id(saved_view.id)).to be_nil
  end

  context 'when the saved view belongs to another user' do
    let_it_be(:other_saved_view) { create(:merge_request_saved_view, user: other_user) }

    let(:input) { { id: global_id_of(other_saved_view) } }

    it 'does not delete the saved view' do
      expect { request }.not_to change { ::MergeRequests::SavedView.count }
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  it_behaves_like 'a merge request saved views mutation gated by the mr_dashboard_saved_views feature flag'

  describe 'granular PAT authorization' do
    let_it_be(:granular_saved_view) { create(:merge_request_saved_view, user: current_user) }

    it_behaves_like 'authorizing granular token permissions for GraphQL',
      [:delete_saved_view, :read_saved_view] do
      let(:user) { current_user }
      let(:boundary_object) { :user }
      let(:input) { { id: global_id_of(granular_saved_view) } }
      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end
  end
end
