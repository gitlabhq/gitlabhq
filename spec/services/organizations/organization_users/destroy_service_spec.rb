# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationUsers::DestroyService, feature_category: :organization do
  describe '#execute' do
    let(:organization) { create(:organization) }
    let(:other_organization) { create(:organization) }

    let(:deleted_organization_user) { response.payload[:organization_user] }

    subject(:response) { described_class.new(organization_user, current_user: current_user).execute }

    def add_membership_to(organization_user)
      create(:organization_user, organization: other_organization, user: organization_user.user)
    end

    context 'when user does not have permission' do
      let!(:organization_user) do
        create(:organization_user, :without_common_organization, organization: organization)
      end

      let(:current_user) { organization_user.user }

      before do
        add_membership_to(organization_user)
      end

      it 'returns an error' do
        expect { response }.not_to change { Organizations::OrganizationUser.count }

        expect(response).to be_error
        expect(response.reason).to eq(:forbidden)
        expect(response.message).to match_array(
          [_('You have insufficient permissions to delete the organization user')]
        )
      end
    end

    context 'when user has permission' do
      let!(:organization_owner) do
        create(:organization_owner, :without_common_organization, organization: organization)
      end

      let(:current_user) { organization_owner.user }

      context 'when the organization user belongs to multiple organizations' do
        let!(:organization_user) do
          create(:organization_user, :without_common_organization, organization: organization)
        end

        before do
          add_membership_to(organization_user)
        end

        it 'deletes the organization user' do
          expect { response }.to change { Organizations::OrganizationUser.count }.by(-1)

          expect(response).to be_success
          expect(deleted_organization_user).to be_instance_of(Organizations::OrganizationUser)
        end
      end

      context 'when the organization user is the last owner' do
        let(:organization_user) { organization_owner }

        before do
          add_membership_to(organization_owner)
        end

        it 'returns a last owner error' do
          expect { response }.not_to change { Organizations::OrganizationUser.count }

          expect(response).to be_error
          expect(response.reason).to eq(:last_owner)
          expect(response.message).to match_array(
            [_('You cannot delete the last owner of the organization')]
          )
        end
      end

      context 'when the organization is the home organization of the organization user' do
        let!(:organization_user) do
          create(:organization_user, :without_common_organization, organization: organization)
        end

        before do
          add_membership_to(organization_user)
          organization_user.user.update!(organization: organization)
        end

        it 'returns an error' do
          expect { response }.not_to change { Organizations::OrganizationUser.count }

          expect(response).to be_error
          expect(response.reason).to eq(:home_organization)
          expect(response.message).to match_array(
            [_('You cannot delete a user from their home organization')]
          )
        end
      end

      context 'when the organization user belongs to only one organization' do
        let!(:organization_user) do
          create(:organization_user, :without_common_organization, organization: organization)
        end

        it 'returns an error' do
          expect { response }.not_to change { Organizations::OrganizationUser.count }

          expect(response).to be_error
          expect(response.message).to match_array(
            [_('A user must associate with at least one organization')]
          )
        end
      end

      context 'when the organization user is not deleted' do
        let!(:organization_user) do
          create(:organization_user, :without_common_organization, organization: organization)
        end

        before do
          add_membership_to(organization_user)

          allow(organization_user).to receive(:destroy)
          allow(organization_user).to receive(:destroyed?).and_return(false)
        end

        it 'returns an error' do
          expect(response).to be_error
          expect(response.message).to match_array([_('Failed to delete the organization user')])
        end
      end
    end
  end
end
