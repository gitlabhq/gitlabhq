# frozen_string_literal: true

require 'spec_helper'
RSpec.describe 'Restoring a Terraform state',
  :aggregate_failures,
  feature_category: :infrastructure_as_code do
  include GraphqlHelpers
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:state) do
    create(:terraform_state, project: project, deleted_at: Time.current)
  end

  let_it_be(:current_user) { create(:user, maintainer_of: project) }
  let(:input) { { id: state.to_global_id } }
  let(:mutation) do
    graphql_mutation(:terraform_state_restore, input, <<~QUERY)
     terraformState {
       id
       deletedAt
     }
     errors
    QUERY
  end

  let(:mutation_response) do
    graphql_mutation_response(:terraform_state_restore)
  end

  subject(:perform_request) do
    post_graphql_mutation(mutation, current_user: current_user)
  end

  around do |example|
    freeze_time { example.run }
  end

  it_behaves_like 'a working GraphQL mutation'
  it 'restores the Terraform state' do
    perform_request
    expect(mutation_response).to include(
      'errors' => be_blank,
      'terraformState' => {
        'id' => state.to_global_id.to_s,
        'deletedAt' => nil
      }
    )
    expect(state.reload.deleted_at).to be_nil
  end

  context 'when the delayed deletion feature is disabled' do
    before do
      stub_feature_flags(terraform_state_delayed_deletion: false)
    end

    it 'does not restore the Terraform state' do
      perform_request
      expect_graphql_errors_to_include(/The resource that you are attempting to access/)
      expect(state.reload.deleted_at).to be_present
    end
  end

  context 'when the state is not marked for deletion' do
    before do
      state.update!(deleted_at: nil)
    end

    it 'returns the service error' do
      perform_request
      expect(mutation_response).to include(
        'terraformState' => nil,
        'errors' => ['State is not marked for deletion']
      )
    end
  end

  context 'when the grace period has elapsed' do
    before do
      state.update!(deleted_at: Terraform::State::GRACE_PERIOD.ago)
    end

    it 'returns the service error' do
      perform_request
      expect(mutation_response).to include(
        'terraformState' => nil,
        'errors' => ['Grace period for this state has elapsed']
      )
      expect(state.reload.deleted_at).to eq(Terraform::State::GRACE_PERIOD.ago)
    end
  end

  context 'when the current user does not have permission' do
    let_it_be(:developer) { create(:user, developer_of: project) }
    let_it_be(:guest) { create(:user, guest_of: project) }
    let_it_be(:non_member) { create(:user) }
    let(:anonymous) { nil }

    where(:current_user) do
      [
        ref(:developer),
        ref(:guest),
        ref(:non_member),
        ref(:anonymous)
      ]
    end
    with_them do
      it 'returns a permission error' do
        perform_request
        expect_graphql_errors_to_include(/you don't have permission to perform this action/)
      end
    end
  end

  describe 'granular PAT authorization' do
    it_behaves_like 'authorizing granular token permissions for GraphQL',
      :restore_terraform_state do
      let(:user) { current_user }
      let(:boundary_object) { project }
      let(:mutation) { graphql_mutation(:terraform_state_restore, input, 'errors') }
      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end
  end
end
