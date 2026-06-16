# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Organizations::Delete, feature_category: :organization do
  include GraphqlHelpers

  let_it_be_with_reload(:organization) { create(:organization) }
  let_it_be(:user) { create(:user, owner_of: organization) }
  let_it_be(:unauthorized_user) { create(:user) }
  let_it_be(:admin) { create(:admin, organizations: [organization]) }

  let(:mutation) { graphql_mutation(:organization_delete, params) }
  let(:params) do
    {
      id: organization.to_global_id.to_s
    }
  end

  subject(:delete_organization) { post_graphql_mutation(mutation, current_user: current_user) }

  it { expect(described_class).to require_graphql_authorizations(:delete_organization) }

  it_behaves_like 'authorizing granular token permissions for GraphQL', :delete_organization do
    let(:boundary_object) { :instance }
    let(:mutation) { graphql_mutation(:organization_delete, params, 'errors') }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end

  def mutation_response
    graphql_mutation_response(:organization_delete)
  end

  shared_examples 'successfully soft-deletes the organization' do
    it 'schedules the organization for deletion' do
      delete_organization

      expect(graphql_data_at(:organization_delete, :organization)).to match a_hash_including(
        'name' => organization.name,
        'state' => 'SOFT_DELETED'
      )
      expect(mutation_response['errors']).to be_empty
      expect(organization.reload.state).to eq('soft_deleted')
    end
  end

  context 'when the organization is empty' do
    context 'when the user is an organization owner' do
      let(:current_user) { user }

      it_behaves_like 'successfully soft-deletes the organization'
    end

    context 'when the user is an instance admin' do
      let(:current_user) { admin }

      it_behaves_like 'successfully soft-deletes the organization'
    end
  end

  context 'when the user does not have permission' do
    let(:current_user) { unauthorized_user }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not delete the organization' do
      expect { delete_organization }.not_to change { organization.reload.state }
    end
  end

  context 'when the organization is not empty' do
    let(:current_user) { user }

    shared_examples 'returns an organization not empty error' do
      it 'returns an error message' do
        delete_organization

        expect(mutation_response['errors']).to contain_exactly('Organization must be empty before it can be deleted')
      end
    end

    context 'with groups' do
      before do
        create(:group, organization: organization)
      end

      it_behaves_like 'returns an organization not empty error'
    end

    context 'with projects' do
      before do
        create(:project, organization: organization)
      end

      it_behaves_like 'returns an organization not empty error'
    end
  end

  shared_examples 'does not change the deletion state' do
    it 'does not change the deletion state' do
      expect { delete_organization }.not_to change { organization.reload.state }
    end
  end

  context 'when the organization is the default org' do
    let(:current_user) { admin }
    let(:organization) { create(:organization, :default) } # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- the delete_organization policy disallows deletion of the default organization

    it_behaves_like 'does not change the deletion state'
  end
end
