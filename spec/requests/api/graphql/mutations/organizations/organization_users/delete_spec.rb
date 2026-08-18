# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Organizations::OrganizationUsers::Delete, feature_category: :organization do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:admin) }

  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  let(:organization_owner) { create(:organization_owner, organization: organization) }
  let(:organization_user) do
    create(:organization_user, :without_common_organization, organization: organization)
  end

  let(:mutation) { graphql_mutation(:organization_user_delete, params) }
  let(:params) do
    {
      id: organization_user.to_global_id.to_s
    }
  end

  subject(:delete_organization_user) { post_graphql_mutation(mutation, current_user: current_user) }

  def add_membership_to(organization_user)
    create(:organization_user, organization: other_organization, user: organization_user.user)
  end

  def mutation_response
    graphql_mutation_response(:organization_user_delete)
  end

  it { expect(described_class).to require_graphql_authorizations(:delete_organization_user) }

  it_behaves_like 'authorizing granular token permissions for GraphQL', :delete_organization_user do
    let(:user) { current_user }
    let(:boundary_object) { :instance }
    let(:mutation) { graphql_mutation(:organization_user_delete, params, 'errors') }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }

    before do
      add_membership_to(organization_user)
    end
  end

  context 'when the user does not have permission' do
    let(:current_user) { organization_user.user }

    before do
      add_membership_to(organization_user)
    end

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not delete the organization user' do
      expect { delete_organization_user }.not_to change { Organizations::OrganizationUser.count }
    end
  end

  context 'when the user has permission' do
    context 'when the organization user belongs to multiple organizations' do
      before do
        add_membership_to(organization_user)
      end

      it 'deletes the organization user' do
        expect { delete_organization_user }.to change { Organizations::OrganizationUser.count }.by(-1)

        expect(graphql_data_at(:organization_user_delete, :organization_user, :id))
          .to eq(organization_user.to_global_id.to_s)
        expect(mutation_response['errors']).to be_empty
      end
    end

    context 'when deleting the last owner' do
      let(:organization_user) { organization_owner }

      before do
        add_membership_to(organization_owner)
      end

      # The delete_organization_user ability denies the last owner, so this fails authorization before the
      # service runs and surfaces as a top-level error rather than a mutation error.
      it_behaves_like 'a mutation that returns a top-level access error'

      it 'does not delete the organization user' do
        expect { delete_organization_user }.not_to change { Organizations::OrganizationUser.count }
      end
    end

    context 'when the organization is the home organization of the organization user' do
      before do
        add_membership_to(organization_user)
        organization_user.user.update!(organization: organization)
      end

      it 'returns an error and does not delete the organization user' do
        expect { delete_organization_user }.not_to change { Organizations::OrganizationUser.count }

        expect(mutation_response['errors'])
          .to contain_exactly(_('You cannot delete a user from their home organization'))
      end
    end

    context 'when the organization user belongs to only one organization' do
      before do
        organization_user
      end

      it 'returns an error and does not delete the organization user' do
        expect { delete_organization_user }.not_to change { Organizations::OrganizationUser.count }

        expect(mutation_response['errors'])
          .to contain_exactly(_('A user must associate with at least one organization'))
      end
    end
  end
end
