# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupMember do
  describe 'default values' do
    subject(:goup_member) { build(:group_member) }

    it { expect(goup_member.source_type).to eq(described_class::SOURCE_TYPE) }
  end

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
      group = create :group
      group_member = build :group_member, user: user, group: group

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

  describe '#last_owner_of_the_group?' do
    context 'when member is an owner' do
      let_it_be(:group_member) { build(:group_member, :owner) }

      using RSpec::Parameterized::TableSyntax

      where(:member_last_owner?, :member_last_blocked_owner?, :expected) do
        false | false | false
        true  | false | true
        false | true  | true
        true  | true  | true
      end

      with_them do
        it "returns expected" do
          allow(group_member.group).to receive(:member_last_owner?).with(group_member).and_return(member_last_owner?)
          allow(group_member.group).to receive(:member_last_blocked_owner?)
            .with(group_member)
            .and_return(member_last_blocked_owner?)

          expect(group_member.last_owner_of_the_group?).to be(expected)
        end
      end
    end

    context 'when member is not an owner' do
      let_it_be(:group_member) { build(:group_member, :guest) }

      subject { group_member.last_owner_of_the_group? }

      it { is_expected.to be(false) }
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
        group = create(:group)
        member = build(:group_member, group: group)
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

    shared_examples_for 'calls AuthorizedProjectsWorker inline to recalculate authorizations' do
      # this is inline with the overridden behaviour in stubbed_member.rb
      it 'calls AuthorizedProjectsWorker inline to recalculate authorizations' do
        worker_instance = AuthorizedProjectsWorker.new
        expect(AuthorizedProjectsWorker).to receive(:new).and_return(worker_instance)
        expect(worker_instance).to receive(:perform).with(user.id)

        action
      end
    end

    context 'on create' do
      let(:action) { group.add_member(user, Gitlab::Access::GUEST) }

      it 'changes access level' do
        expect { action }.to change { user.can?(:guest_access, project_a) }.from(false).to(true)
          .and change { user.can?(:guest_access, project_b) }.from(false).to(true)
          .and change { user.can?(:guest_access, project_c) }.from(false).to(true)
      end

      it_behaves_like 'calls AuthorizedProjectsWorker inline to recalculate authorizations'
    end

    context 'on update' do
      before do
        group.add_member(user, Gitlab::Access::GUEST)
      end

      let(:action) { group.members.find_by(user: user).update!(access_level: Gitlab::Access::DEVELOPER) }

      it 'changes access level' do
        expect { action }.to change { user.can?(:developer_access, project_a) }.from(false).to(true)
          .and change { user.can?(:developer_access, project_b) }.from(false).to(true)
          .and change { user.can?(:developer_access, project_c) }.from(false).to(true)
      end

      it_behaves_like 'calls AuthorizedProjectsWorker inline to recalculate authorizations'
    end

    context 'on destroy' do
      before do
        group.add_member(user, Gitlab::Access::GUEST)
      end

      let(:action) { group.members.find_by(user: user).destroy! }

      it 'changes access level' do
        expect { action }.to change { user.can?(:guest_access, project_a) }.from(true).to(false)
          .and change { user.can?(:guest_access, project_b) }.from(true).to(false)
          .and change { user.can?(:guest_access, project_c) }.from(true).to(false)
      end

      it_behaves_like 'calls AuthorizedProjectsWorker inline to recalculate authorizations'
    end
  end
end
