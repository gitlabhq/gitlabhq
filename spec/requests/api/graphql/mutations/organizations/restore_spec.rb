# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Organizations::Restore, feature_category: :organization do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:owner) { create(:user) }
  let_it_be_with_reload(:organization) { create(:organization, owners: [owner]) }

  let(:mutation) { graphql_mutation(:organization_restore, params) }
  let(:params) do
    {
      id: organization.to_global_id.to_s
    }
  end

  subject(:restore_organization) { post_graphql_mutation(mutation, current_user: current_user) }

  it { expect(described_class).to require_graphql_authorizations(:restore_organization) }

  it_behaves_like 'authorizing granular token permissions for GraphQL', :restore_organization do
    let(:boundary_object) { :instance }
    let(:mutation) { graphql_mutation(:organization_restore, params, 'errors') }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    let(:user) { admin }

    before do
      organization.soft_delete(transition_user: user)
      organization.reload
    end
  end

  def mutation_response
    graphql_mutation_response(:organization_restore)
  end

  context 'when the user is unauthenticated' do
    let(:current_user) { nil }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not change the organization state' do
      expect { restore_organization }.not_to change { organization.reload.state }
    end
  end

  context 'when the user is a non-admin owner' do
    let(:current_user) { owner }

    before do
      organization.soft_delete(transition_user: admin)
      organization.reload
    end

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not change the organization state' do
      expect { restore_organization }.not_to change { organization.reload.state }
    end
  end

  context 'when the user is an admin', :enable_admin_mode do
    let(:current_user) { admin }

    context 'when the organization is soft-deleted' do
      before do
        organization.soft_delete(transition_user: admin)
        organization.reload
      end

      it 'restores the organization to active state', :aggregate_failures do
        restore_organization

        expect(graphql_data_at(:organization_restore, :organization)).to match a_hash_including(
          'name' => organization.name,
          'state' => 'ACTIVE'
        )
        expect(mutation_response['errors']).to be_empty
        expect(organization.reload.state).to eq('active')
      end
    end

    context 'when the organization is not soft-deleted' do
      it 'returns errors and does not change the state', :aggregate_failures do
        restore_organization

        expect(mutation_response['errors']).to contain_exactly('Organization is not soft-deleted')
        expect(organization.reload.state).to eq('active')
      end
    end
  end

  context 'when the organization ID does not exist' do
    let(:current_user) { admin }
    let(:params) do
      {
        id: "gid://gitlab/Organizations::Organization/#{non_existing_record_id}"
      }
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end
end
