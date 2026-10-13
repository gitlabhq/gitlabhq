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

      let!(:current_user) { create(:user) }

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

    context 'when a user removes their own membership' do
      let!(:organization_user) do
        create(:organization_user, :without_common_organization, organization: organization)
      end

      let(:current_user) { organization_user.user }

      before do
        add_membership_to(organization_user)
      end

      it 'deletes the organization user' do
        expect { response }.to change { Organizations::OrganizationUser.count }.by(-1)

        expect(response).to be_success
        expect(deleted_organization_user).to be_instance_of(Organizations::OrganizationUser)
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

      context 'when the user has a membership in a group or project in the organization' do
        let!(:organization_user) do
          create(:organization_user, :without_common_organization, organization: organization)
        end

        let(:user) { organization_user.user }

        before do
          add_membership_to(organization_user)
        end

        it 'removes a direct group membership and deletes the organization user' do
          group = create(:group, organization: organization)
          group.add_developer(user)

          expect { response }.to change { Organizations::OrganizationUser.count }.by(-1)

          expect(response).to be_success
          expect(group.member?(user)).to be(false)
        end

        it 'removes a direct project membership and deletes the organization user' do
          project = create(:project, organization: organization)
          project.add_developer(user)

          expect { response }.to change { Organizations::OrganizationUser.count }.by(-1)

          expect(response).to be_success
          expect(project.member?(user)).to be(false)
        end

        it 'removes memberships across the group hierarchy' do
          group = create(:group, organization: organization)
          subgroup = create(:group, parent: group, organization: organization)
          project = create(:project, group: subgroup, organization: organization)
          group.add_developer(user)
          subgroup.add_developer(user)
          project.add_developer(user)

          expect { response }.to change { Organizations::OrganizationUser.count }.by(-1)

          expect(response).to be_success
          expect(group.member?(user)).to be(false)
          expect(subgroup.member?(user)).to be(false)
          expect(project.member?(user)).to be(false)
        end

        it 'logs the removal with the count of cascaded memberships' do
          group = create(:group, organization: organization)
          group.add_developer(user)

          expect(Gitlab::AppLogger).to receive(:info).with(
            message: 'Removed user from organization and cascaded membership removal',
            Labkit::Fields::GL_ORGANIZATION_ID => organization.id,
            target_user_id: user.id,
            current_user_id: current_user.id,
            removed_memberships_count: 1
          )

          expect(response).to be_success
        end

        it 'leaves memberships in other organizations untouched' do
          group = create(:group, organization: other_organization)
          group.add_developer(user)

          expect { response }.to change { Organizations::OrganizationUser.count }.by(-1)

          expect(response).to be_success
          expect(group.member?(user)).to be(true)
        end

        it 'deletes the organization user when the membership is a pending access request' do
          group = create(:group, organization: organization)
          create(:group_member, :access_request, group: group, user: user)

          expect { response }.to change { Organizations::OrganizationUser.count }.by(-1)

          expect(response).to be_success
        end

        it 'does not destroy the organization user when a group membership removal fails' do
          group = create(:group, organization: organization)
          group.add_developer(user)

          allow_next_instance_of(::Members::DestroyService) do |service|
            allow(service).to receive(:execute)
          end

          expect { response }.not_to change { Organizations::OrganizationUser.count }

          expect(response).to be_error
          expect(response.reason).to eq(:membership_removal_failed)
          expect(response.message).to match_array(
            [_('Failed to remove the user from groups or projects in the organization')]
          )
          expect(group.member?(user)).to be(true)
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

          allow(organization_user).to receive(:destroy!)
            .and_raise(ActiveRecord::RecordNotDestroyed.new('failed', organization_user))
        end

        it 'returns an error' do
          expect(response).to be_error
          expect(response.message).to match_array([_('Failed to delete the organization user')])
        end
      end
    end
  end

  describe 'Organization Administrator role sync' do
    let_it_be(:organization) { create(:organization) }
    let_it_be(:other_owner) { create(:organization_owner, organization: organization) }

    subject(:execute) do
      described_class.new(organization_user, current_user: current_user).execute
    end

    before do
      allow(Authz::Organizations::OwnerRoleSync).to receive(:enabled?).and_return(true)
    end

    context 'when removing an owner' do
      let_it_be_with_refind(:organization_owner) { create(:organization_owner, organization: organization) }
      let(:organization_user) { organization_owner }
      let(:current_user) { other_owner.user }

      before_all do
        # A user must remain associated with at least one organization, so the
        # target needs a second membership for the destroy itself to succeed.
        create(:organization_user, user: organization_owner.user)
      end

      it 'enqueues RevokeOwnerRoleWorker with the acting user as the third argument' do
        expect(Authz::Organizations::RevokeOwnerRoleWorker).to receive(:perform_async)
          .with(organization.id, organization_owner.user_id, other_owner.user.id)

        execute
      end

      context 'when the owner removes themselves' do
        let(:current_user) { organization_owner.user }

        it 'enqueues RevokeOwnerRoleWorker with themselves as the acting user' do
          expect(Authz::Organizations::RevokeOwnerRoleWorker).to receive(:perform_async)
            .with(organization.id, organization_owner.user_id, organization_owner.user_id)

          execute
        end
      end

      context 'when the owner role sync is unavailable' do
        before do
          allow(Authz::Organizations::OwnerRoleSync).to receive(:enabled?).and_return(false)
        end

        it 'does not enqueue RevokeOwnerRoleWorker' do
          expect(Authz::Organizations::RevokeOwnerRoleWorker).not_to receive(:perform_async)

          execute
        end
      end

      context 'when the removal fails' do
        let(:organization_user) { create(:organization_owner, organization: organization) }

        before do
          create(:organization_user, user: organization_user.user)
          allow(organization_user).to receive(:destroy!)
            .and_raise(ActiveRecord::RecordNotDestroyed.new('failed', organization_user))
        end

        it 'does not enqueue RevokeOwnerRoleWorker' do
          expect(Authz::Organizations::RevokeOwnerRoleWorker).not_to receive(:perform_async)

          execute
        end
      end
    end

    context 'when removing a non-owner' do
      let(:organization_user) { create(:organization_user, organization: organization) }
      let(:current_user) { other_owner.user }

      it 'does not enqueue RevokeOwnerRoleWorker' do
        expect(Authz::Organizations::RevokeOwnerRoleWorker).not_to receive(:perform_async)

        execute
      end
    end
  end
end
