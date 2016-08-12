require 'spec_helper'

describe Group, models: true do
  let!(:group) { create(:group) }

  describe 'associations' do
    it { is_expected.to have_many :projects }
    it { is_expected.to have_many(:group_members).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:group_members) }
    it { is_expected.to have_many(:owners).through(:group_members) }
    it { is_expected.to have_many(:requesters).dependent(:destroy) }
    it { is_expected.to have_many(:project_group_links).dependent(:destroy) }
    it { is_expected.to have_many(:shared_projects).through(:project_group_links) }
    it { is_expected.to have_many(:notification_settings).dependent(:destroy) }

    describe '#members & #requesters' do
      let(:requester) { create(:user) }
      let(:developer) { create(:user) }
      before do
        group.request_access(requester)
        group.add_developer(developer)
      end

      describe '#members' do
        it 'includes members and exclude requesters' do
          member_user_ids = group.members.pluck(:user_id)

          expect(member_user_ids).to include(developer.id)
          expect(member_user_ids).not_to include(requester.id)
        end
      end

      describe '#requesters' do
        it 'does not include requesters' do
          requester_user_ids = group.requesters.pluck(:user_id)

          expect(requester_user_ids).to include(requester.id)
          expect(requester_user_ids).not_to include(developer.id)
        end
      end
    end
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Referable) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of :path }
    it { is_expected.to validate_uniqueness_of(:path) }
    it { is_expected.not_to validate_presence_of :owner }
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

      it{ is_expected.to eq([group]) }
    end

    describe 'public_and_internal_only' do
      subject { described_class.public_and_internal_only.to_a }

      it{ is_expected.to match_array([group, internal_group]) }
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
    before { group.add_user(user, GroupMember::MASTER) }

    it { expect(group.group_members.masters.map(&:user)).to include(user) }
  end

  describe '#add_users' do
    let(:user) { create(:user) }
    before { group.add_users([user.id], GroupMember::GUEST) }

    it "updates the group permission" do
      expect(group.group_members.guests.map(&:user)).to include(user)
      group.add_users([user.id], GroupMember::DEVELOPER)
      expect(group.group_members.developers.map(&:user)).to include(user)
      expect(group.group_members.guests.map(&:user)).not_to include(user)
    end
  end

  describe '#avatar_type' do
    let(:user) { create(:user) }
    before { group.add_user(user, GroupMember::MASTER) }

    it "is true if avatar is image" do
      group.update_attribute(:avatar, 'uploads/avatar.png')
      expect(group.avatar_type).to be_truthy
    end

    it "is false if avatar is html page" do
      group.update_attribute(:avatar, 'uploads/avatar.html')
      expect(group.avatar_type).to eq(["only images allowed"])
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
    before { @members = setup_group_members(group) }

    it { expect(group.has_owner?(@members[:owner])).to be_truthy }
    it { expect(group.has_owner?(@members[:master])).to be_falsey }
    it { expect(group.has_owner?(@members[:developer])).to be_falsey }
    it { expect(group.has_owner?(@members[:reporter])).to be_falsey }
    it { expect(group.has_owner?(@members[:guest])).to be_falsey }
    it { expect(group.has_owner?(@members[:requester])).to be_falsey }
  end

  describe '#has_master?' do
    before { @members = setup_group_members(group) }

    it { expect(group.has_master?(@members[:owner])).to be_falsey }
    it { expect(group.has_master?(@members[:master])).to be_truthy }
    it { expect(group.has_master?(@members[:developer])).to be_falsey }
    it { expect(group.has_master?(@members[:reporter])).to be_falsey }
    it { expect(group.has_master?(@members[:guest])).to be_falsey }
    it { expect(group.has_master?(@members[:requester])).to be_falsey }
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
end
