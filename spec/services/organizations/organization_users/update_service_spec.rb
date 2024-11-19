# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationUsers::UpdateService, feature_category: :cell do
  describe '#execute' do
    let_it_be(:organization) { create(:organization) }
    let_it_be_with_reload(:organization_user) { create(:organization_user, organization: organization) }

    let(:access_level) { Gitlab::Access::OWNER }
    let(:params) { { access_level: access_level } }
    let(:updated_organization_user) { response.payload[:organization_user] }

    subject(:response) { described_class.new(organization_user, current_user: current_user, params: params).execute }

    context 'when user does not have permission' do
      let(:current_user) { organization_user.user }

      it 'returns an error' do
        expect(response).to be_error

        error_message = response.message
        expect(error_message).to match_array([_('You have insufficient permissions to update the organization user')])
      end
    end

    context 'when user has permission' do
      let_it_be(:organization_owner) { create(:organization_owner, organization: organization) }

      let(:current_user) { organization_owner.user }

      shared_examples 'updates the organization user' do
        specify do
          expect(response).to be_success
          expect(updated_organization_user).to be_instance_of(Organizations::OrganizationUser)
          expect(updated_organization_user.access_level_before_type_cast).to eq(access_level)
        end
      end

      it_behaves_like 'updates the organization user'

      context 'when the organization user is the last owner' do
        let_it_be(:organization_user) { organization_owner }

        context 'when new access level is owner' do
          specify { expect(response).to be_success }
        end

        context 'when new access level is less than owner' do
          let(:access_level) { 'default' }

          it 'returns an error' do
            expect(response).to be_error

            error_message = _('You cannot change the access of the last owner from the organization')
            expect(response.message).to contain_exactly(error_message)
          end
        end
      end

      context 'when the organization user is the not last owner' do
        let_it_be(:organization_user) { organization_owner }
        let_it_be(:organization_owner_2) { create(:organization_owner, organization: organization) }

        it_behaves_like 'updates the organization user'
      end

      context 'when the organization user is not updated' do
        it 'returns an error' do
          expect(organization_user).to receive(:update).and_return(false)
          expect(response).to be_error
          expect(response.message).to match_array([_('Failed to update the organization user')])
        end
      end
    end
  end
end
