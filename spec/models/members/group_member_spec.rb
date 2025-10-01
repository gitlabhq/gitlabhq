# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupMember, feature_category: :groups_and_projects do
  describe 'default values' do
    subject(:goup_member) { build(:group_member) }

    it { expect(goup_member.source_type).to eq(described_class::SOURCE_TYPE) }
  end

  context 'scopes' do
    let_it_be(:user_1) { create(:user) }
    let_it_be(:user_2) { create(:user) }
    let_it_be(:user_3) { create(:user) }

    let_it_be(:group_1) { create(:group) }
    let_it_be(:group_2) { create(:group) }

    it 'counts users by group ID' do
      group_1.add_owner(user_1)
      group_1.add_owner(user_2)
      group_2.add_owner(user_1)

      expect(described_class.count_users_by_group_id).to eq(group_1.id => 2, group_2.id => 1)
    end

    describe '.of_ldap_type' do
      it 'returns ldap type users' do
        group_member = create(:group_member, :ldap)

        expect(described_class.of_ldap_type).to eq([group_member])
      end
    end
  end

  describe '.access_level_roles' do
    it 'returns Gitlab::Access.options_with_owner' do
      expect(described_class.access_level_roles).to eq(Gitlab::Access.options_with_owner)
    end
  end

  describe '.max_access_members' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }

    let_it_be(:user) { create(:user) }
    let_it_be(:developer_member) { create(:group_member, :developer, group: group, user: user) }

    let(:group_ids) { [group.id] }

    subject { described_class.max_access_members(group_ids, user) }

    it "returns user's max access level" do
      is_expected.to contain_exactly(developer_member)
    end

    describe 'when user has different member access level in a group hierarchy' do
      let_it_be(:owner_member) { create(:group_member, :owner, group: subgroup, user: user) }

      describe 'when group has no inherited access level' do
        it "returns user's max access level" do
          is_expected.to contain_exactly(developer_member)
        end
      end

      describe 'when group has inherited access level' do
        let(:group_ids) { [subgroup.id] }

        it "returns user's max access level" do
          is_expected.to contain_exactly(owner_member)
        end
      end
    end
  end

  describe '#prevent_role_assignement?' do
    let_it_be(:group) { create(:group) }
    let_it_be_with_reload(:current_user) { create(:user) }
    let_it_be_with_reload(:member) do
      create(:group_member, access_level: Gitlab::Access::GUEST, group: group)
    end

    let(:access_level) { Gitlab::Access::GUEST }
    let(:params) { { access_level: access_level } }

    subject(:prevent_assignement?) { member.prevent_role_assignement?(current_user, params) }

    context 'when current user is a DEVELOPER' do
      before do
        group.add_developer(current_user)
      end

      context 'without assigning_access_level param' do
        let(:access_level) { nil }

        it 'returns false' do
          expect(prevent_assignement?).to be(false)
        end
      end

      context 'with MAINTAINER as access_role param' do
        let(:access_level) { Gitlab::Access::MAINTAINER }

        it 'returns true' do
          expect(prevent_assignement?).to be(true)
        end
      end
    end

    context 'when current user is a MAINTAINER' do
      before do
        group.add_maintainer(current_user)
      end

      context 'without assigning_access_level param' do
        let(:access_level) { nil }

        it 'returns true' do
          expect(prevent_assignement?).to be(false)
        end
      end

      context 'with OWNER as access_role param' do
        let(:access_level) { Gitlab::Access::OWNER }

        it 'returns false' do
          expect(prevent_assignement?).to be(true)
        end
      end
    end

    context 'when current user is an admin', :enable_admin_mode do
      before do
        current_user.update!(admin: true)
      end

      context 'without assigning_access_level param' do
        let(:access_level) { nil }

        it 'returns false' do
          expect(prevent_assignement?).to be(false)
        end
      end

      context 'with OWNER as access_role param' do
        let(:access_level) { Gitlab::Access::OWNER }

        it 'returns false' do
          expect(prevent_assignement?).to be(false)
        end
      end
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

  describe '#last_owner_of_the_group?' do
    let_it_be(:parent_group) { create(:group) }
    let_it_be(:group) { create(:group, parent: parent_group) }
    let_it_be(:group_member) { create(:group_member, :owner, source: group) }

    subject { group_member.last_owner_of_the_group? }

    context 'when overridden by last_owner instance variable' do
      before do
        group_member.last_owner = last_owner
      end

      after do
        group_member.last_owner = nil
      end

      context 'and it is set to true' do
        let(:last_owner) { true }

        it { is_expected.to be(true) }
      end

      context 'and it is set to false' do
        let(:last_owner) { false }

        it { is_expected.to be(false) }
      end
    end

    context 'when member is an owner' do
      context 'and there are no other owners' do
        it { is_expected.to be(true) }

        context 'and member is also owner of a parent group' do
          before do
            parent_group.add_owner(group_member.user)
          end

          after do
            parent_group.members.delete_all
          end

          it { is_expected.to be(false) }
        end
      end

      context 'and there is another owner' do
        context 'and that other owner is a project bot' do
          let(:project_bot) { create(:user, :project_bot) }
          let!(:other_owner_bot) { create(:group_member, :owner, source: group, user: project_bot) }

          it { is_expected.to be(true) }
        end

        context 'and that other owner is not a project bot' do
          let(:other_user) { create(:user) }
          let!(:other_owner) { create(:group_member, :owner, source: group, user: other_user) }

          it { is_expected.to be(false) }
        end
      end
    end

    context 'when member is not an owner' do
      let_it_be(:group_member) { build(:group_member, :guest) }

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
