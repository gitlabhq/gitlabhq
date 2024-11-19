# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Organizations::OrganizationUsers::Update, feature_category: :cell do
  include GraphqlHelpers

  let_it_be(:organization) { create(:organization) }
  let_it_be(:organization_owner) { create(:organization_owner, organization: organization) }
  let_it_be_with_reload(:organization_user) { create(:organization_user, organization: organization) }

  let(:mutation) { graphql_mutation(:organization_user_update, params) }
  let(:access_level) { 'OWNER' }
  let(:params) do
    {
      id: organization_user.to_global_id.to_s,
      access_level: access_level
    }
  end

  subject(:update_organization_user) { post_graphql_mutation(mutation, current_user: current_user) }

  it { expect(described_class).to require_graphql_authorizations(:admin_organization) }

  def mutation_response
    graphql_mutation_response(:organization_user_update)
  end

  context 'when the user does not have permission' do
    let(:current_user) { organization_user.user }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not update the organization user' do
      initial_access_level = organization_user.access_level

      update_organization_user
      organization_user.reset

      expect(organization_user.access_level).to eq(initial_access_level)
    end
  end

  context 'when the user has permission' do
    let(:current_user) { organization_owner.user }

    let(:attribute_hash) do
      {
        "accessLevel" => { "integerValue" => 50, "stringValue" => "OWNER" },
        "id" => organization_user.to_global_id.to_s
      }
    end

    shared_examples 'updates the organization user' do
      specify do
        update_organization_user

        expect(graphql_data_at(:organization_user_update, :organization_user)).to match a_hash_including(attribute_hash)
        expect(mutation_response['errors']).to be_empty
      end
    end

    context 'when updating access level of last owner' do
      let_it_be(:organization_user) { organization_owner }

      let(:access_level) { 'DEFAULT' }

      it 'returns an error' do
        update_organization_user

        error_message = _('You cannot change the access of the last owner from the organization')
        expect(mutation_response['errors']).to contain_exactly(error_message)
      end
    end

    context 'when the organization user is the not last owner' do
      let_it_be(:organization_user) { organization_owner }
      let_it_be(:organization_owner_2) { create(:organization_owner, organization: organization) }

      it_behaves_like 'updates the organization user'
    end
  end
end
