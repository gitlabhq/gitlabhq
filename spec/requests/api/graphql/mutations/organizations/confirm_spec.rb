# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Organizations::Confirm, feature_category: :organization do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:organization) { create(:organization, :unconfirmed, owners: user) }
  let_it_be(:source_organization) { create(:organization) }
  let_it_be(:top_level_group) { create(:group, organization: source_organization, owners: user) }
  let_it_be(:other_top_level_group) { create(:group, organization: source_organization, owners: user) }

  let(:mutation) { graphql_mutation(:organization_confirm, params) }
  let(:groups) { [top_level_group.to_global_id.to_s, other_top_level_group.to_global_id.to_s] }
  let(:params) do
    {
      id: organization.to_global_id.to_s,
      groups: groups
    }
  end

  subject(:confirm_organization) { post_graphql_mutation(mutation, current_user: current_user) }

  it { expect(described_class).to require_graphql_authorizations(:update_organization) }

  it_behaves_like 'authorizing granular token permissions for GraphQL', :update_organization do
    let(:boundary_object) { :instance }
    let(:mutation) { graphql_mutation(:organization_confirm, params, 'errors') }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end

  def mutation_response
    graphql_mutation_response(:organization_confirm)
  end

  context 'when the user does not have permission' do
    let(:current_user) { nil }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not change the organization state' do
      confirm_organization
      organization.reset

      expect(organization.state).to eq('unconfirmed')
    end
  end

  context 'when the user has permission' do
    let(:current_user) { user }

    context 'when confirming without groups' do
      let(:groups) { [] }

      it 'confirms the organization', :aggregate_failures do
        confirm_organization

        expect(graphql_data_at(:organization_confirm, :organization)).to match a_hash_including(
          'id' => organization.to_global_id.to_s,
          'name' => organization.name,
          'path' => organization.path,
          'state' => 'CONFIRMED'
        )
        expect(mutation_response['errors']).to be_empty
        expect(organization.reload.state).to eq('confirmed')
      end
    end

    context 'when groups param is not provided' do
      let(:params) { { id: organization.to_global_id.to_s } }

      it 'confirms the organization', :aggregate_failures do
        confirm_organization

        expect(graphql_data_at(:organization_confirm, :organization)).to match a_hash_including(
          'id' => organization.to_global_id.to_s,
          'state' => 'CONFIRMED'
        )
        expect(mutation_response['errors']).to be_empty
        expect(organization.reload.state).to eq('confirmed')
      end
    end

    context 'when confirming with groups' do
      it 'confirms the organization and transfers groups', :aggregate_failures do
        expect(top_level_group.organization_id).to eq(source_organization.id)
        expect(other_top_level_group.organization_id).to eq(source_organization.id)

        confirm_organization

        expect(graphql_data_at(:organization_confirm, :organization)).to match a_hash_including(
          'id' => organization.to_global_id.to_s,
          'state' => 'CONFIRMED'
        )
        expect(mutation_response['errors']).to be_empty
        expect(organization.reload.state).to eq('confirmed')
        expect(top_level_group.reload.organization_id).to eq(organization.id)
        expect(other_top_level_group.reload.organization_id).to eq(organization.id)
      end
    end

    context 'when organization is already confirmed' do
      before do
        organization.update_column(:state, Organizations::Organization.states[:active])
      end

      it 'returns an error', :aggregate_failures do
        confirm_organization

        expect(mutation_response['errors']).to include('State cannot transition via "confirm"')
      end
    end

    context 'when a group does not exist' do
      let(:groups) { [top_level_group.to_global_id.to_s, "gid://gitlab/Group/#{non_existing_record_id}"] }

      it 'returns an error', :aggregate_failures do
        confirm_organization

        expect(mutation_response['errors']).to include('One or more groups could not be found')
        expect(organization.reload.state).to eq('unconfirmed')
      end
    end
  end
end
