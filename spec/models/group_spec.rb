require 'spec_helper'

describe Group do
  let!(:group) { create(:group, :access_requestable) }

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
    it { is_expected.to have_many(:uploads).dependent(:destroy) }
    it { is_expected.to have_one(:chat_team) }
    it { is_expected.to have_many(:custom_attributes).class_name('GroupCustomAttribute') }
    it { is_expected.to have_many(:audit_events).dependent(false) }
    it { is_expected.to have_many(:badges).class_name('GroupBadge') }

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

  describe '.visible_to_user' do
    let!(:group) { create(:group) }
    let!(:user)  { create(:user) }

    subject { described_class.visible_to_user(user) }

    describe 'when the user has access to a group' do
      before do
        group.add_user(user, Gitlab::Access::MASTER)
      end

      it { is_expected.to eq([group]) }
    end

    describe 'when the user does not have access to any groups' do
      it { is_expected.to eq([]) }
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
      group.add_user(user, GroupMember::MASTER)
    end

    it { expect(group.group_members.masters.map(&:user)).to include(user) }
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
      group.add_user(user, GroupMember::MASTER)
    end

    it "is true if avatar is image" do
      group.update_attribute(:avatar, 'uploads/avatar.png')
      expect(group.avatar_type).to be_truthy
    end

    it "is false if avatar is html page" do
      group.update_attribute(:avatar, 'uploads/avatar.html')
      expect(group.avatar_type).to eq(["file format is not supported. Please try one of the following supported formats: png, jpg, jpeg, gif, bmp, tiff"])
    end
  end

  describe '#avatar_url' do
    let!(:group) { create(:group, :access_requestable, :with_avatar) }
    let(:user) { create(:user) }

    context 'when avatar file is uploaded' do
      before do
        group.add_master(user)
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
    it { expect(group.has_owner?(@members[:master])).to be_falsey }
    it { expect(group.has_owner?(@members[:developer])).to be_falsey }
    it { expect(group.has_owner?(@members[:reporter])).to be_falsey }
    it { expect(group.has_owner?(@members[:guest])).to be_falsey }
    it { expect(group.has_owner?(@members[:requester])).to be_falsey }
    it { expect(group.has_owner?(nil)).to be_falsey }
  end

  describe '#has_master?' do
    before do
      @members = setup_group_members(group)
      create(:group_member, :invited, :master, group: group)
    end

    it { expect(group.has_master?(@members[:owner])).to be_falsey }
    it { expect(group.has_master?(@members[:master])).to be_truthy }
    it { expect(group.has_master?(@members[:developer])).to be_falsey }
    it { expect(group.has_master?(@members[:reporter])).to be_falsey }
    it { expect(group.has_master?(@members[:guest])).to be_falsey }
    it { expect(group.has_master?(@members[:requester])).to be_falsey }
    it { expect(group.has_master?(nil)).to be_falsey }
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
      master: create(:user),
      developer: create(:user),
      reporter: create(:user),
      guest: create(:user),
      requester: create(:user)
    }

    group.add_user(members[:owner], GroupMember::OWNER)
    group.add_user(members[:master], GroupMember::MASTER)
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

  describe '#members_with_parents', :nested_groups do
    let!(:group) { create(:group, :nested) }
    let!(:master) { group.parent.add_user(create(:user), GroupMember::MASTER) }
    let!(:developer) { group.add_user(create(:user), GroupMember::DEVELOPER) }

    it 'returns parents members' do
      expect(group.members_with_parents).to include(developer)
      expect(group.members_with_parents).to include(master)
    end
  end

  describe '#users_with_descendants', :nested_groups do
    let(:user_a) { create(:user) }
    let(:user_b) { create(:user) }

    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:deep_nested_group) { create(:group, parent: nested_group) }

    it 'returns member users on every nest level without duplication' do
      group.add_developer(user_a)
      nested_group.add_developer(user_b)
      deep_nested_group.add_developer(user_a)

      expect(group.users_with_descendants).to contain_exactly(user_a, user_b)
      expect(nested_group.users_with_descendants).to contain_exactly(user_a, user_b)
      expect(deep_nested_group.users_with_descendants).to contain_exactly(user_a)
    end
  end

  describe '#user_ids_for_project_authorizations' do
    it 'returns the user IDs for which to refresh authorizations' do
      master = create(:user)
      developer = create(:user)

      group.add_user(master, GroupMember::MASTER)
      group.add_user(developer, GroupMember::DEVELOPER)

      expect(group.user_ids_for_project_authorizations)
        .to include(master.id, developer.id)
    end
  end

  describe '#update_two_factor_requirement' do
    let(:user) { create(:user) }

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

          group.update_attributes!(path: new_path)
        end
      end

      context 'when the path is not changed' do
        it 'does not trigger system hook' do
          expect(group).not_to receive(:system_hook_service)

          group.update_attributes!(name: 'new name')
        end
      end
    end
  end

  describe '#secret_variables_for' do
    let(:project) { create(:project, group: group) }

    let!(:secret_variable) do
      create(:ci_group_variable, value: 'secret', group: group)
    end

    let!(:protected_variable) do
      create(:ci_group_variable, :protected, value: 'protected', group: group)
    end

    subject { group.secret_variables_for('ref', project) }

    shared_examples 'ref is protected' do
      it 'contains all the variables' do
        is_expected.to contain_exactly(secret_variable, protected_variable)
      end
    end

    context 'when the ref is not protected' do
      before do
        stub_application_setting(
          default_branch_protection: Gitlab::Access::PROTECTION_NONE)
      end

      it 'contains only the secret variables' do
        is_expected.to contain_exactly(secret_variable)
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

    context 'when group has children', :postgresql do
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
        expected_array1 = [protected_variable, secret_variable]
        expected_array2 = [variable_child, variable_child_2, variable_child_3]
        got_array = group_child_3.secret_variables_for('ref', project).to_a

        expect(got_array.shift(2)).to contain_exactly(*expected_array1)
        expect(got_array).to eq(expected_array2)
      end
    end
  end

  describe '#has_parent?' do
    context 'when the group has a parent' do
      it 'should be truthy' do
        group = create(:group, :nested)
        expect(group.has_parent?).to be_truthy
      end
    end

    context 'when the group has no parent' do
      it 'should be falsy' do
        group = create(:group, parent: nil)
        expect(group.has_parent?).to be_falsy
      end
    end
  end
end
