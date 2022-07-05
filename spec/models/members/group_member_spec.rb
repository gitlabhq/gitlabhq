# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupMember do
  context 'scopes' do
    let_it_be(:user_1) { create(:user) }
    let_it_be(:user_2) { create(:user) }

    it 'counts users by group ID' do
      group_1 = create(:group)
      group_2 = create(:group)

      group_1.add_owner(user_1)
      group_1.add_owner(user_2)
      group_2.add_owner(user_1)

      expect(described_class.count_users_by_group_id).to eq(group_1.id => 2,
                                                            group_2.id => 1)
    end

    describe '.of_ldap_type' do
      it 'returns ldap type users' do
        group_member = create(:group_member, :ldap)

        expect(described_class.of_ldap_type).to eq([group_member])
      end
    end

    describe '.with_user' do
      it 'returns requested user' do
        group_member = create(:group_member, user: user_2)
        create(:group_member, user: user_1)

        expect(described_class.with_user(user_2)).to eq([group_member])
      end
    end
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:update_two_factor_requirement).to(:user).allow_nil }
  end

  describe '.access_level_roles' do
    it 'returns Gitlab::Access.options_with_owner' do
      expect(described_class.access_level_roles).to eq(Gitlab::Access.options_with_owner)
    end
  end

  describe '#permissible_access_level_roles' do
    let_it_be(:group) { create(:group) }

    it 'returns Gitlab::Access.options_with_owner' do
      result = described_class.permissible_access_level_roles(group.first_owner, group)

      expect(result).to eq(Gitlab::Access.options_with_owner)
    end
  end

  it_behaves_like 'members notifications', :group

  describe '#namespace_id' do
    subject { build(:group_member, source_id: 1).namespace_id }

    it { is_expected.to eq 1 }
  end

  describe '#real_source_type' do
    subject { create(:group_member).real_source_type }

    it { is_expected.to eq 'Group' }
  end

  describe '#update_two_factor_requirement' do
    it 'is called after creation and deletion' do
      user = build :user
      group_member = build :group_member, user: user

      expect(user).to receive(:update_two_factor_requirement)

      group_member.save!

      expect(user).to receive(:update_two_factor_requirement)

      group_member.destroy!
    end
  end

  describe '#destroy' do
    context 'for an orphaned member' do
      let!(:orphaned_group_member) do
        create(:group_member).tap { |member| member.update_column(:user_id, nil) }
      end

      it 'does not raise an error' do
        expect { orphaned_group_member.destroy! }.not_to raise_error
      end
    end
  end

  describe '#after_accept_invite' do
    it 'calls #update_two_factor_requirement' do
      email = 'foo@email.com'
      user = build(:user, email: email)
      group = create(:group, require_two_factor_authentication: true)
      group_member = create(:group_member, group: group, invite_token: '1234', invite_email: email)

      expect(user).to receive(:require_two_factor_authentication_from_group).and_call_original

      group_member.accept_invite!(user)

      expect(user.require_two_factor_authentication_from_group).to be_truthy
    end
  end

  context 'access levels' do
    context 'with parent group' do
      it_behaves_like 'inherited access level as a member of entity' do
        let(:entity) { create(:group, parent: parent_entity) }
      end
    end

    context 'with parent group and a sub subgroup' do
      it_behaves_like 'inherited access level as a member of entity' do
        let(:subgroup) { create(:group, parent: parent_entity) }
        let(:entity) { create(:group, parent: subgroup) }
      end

      context 'when only the subgroup has the member' do
        it_behaves_like 'inherited access level as a member of entity' do
          let(:parent_entity) { create(:group, parent: create(:group)) }
          let(:entity) { create(:group, parent: parent_entity) }
        end
      end
    end
  end

  context 'when group member expiration date is updated' do
    let_it_be(:group_member) { create(:group_member) }

    it 'emails the user that their group membership expiry has changed' do
      expect_next_instance_of(NotificationService) do |notification|
        allow(notification).to receive(:updated_group_member_expiration).with(group_member)
      end

      group_member.update!(expires_at: 5.days.from_now)
    end
  end

  describe 'refresh_member_authorized_projects' do
    context 'when importing' do
      it 'does not refresh' do
        expect(UserProjectAccessChangedService).not_to receive(:new)

        member = build(:group_member)
        member.importing = true
        member.save!
      end
    end
  end

  context 'authorization refresh on addition/updation/deletion' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project_a) { create(:project, group: group) }
    let_it_be(:project_b) { create(:project, group: group) }
    let_it_be(:project_c) { create(:project, group: group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:affected_project_ids) { Project.id_in([project_a, project_b, project_c]).ids }

    before do
      stub_const(
        "#{described_class.name}::THRESHOLD_FOR_REFRESHING_AUTHORIZATIONS_VIA_PROJECTS",
        affected_project_ids.size - 1)
    end

    shared_examples_for 'calls UserProjectAccessChangedService to recalculate authorizations' do
      it 'calls UserProjectAccessChangedService to recalculate authorizations' do
        expect_next_instance_of(UserProjectAccessChangedService, user.id) do |service|
          expect(service).to receive(:execute).with(blocking: blocking)
        end

        action
      end
    end

    shared_examples_for 'tries to update permissions via refreshing authorizations for the affected projects' do
      context 'when the number of affected projects exceeds the set threshold' do
        it 'updates permissions via refreshing authorizations for the affected projects asynchronously' do
          expect_next_instance_of(
            AuthorizedProjectUpdate::ProjectAccessChangedService, affected_project_ids
          ) do |service|
            expect(service).to receive(:execute).with(blocking: false)
          end

          action
        end

        it 'calls AuthorizedProjectUpdate::UserRefreshFromReplicaWorker with a delay as a safety net' do
          expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to(
            receive(:bulk_perform_in)
              .with(1.hour,
                    [[user.id]],
                    batch_delay: 30.seconds, batch_size: 100)
          )

          action
        end
      end

      context 'when the number of affected projects does not exceed the set threshold' do
        before do
          stub_const(
            "#{described_class.name}::THRESHOLD_FOR_REFRESHING_AUTHORIZATIONS_VIA_PROJECTS",
            affected_project_ids.size + 1)
        end

        it_behaves_like 'calls UserProjectAccessChangedService to recalculate authorizations'
      end
    end

    context 'on create' do
      let(:action) { group.add_member(user, Gitlab::Access::GUEST) }
      let(:blocking) { true }

      it 'changes access level', :sidekiq_inline do
        expect { action }.to change { user.can?(:guest_access, project_a) }.from(false).to(true)
          .and change { user.can?(:guest_access, project_b) }.from(false).to(true)
          .and change { user.can?(:guest_access, project_c) }.from(false).to(true)
      end

      it_behaves_like 'tries to update permissions via refreshing authorizations for the affected projects'

      context 'when the feature flag `refresh_authorizations_via_affected_projects_on_group_membership` is disabled' do
        before do
          stub_feature_flags(refresh_authorizations_via_affected_projects_on_group_membership: false)
        end

        it_behaves_like 'calls UserProjectAccessChangedService to recalculate authorizations'
      end
    end

    context 'on update' do
      before do
        group.add_member(user, Gitlab::Access::GUEST)
      end

      let(:action) { group.members.find_by(user: user).update!(access_level: Gitlab::Access::DEVELOPER) }
      let(:blocking) { true }

      it 'changes access level', :sidekiq_inline do
        expect { action }.to change { user.can?(:developer_access, project_a) }.from(false).to(true)
          .and change { user.can?(:developer_access, project_b) }.from(false).to(true)
          .and change { user.can?(:developer_access, project_c) }.from(false).to(true)
      end

      it_behaves_like 'tries to update permissions via refreshing authorizations for the affected projects'

      context 'when the feature flag `refresh_authorizations_via_affected_projects_on_group_membership` is disabled' do
        before do
          stub_feature_flags(refresh_authorizations_via_affected_projects_on_group_membership: false)
        end

        it_behaves_like 'calls UserProjectAccessChangedService to recalculate authorizations'
      end
    end

    context 'on destroy' do
      before do
        group.add_member(user, Gitlab::Access::GUEST)
      end

      let(:action) { group.members.find_by(user: user).destroy! }
      let(:blocking) { false }

      it 'changes access level', :sidekiq_inline do
        expect { action }.to change { user.can?(:guest_access, project_a) }.from(true).to(false)
          .and change { user.can?(:guest_access, project_b) }.from(true).to(false)
          .and change { user.can?(:guest_access, project_c) }.from(true).to(false)
      end

      it_behaves_like 'tries to update permissions via refreshing authorizations for the affected projects'

      context 'when the feature flag `refresh_authorizations_via_affected_projects_on_group_membership` is disabled' do
        before do
          stub_feature_flags(refresh_authorizations_via_affected_projects_on_group_membership: false)
        end

        it_behaves_like 'calls UserProjectAccessChangedService to recalculate authorizations'
      end
    end
  end
end
