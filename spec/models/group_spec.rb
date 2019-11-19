# frozen_string_literal: true

require 'spec_helper'

describe Group do
  let!(:group) { create(:group) }

  describe 'associations' do
    it { is_expected.to have_many :projects }
    it { is_expected.to have_many(:group_members).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:group_members) }
    it { is_expected.to have_many(:owners).through(:group_members) }
    it { is_expected.to have_many(:requesters).dependent(:destroy) }
    it { is_expected.to have_many(:members_and_requesters) }
    it { is_expected.to have_many(:project_group_links).dependent(:destroy) }
    it { is_expected.to have_many(:shared_projects).through(:project_group_links) }
    it { is_expected.to have_many(:notification_settings).dependent(:destroy) }
    it { is_expected.to have_many(:labels).class_name('GroupLabel') }
    it { is_expected.to have_many(:variables).class_name('Ci::GroupVariable') }
    it { is_expected.to have_many(:uploads) }
    it { is_expected.to have_one(:chat_team) }
    it { is_expected.to have_many(:custom_attributes).class_name('GroupCustomAttribute') }
    it { is_expected.to have_many(:badges).class_name('GroupBadge') }
    it { is_expected.to have_many(:cluster_groups).class_name('Clusters::Group') }
    it { is_expected.to have_many(:clusters).class_name('Clusters::Cluster') }
    it { is_expected.to have_many(:container_repositories) }

    describe '#members & #requesters' do
      let(:requester) { create(:user) }
      let(:developer) { create(:user) }
      before do
        group.request_access(requester)
        group.add_developer(developer)
      end

      it_behaves_like 'members and requesters associations' do
        let(:namespace) { group }
      end
    end
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Referable) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :path }
    it { is_expected.not_to validate_presence_of :owner }
    it { is_expected.to validate_presence_of :two_factor_grace_period }
    it { is_expected.to validate_numericality_of(:two_factor_grace_period).is_greater_than_or_equal_to(0) }

    describe 'path validation' do
      it 'rejects paths reserved on the root namespace when the group has no parent' do
        group = build(:group, path: 'api')

        expect(group).not_to be_valid
      end

      it 'allows root paths when the group has a parent' do
        group = build(:group, path: 'api', parent: create(:group))

        expect(group).to be_valid
      end

      it 'rejects any wildcard paths when not a top level group' do
        group = build(:group, path: 'tree', parent: create(:group))

        expect(group).not_to be_valid
      end
    end

    describe '#notification_settings' do
      let(:user) { create(:user) }
      let(:group) { create(:group) }
      let(:sub_group) { create(:group, parent_id: group.id) }

      before do
        group.add_developer(user)
        sub_group.add_maintainer(user)
      end

      it 'also gets notification settings from parent groups' do
        expect(sub_group.notification_settings.size).to eq(2)
        expect(sub_group.notification_settings).to include(group.notification_settings.first)
      end

      context 'when sub group is deleted' do
        it 'does not delete parent notification settings' do
          expect do
            sub_group.destroy
          end.to change { NotificationSetting.count }.by(-1)
        end
      end
    end

    describe '#notification_email_for' do
      let(:user) { create(:user) }
      let(:group) { create(:group) }
      let(:subgroup) { create(:group, parent: group) }

      let(:group_notification_email) { 'user+group@example.com' }
      let(:subgroup_notification_email) { 'user+subgroup@example.com' }

      subject { subgroup.notification_email_for(user) }

      context 'when both group notification emails are set' do
        it 'returns subgroup notification email' do
          create(:notification_setting, user: user, source: group, notification_email: group_notification_email)
          create(:notification_setting, user: user, source: subgroup, notification_email: subgroup_notification_email)

          is_expected.to eq(subgroup_notification_email)
        end
      end

      context 'when subgroup notification email is blank' do
        it 'returns parent group notification email' do
          create(:notification_setting, user: user, source: group, notification_email: group_notification_email)
          create(:notification_setting, user: user, source: subgroup, notification_email: '')

          is_expected.to eq(group_notification_email)
        end
      end

      context 'when only the parent group notification email is set' do
        it 'returns parent group notification email' do
          create(:notification_setting, user: user, source: group, notification_email: group_notification_email)

          is_expected.to eq(group_notification_email)
        end
      end
    end

    describe '#visibility_level_allowed_by_parent' do
      let(:parent) { create(:group, :internal) }
      let(:sub_group) { build(:group, parent_id: parent.id) }

      context 'without a parent' do
        it 'is valid' do
          sub_group.parent_id = nil

          expect(sub_group).to be_valid
        end
      end

      context 'with a parent' do
        context 'when visibility of sub group is greater than the parent' do
          it 'is invalid' do
            sub_group.visibility_level = Gitlab::VisibilityLevel::PUBLIC

            expect(sub_group).to be_invalid
          end
        end

        context 'when visibility of sub group is lower or equal to the parent' do
          [Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PRIVATE].each do |level|
            it 'is valid' do
              sub_group.visibility_level = level

              expect(sub_group).to be_valid
            end
          end
        end
      end
    end

    describe '#visibility_level_allowed_by_projects' do
      let!(:internal_group) { create(:group, :internal) }
      let!(:internal_project) { create(:project, :internal, group: internal_group) }

      context 'when group has a lower visibility' do
        it 'is invalid' do
          internal_group.visibility_level = Gitlab::VisibilityLevel::PRIVATE

          expect(internal_group).to be_invalid
          expect(internal_group.errors[:visibility_level]).to include('private is not allowed since this group contains projects with higher visibility.')
        end
      end

      context 'when group has a higher visibility' do
        it 'is valid' do
          internal_group.visibility_level = Gitlab::VisibilityLevel::PUBLIC

          expect(internal_group).to be_valid
        end
      end
    end

    describe '#visibility_level_allowed_by_sub_groups' do
      let!(:internal_group) { create(:group, :internal) }
      let!(:internal_sub_group) { create(:group, :internal, parent: internal_group) }

      context 'when parent group has a lower visibility' do
        it 'is invalid' do
          internal_group.visibility_level = Gitlab::VisibilityLevel::PRIVATE

          expect(internal_group).to be_invalid
          expect(internal_group.errors[:visibility_level]).to include('private is not allowed since there are sub-groups with higher visibility.')
        end
      end

      context 'when parent group has a higher visibility' do
        it 'is valid' do
          internal_group.visibility_level = Gitlab::VisibilityLevel::PUBLIC

          expect(internal_group).to be_valid
        end
      end
    end
  end

  describe '.public_or_visible_to_user' do
    let!(:private_group)  { create(:group, :private)  }
    let!(:internal_group) { create(:group, :internal) }

    subject { described_class.public_or_visible_to_user(user) }

    context 'when user is nil' do
      let!(:user) { nil }

      it { is_expected.to match_array([group]) }
    end

    context 'when user' do
      let!(:user) { create(:user) }

      context 'when user does not have access to any private group' do
        it { is_expected.to match_array([internal_group, group]) }
      end

      context 'when user is a member of private group' do
        before do
          private_group.add_user(user, Gitlab::Access::DEVELOPER)
        end

        it { is_expected.to match_array([private_group, internal_group, group]) }
      end

      context 'when user is a member of private subgroup' do
        let!(:private_subgroup) { create(:group, :private, parent: private_group) }

        before do
          private_subgroup.add_user(user, Gitlab::Access::DEVELOPER)
        end

        it { is_expected.to match_array([private_subgroup, internal_group, group]) }
      end
    end
  end

  describe 'scopes' do
    let!(:private_group)  { create(:group, :private)  }
    let!(:internal_group) { create(:group, :internal) }

    describe 'public_only' do
      subject { described_class.public_only.to_a }

      it { is_expected.to eq([group]) }
    end

    describe 'public_and_internal_only' do
      subject { described_class.public_and_internal_only.to_a }

      it { is_expected.to match_array([group, internal_group]) }
    end

    describe 'non_public_only' do
      subject { described_class.non_public_only.to_a }

      it { is_expected.to match_array([private_group, internal_group]) }
    end
  end

  describe '#to_reference' do
    it 'returns a String reference to the object' do
      expect(group.to_reference).to eq "@#{group.name}"
    end
  end

  describe '#users' do
    it { expect(group.users).to eq(group.owners) }
  end

  describe '#human_name' do
    it { expect(group.human_name).to eq(group.name) }
  end

  describe '#add_user' do
    let(:user) { create(:user) }

    before do
      group.add_user(user, GroupMember::MAINTAINER)
    end

    it { expect(group.group_members.maintainers.map(&:user)).to include(user) }
  end

  describe '#add_users' do
    let(:user) { create(:user) }

    before do
      group.add_users([user.id], GroupMember::GUEST)
    end

    it "updates the group permission" do
      expect(group.group_members.guests.map(&:user)).to include(user)
      group.add_users([user.id], GroupMember::DEVELOPER)
      expect(group.group_members.developers.map(&:user)).to include(user)
      expect(group.group_members.guests.map(&:user)).not_to include(user)
    end
  end

  describe '#avatar_type' do
    let(:user) { create(:user) }

    before do
      group.add_user(user, GroupMember::MAINTAINER)
    end

    it "is true if avatar is image" do
      group.update_attribute(:avatar, 'uploads/avatar.png')
      expect(group.avatar_type).to be_truthy
    end

    it "is false if avatar is html page" do
      group.update_attribute(:avatar, 'uploads/avatar.html')
      expect(group.avatar_type).to eq(["file format is not supported. Please try one of the following supported formats: png, jpg, jpeg, gif, bmp, tiff, ico"])
    end
  end

  describe '#avatar_url' do
    let!(:group) { create(:group, :with_avatar) }
    let(:user) { create(:user) }

    context 'when avatar file is uploaded' do
      before do
        group.add_maintainer(user)
      end

      it 'shows correct avatar url' do
        expect(group.avatar_url).to eq(group.avatar.url)
        expect(group.avatar_url(only_path: false)).to eq([Gitlab.config.gitlab.url, group.avatar.url].join)
      end
    end
  end

  describe '.search' do
    it 'returns groups with a matching name' do
      expect(described_class.search(group.name)).to eq([group])
    end

    it 'returns groups with a partially matching name' do
      expect(described_class.search(group.name[0..2])).to eq([group])
    end

    it 'returns groups with a matching name regardless of the casing' do
      expect(described_class.search(group.name.upcase)).to eq([group])
    end

    it 'returns groups with a matching path' do
      expect(described_class.search(group.path)).to eq([group])
    end

    it 'returns groups with a partially matching path' do
      expect(described_class.search(group.path[0..2])).to eq([group])
    end

    it 'returns groups with a matching path regardless of the casing' do
      expect(described_class.search(group.path.upcase)).to eq([group])
    end
  end

  describe '#has_owner?' do
    before do
      @members = setup_group_members(group)
      create(:group_member, :invited, :owner, group: group)
    end

    it { expect(group.has_owner?(@members[:owner])).to be_truthy }
    it { expect(group.has_owner?(@members[:maintainer])).to be_falsey }
    it { expect(group.has_owner?(@members[:developer])).to be_falsey }
    it { expect(group.has_owner?(@members[:reporter])).to be_falsey }
    it { expect(group.has_owner?(@members[:guest])).to be_falsey }
    it { expect(group.has_owner?(@members[:requester])).to be_falsey }
    it { expect(group.has_owner?(nil)).to be_falsey }
  end

  describe '#has_maintainer?' do
    before do
      @members = setup_group_members(group)
      create(:group_member, :invited, :maintainer, group: group)
    end

    it { expect(group.has_maintainer?(@members[:owner])).to be_falsey }
    it { expect(group.has_maintainer?(@members[:maintainer])).to be_truthy }
    it { expect(group.has_maintainer?(@members[:developer])).to be_falsey }
    it { expect(group.has_maintainer?(@members[:reporter])).to be_falsey }
    it { expect(group.has_maintainer?(@members[:guest])).to be_falsey }
    it { expect(group.has_maintainer?(@members[:requester])).to be_falsey }
    it { expect(group.has_maintainer?(nil)).to be_falsey }
  end

  describe '#last_owner?' do
    before do
      @members = setup_group_members(group)
    end

    it { expect(group.last_owner?(@members[:owner])).to be_truthy }

    context 'with two owners' do
      before do
        create(:group_member, :owner, group: group)
      end

      it { expect(group.last_owner?(@members[:owner])).to be_falsy }
    end

    context 'with owners from a parent' do
      before do
        parent_group = create(:group)
        create(:group_member, :owner, group: parent_group)
        group.update(parent: parent_group)
      end

      it { expect(group.last_owner?(@members[:owner])).to be_falsy }
    end
  end

  describe '#lfs_enabled?' do
    context 'LFS enabled globally' do
      before do
        allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
      end

      it 'returns true when nothing is set' do
        expect(group.lfs_enabled?).to be_truthy
      end

      it 'returns false when set to false' do
        group.update_attribute(:lfs_enabled, false)

        expect(group.lfs_enabled?).to be_falsey
      end

      it 'returns true when set to true' do
        group.update_attribute(:lfs_enabled, true)

        expect(group.lfs_enabled?).to be_truthy
      end
    end

    context 'LFS disabled globally' do
      before do
        allow(Gitlab.config.lfs).to receive(:enabled).and_return(false)
      end

      it 'returns false when nothing is set' do
        expect(group.lfs_enabled?).to be_falsey
      end

      it 'returns false when set to false' do
        group.update_attribute(:lfs_enabled, false)

        expect(group.lfs_enabled?).to be_falsey
      end

      it 'returns false when set to true' do
        group.update_attribute(:lfs_enabled, true)

        expect(group.lfs_enabled?).to be_falsey
      end
    end
  end

  describe '#owners' do
    let(:owner) { create(:user) }
    let(:developer) { create(:user) }

    it 'returns the owners of a Group' do
      group.add_owner(owner)
      group.add_developer(developer)

      expect(group.owners).to eq([owner])
    end
  end

  def setup_group_members(group)
    members = {
      owner: create(:user),
      maintainer: create(:user),
      developer: create(:user),
      reporter: create(:user),
      guest: create(:user),
      requester: create(:user)
    }

    group.add_user(members[:owner], GroupMember::OWNER)
    group.add_user(members[:maintainer], GroupMember::MAINTAINER)
    group.add_user(members[:developer], GroupMember::DEVELOPER)
    group.add_user(members[:reporter], GroupMember::REPORTER)
    group.add_user(members[:guest], GroupMember::GUEST)
    group.request_access(members[:requester])

    members
  end

  describe '#web_url' do
    it 'returns the canonical URL' do
      expect(group.web_url).to include("groups/#{group.name}")
    end

    context 'nested group' do
      let(:nested_group) { create(:group, :nested) }

      it { expect(nested_group.web_url).to include("groups/#{nested_group.full_path}") }
    end
  end

  describe 'nested group' do
    subject { build(:group, :nested) }

    it { is_expected.to be_valid }
    it { expect(subject.parent).to be_kind_of(described_class) }
  end

  describe '#max_member_access_for_user' do
    context 'group shared with another group' do
      let(:parent_group_user) { create(:user) }
      let(:group_user) { create(:user) }
      let(:child_group_user) { create(:user) }

      let_it_be(:group_parent) { create(:group, :private) }
      let_it_be(:group) { create(:group, :private, parent: group_parent) }
      let_it_be(:group_child) { create(:group, :private, parent: group) }

      let_it_be(:shared_group_parent) { create(:group, :private) }
      let_it_be(:shared_group) { create(:group, :private, parent: shared_group_parent) }
      let_it_be(:shared_group_child) { create(:group, :private, parent: shared_group) }

      before do
        group_parent.add_owner(parent_group_user)
        group.add_owner(group_user)
        group_child.add_owner(child_group_user)

        create(:group_group_link, { shared_with_group: group,
                                    shared_group: shared_group,
                                    group_access: GroupMember::DEVELOPER })
      end

      context 'when feature flag share_group_with_group is enabled' do
        before do
          stub_feature_flags(share_group_with_group: true)
        end

        context 'with user in the group' do
          let(:user) { group_user }

          it 'returns correct access level' do
            expect(shared_group_parent.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
            expect(shared_group.max_member_access_for_user(user)).to eq(Gitlab::Access::DEVELOPER)
            expect(shared_group_child.max_member_access_for_user(user)).to eq(Gitlab::Access::DEVELOPER)
          end
        end

        context 'with user in the parent group' do
          let(:user) { parent_group_user }

          it 'returns correct access level' do
            expect(shared_group_parent.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
            expect(shared_group.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
            expect(shared_group_child.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
          end
        end

        context 'with user in the child group' do
          let(:user) { child_group_user }

          it 'returns correct access level' do
            expect(shared_group_parent.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
            expect(shared_group.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
            expect(shared_group_child.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
          end
        end
      end

      context 'when feature flag share_group_with_group is disabled' do
        before do
          stub_feature_flags(share_group_with_group: false)
        end

        context 'with user in the group' do
          let(:user) { group_user }

          it 'returns correct access level' do
            expect(shared_group_parent.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
            expect(shared_group.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
            expect(shared_group_child.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
          end
        end

        context 'with user in the parent group' do
          let(:user) { parent_group_user }

          it 'returns correct access level' do
            expect(shared_group_parent.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
            expect(shared_group.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
            expect(shared_group_child.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
          end
        end

        context 'with user in the child group' do
          let(:user) { child_group_user }

          it 'returns correct access level' do
            expect(shared_group_parent.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
            expect(shared_group.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
            expect(shared_group_child.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
          end
        end
      end
    end

    context 'multiple groups shared with group' do
      let(:user) { create(:user) }
      let(:group) { create(:group, :private) }
      let(:shared_group_parent) { create(:group, :private) }
      let(:shared_group) { create(:group, :private, parent: shared_group_parent) }

      before do
        stub_feature_flags(share_group_with_group: true)

        group.add_owner(user)

        create(:group_group_link, { shared_with_group: group,
                                    shared_group: shared_group,
                                    group_access: GroupMember::DEVELOPER })
        create(:group_group_link, { shared_with_group: group,
                                    shared_group: shared_group_parent,
                                    group_access: GroupMember::MAINTAINER })
      end

      it 'returns correct access level' do
        expect(shared_group.max_member_access_for_user(user)).to eq(Gitlab::Access::MAINTAINER)
      end
    end
  end

  describe '#members_with_parents' do
    let!(:group) { create(:group, :nested) }
    let!(:maintainer) { group.parent.add_user(create(:user), GroupMember::MAINTAINER) }
    let!(:developer) { group.add_user(create(:user), GroupMember::DEVELOPER) }

    it 'returns parents members' do
      expect(group.members_with_parents).to include(developer)
      expect(group.members_with_parents).to include(maintainer)
    end
  end

  describe '#direct_and_indirect_members' do
    let!(:group) { create(:group, :nested) }
    let!(:sub_group) { create(:group, parent: group) }
    let!(:maintainer) { group.parent.add_user(create(:user), GroupMember::MAINTAINER) }
    let!(:developer) { group.add_user(create(:user), GroupMember::DEVELOPER) }
    let!(:other_developer) { group.add_user(create(:user), GroupMember::DEVELOPER) }

    it 'returns parents members' do
      expect(group.direct_and_indirect_members).to include(developer)
      expect(group.direct_and_indirect_members).to include(maintainer)
    end

    it 'returns descendant members' do
      expect(group.direct_and_indirect_members).to include(other_developer)
    end
  end

  describe '#users_with_descendants' do
    let(:user_a) { create(:user) }
    let(:user_b) { create(:user) }

    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:deep_nested_group) { create(:group, parent: nested_group) }

    it 'returns member users on every nest level without duplication' do
      group.add_developer(user_a)
      nested_group.add_developer(user_b)
      deep_nested_group.add_maintainer(user_a)

      expect(group.users_with_descendants).to contain_exactly(user_a, user_b)
      expect(nested_group.users_with_descendants).to contain_exactly(user_a, user_b)
      expect(deep_nested_group.users_with_descendants).to contain_exactly(user_a)
    end
  end

  describe '#direct_and_indirect_users' do
    let(:user_a) { create(:user) }
    let(:user_b) { create(:user) }
    let(:user_c) { create(:user) }
    let(:user_d) { create(:user) }

    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:deep_nested_group) { create(:group, parent: nested_group) }
    let(:project) { create(:project, namespace: group) }

    before do
      group.add_developer(user_a)
      group.add_developer(user_c)
      nested_group.add_developer(user_b)
      deep_nested_group.add_developer(user_a)
      project.add_developer(user_d)
    end

    it 'returns member users on every nest level without duplication' do
      expect(group.direct_and_indirect_users).to contain_exactly(user_a, user_b, user_c, user_d)
      expect(nested_group.direct_and_indirect_users).to contain_exactly(user_a, user_b, user_c)
      expect(deep_nested_group.direct_and_indirect_users).to contain_exactly(user_a, user_b, user_c)
    end

    it 'does not return members of projects belonging to ancestor groups' do
      expect(nested_group.direct_and_indirect_users).not_to include(user_d)
    end
  end

  describe '#project_users_with_descendants' do
    let(:user_a) { create(:user) }
    let(:user_b) { create(:user) }
    let(:user_c) { create(:user) }

    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:deep_nested_group) { create(:group, parent: nested_group) }
    let(:project_a) { create(:project, namespace: group) }
    let(:project_b) { create(:project, namespace: nested_group) }
    let(:project_c) { create(:project, namespace: deep_nested_group) }

    it 'returns members of all projects in group and subgroups' do
      project_a.add_developer(user_a)
      project_b.add_developer(user_b)
      project_c.add_developer(user_c)

      expect(group.project_users_with_descendants).to contain_exactly(user_a, user_b, user_c)
      expect(nested_group.project_users_with_descendants).to contain_exactly(user_b, user_c)
      expect(deep_nested_group.project_users_with_descendants).to contain_exactly(user_c)
    end
  end

  describe '#user_ids_for_project_authorizations' do
    it 'returns the user IDs for which to refresh authorizations' do
      maintainer = create(:user)
      developer = create(:user)

      group.add_user(maintainer, GroupMember::MAINTAINER)
      group.add_user(developer, GroupMember::DEVELOPER)

      expect(group.user_ids_for_project_authorizations)
        .to include(maintainer.id, developer.id)
    end
  end

  describe '#update_two_factor_requirement' do
    let(:user) { create(:user) }

    context 'group membership' do
      before do
        group.add_user(user, GroupMember::OWNER)
      end

      it 'is called when require_two_factor_authentication is changed' do
        expect_any_instance_of(User).to receive(:update_two_factor_requirement)

        group.update!(require_two_factor_authentication: true)
      end

      it 'is called when two_factor_grace_period is changed' do
        expect_any_instance_of(User).to receive(:update_two_factor_requirement)

        group.update!(two_factor_grace_period: 23)
      end

      it 'is not called when other attributes are changed' do
        expect_any_instance_of(User).not_to receive(:update_two_factor_requirement)

        group.update!(description: 'foobar')
      end

      it 'calls #update_two_factor_requirement on each group member' do
        other_user = create(:user)
        group.add_user(other_user, GroupMember::OWNER)

        calls = 0
        allow_any_instance_of(User).to receive(:update_two_factor_requirement) do
          calls += 1
        end

        group.update!(require_two_factor_authentication: true, two_factor_grace_period: 23)

        expect(calls).to eq 2
      end
    end

    context 'sub groups and projects' do
      it 'enables two_factor_requirement for group member' do
        group.add_user(user, GroupMember::OWNER)

        group.update!(require_two_factor_authentication: true)

        expect(user.reload.require_two_factor_authentication_from_group).to be_truthy
      end

      context 'expanded group members' do
        let(:indirect_user) { create(:user) }

        it 'enables two_factor_requirement for subgroup member' do
          subgroup = create(:group, :nested, parent: group)
          subgroup.add_user(indirect_user, GroupMember::OWNER)

          group.update!(require_two_factor_authentication: true)

          expect(indirect_user.reload.require_two_factor_authentication_from_group).to be_truthy
        end

        it 'does not enable two_factor_requirement for ancestor group member' do
          ancestor_group = create(:group)
          ancestor_group.add_user(indirect_user, GroupMember::OWNER)
          group.update!(parent: ancestor_group)

          group.update!(require_two_factor_authentication: true)

          expect(indirect_user.reload.require_two_factor_authentication_from_group).to be_falsey
        end
      end

      context 'project members' do
        it 'does not enable two_factor_requirement for child project member' do
          project = create(:project, group: group)
          project.add_maintainer(user)

          group.update!(require_two_factor_authentication: true)

          expect(user.reload.require_two_factor_authentication_from_group).to be_falsey
        end

        it 'does not enable two_factor_requirement for subgroup child project member' do
          subgroup = create(:group, :nested, parent: group)
          project = create(:project, group: subgroup)
          project.add_maintainer(user)

          group.update!(require_two_factor_authentication: true)

          expect(user.reload.require_two_factor_authentication_from_group).to be_falsey
        end
      end
    end
  end

  describe '#path_changed_hook' do
    let(:system_hook_service) { SystemHooksService.new }

    context 'for a new group' do
      let(:group) { build(:group) }

      before do
        expect(group).to receive(:system_hook_service).and_return(system_hook_service)
      end

      it 'does not trigger system hook' do
        expect(system_hook_service).to receive(:execute_hooks_for).with(group, :create)

        group.save!
      end
    end

    context 'for an existing group' do
      let(:group) { create(:group, path: 'old-path') }

      context 'when the path is changed' do
        let(:new_path) { 'very-new-path' }

        it 'triggers the rename system hook' do
          expect(group).to receive(:system_hook_service).and_return(system_hook_service)
          expect(system_hook_service).to receive(:execute_hooks_for).with(group, :rename)

          group.update!(path: new_path)
        end
      end

      context 'when the path is not changed' do
        it 'does not trigger system hook' do
          expect(group).not_to receive(:system_hook_service)

          group.update!(name: 'new name')
        end
      end
    end
  end

  describe '#ci_variables_for' do
    let(:project) { create(:project, group: group) }

    let!(:ci_variable) do
      create(:ci_group_variable, value: 'secret', group: group)
    end

    let!(:protected_variable) do
      create(:ci_group_variable, :protected, value: 'protected', group: group)
    end

    subject { group.ci_variables_for('ref', project) }

    shared_examples 'ref is protected' do
      it 'contains all the variables' do
        is_expected.to contain_exactly(ci_variable, protected_variable)
      end
    end

    context 'when the ref is not protected' do
      before do
        stub_application_setting(
          default_branch_protection: Gitlab::Access::PROTECTION_NONE)
      end

      it 'contains only the CI variables' do
        is_expected.to contain_exactly(ci_variable)
      end
    end

    context 'when the ref is a protected branch' do
      before do
        allow(project).to receive(:protected_for?).with('ref').and_return(true)
      end

      it_behaves_like 'ref is protected'
    end

    context 'when the ref is a protected tag' do
      before do
        allow(project).to receive(:protected_for?).with('ref').and_return(true)
      end

      it_behaves_like 'ref is protected'
    end

    context 'when group has children' do
      let(:group_child)      { create(:group, parent: group) }
      let(:group_child_2)    { create(:group, parent: group_child) }
      let(:group_child_3)    { create(:group, parent: group_child_2) }
      let(:variable_child)   { create(:ci_group_variable, group: group_child) }
      let(:variable_child_2) { create(:ci_group_variable, group: group_child_2) }
      let(:variable_child_3) { create(:ci_group_variable, group: group_child_3) }

      before do
        allow(project).to receive(:protected_for?).with('ref').and_return(true)
      end

      it 'returns all variables belong to the group and parent groups' do
        expected_array1 = [protected_variable, ci_variable]
        expected_array2 = [variable_child, variable_child_2, variable_child_3]
        got_array = group_child_3.ci_variables_for('ref', project).to_a

        expect(got_array.shift(2)).to contain_exactly(*expected_array1)
        expect(got_array).to eq(expected_array2)
      end
    end
  end

  describe '#highest_group_member' do
    let(:nested_group) { create(:group, parent: group) }
    let(:nested_group_2) { create(:group, parent: nested_group) }
    let(:user) { create(:user) }

    subject(:highest_group_member) { nested_group_2.highest_group_member(user) }

    context 'when the user is not a member of any group in the hierarchy' do
      it 'returns nil' do
        expect(highest_group_member).to be_nil
      end
    end

    context 'when the user is only a member of one group in the hierarchy' do
      before do
        nested_group.add_developer(user)
      end

      it 'returns that group member' do
        expect(highest_group_member.access_level).to eq(Gitlab::Access::DEVELOPER)
      end
    end

    context 'when the user is a member of several groups in the hierarchy' do
      before do
        group.add_owner(user)
        nested_group.add_developer(user)
        nested_group_2.add_maintainer(user)
      end

      it 'returns the group member with the highest access level' do
        expect(highest_group_member.access_level).to eq(Gitlab::Access::OWNER)
      end
    end
  end

  context 'with uploads' do
    it_behaves_like 'model with uploads', true do
      let(:model_object) { create(:group, :with_avatar) }
      let(:upload_attribute) { :avatar }
      let(:uploader_class) { AttachmentUploader }
    end
  end

  describe '#first_auto_devops_config' do
    using RSpec::Parameterized::TableSyntax

    let(:group) { create(:group) }

    subject { group.first_auto_devops_config }

    where(:instance_value, :group_value, :config) do
      # Instance level enabled
      true | nil    | { status: true, scope: :instance }
      true | true   | { status: true, scope: :group }
      true | false  | { status: false, scope: :group }

      # Instance level disabled
      false | nil    | { status: false, scope: :instance }
      false | true   | { status: true, scope: :group }
      false | false  | { status: false, scope: :group }
    end

    with_them do
      before do
        stub_application_setting(auto_devops_enabled: instance_value)

        group.update_attribute(:auto_devops_enabled, group_value)
      end

      it { is_expected.to eq(config) }
    end

    context 'with parent groups' do
      where(:instance_value, :parent_value, :group_value, :config) do
        # Instance level enabled
        true | nil   | nil    | { status: true, scope: :instance }
        true | nil   | true   | { status: true, scope: :group }
        true | nil   | false  | { status: false, scope: :group }

        true | true  | nil    | { status: true, scope: :group }
        true | true  | true   | { status: true, scope: :group }
        true | true  | false  | { status: false, scope: :group }

        true | false | nil    | { status: false, scope: :group }
        true | false | true   | { status: true, scope: :group }
        true | false | false  | { status: false, scope: :group }

        # Instance level disable
        false | nil  | nil    | { status: false, scope: :instance }
        false | nil  | true   | { status: true, scope: :group }
        false | nil  | false  | { status: false, scope: :group }

        false | true | nil    | { status: true, scope: :group }
        false | true | true   | { status: true, scope: :group }
        false | true | false  | { status: false, scope: :group }

        false | false | nil   | { status: false, scope: :group }
        false | false | true  | { status: true, scope: :group }
        false | false | false | { status: false, scope: :group }
      end

      with_them do
        before do
          stub_application_setting(auto_devops_enabled: instance_value)
          parent = create(:group, auto_devops_enabled: parent_value)

          group.update!(
            auto_devops_enabled: group_value,
            parent: parent
          )
        end

        it { is_expected.to eq(config) }
      end
    end
  end

  describe '#auto_devops_enabled?' do
    subject { group.auto_devops_enabled? }

    context 'when auto devops is explicitly enabled on group' do
      let(:group) { create(:group, :auto_devops_enabled) }

      it { is_expected.to be_truthy }
    end

    context 'when auto devops is explicitly disabled on group' do
      let(:group) { create(:group, :auto_devops_disabled) }

      it { is_expected.to be_falsy }
    end

    context 'when auto devops is implicitly enabled or disabled' do
      before do
        stub_application_setting(auto_devops_enabled: false)

        group.update!(parent: parent_group)
      end

      context 'when auto devops is enabled on root group' do
        let(:root_group) { create(:group, :auto_devops_enabled) }
        let(:subgroup) { create(:group, parent: root_group) }
        let(:parent_group) { create(:group, parent: subgroup) }

        it { is_expected.to be_truthy }
      end

      context 'when auto devops is disabled on root group' do
        let(:root_group) { create(:group, :auto_devops_disabled) }
        let(:subgroup) { create(:group, parent: root_group) }
        let(:parent_group) { create(:group, parent: subgroup) }

        it { is_expected.to be_falsy }
      end

      context 'when auto devops is disabled on parent group and enabled on root group' do
        let(:root_group) { create(:group, :auto_devops_enabled) }
        let(:parent_group) { create(:group, :auto_devops_disabled, parent: root_group) }

        it { is_expected.to be_falsy }
      end
    end
  end

  describe 'project_creation_level' do
    it 'outputs the default one if it is nil' do
      group = create(:group, project_creation_level: nil)

      expect(group.project_creation_level).to eq(Gitlab::CurrentSettings.default_project_creation)
    end
  end

  describe 'subgroup_creation_level' do
    it 'defaults to maintainers' do
      expect(group.subgroup_creation_level)
        .to eq(Gitlab::Access::MAINTAINER_SUBGROUP_ACCESS)
    end
  end

  describe '#access_request_approvers_to_be_notified' do
    it 'returns a maximum of ten, active, non_requested owners of the group in recent_sign_in descending order' do
      group = create(:group, :public)

      users = create_list(:user, 12, :with_sign_ins)
      active_owners = users.map do |user|
        create(:group_member, :owner, group: group, user: user)
      end

      create(:group_member, :owner, :blocked, group: group)
      create(:group_member, :maintainer, group: group)
      create(:group_member, :access_request, :owner, group: group)

      active_owners_in_recent_sign_in_desc_order = group.members_and_requesters.where(id: active_owners).order_recent_sign_in.limit(10)

      expect(group.access_request_approvers_to_be_notified).to eq(active_owners_in_recent_sign_in_desc_order)
    end
  end

  describe '.groups_including_descendants_by' do
    it 'returns the expected groups for a group and its descendants' do
      parent_group1 = create(:group)
      child_group1 = create(:group, parent: parent_group1)
      child_group2 = create(:group, parent: parent_group1)

      parent_group2 = create(:group)
      child_group3 = create(:group, parent: parent_group2)

      create(:group)

      groups = described_class.groups_including_descendants_by([parent_group2.id, parent_group1.id])

      expect(groups).to contain_exactly(parent_group1, parent_group2, child_group1, child_group2, child_group3)
    end
  end
end
