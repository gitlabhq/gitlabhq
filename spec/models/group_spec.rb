# == Schema Information
#
# Table name: namespaces
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  path        :string(255)      not null
#  owner_id    :integer
#  created_at  :datetime
#  updated_at  :datetime
#  type        :string(255)
#  description :string(255)      default(""), not null
#  avatar      :string(255)
#  public      :boolean          default(FALSE)
#

require 'spec_helper'

describe Group do
  let!(:group) { create(:group) }

  describe 'associations' do
    it { is_expected.to have_many :projects }
    it { is_expected.to have_many :group_members }
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

  describe '.public_and_given_groups' do
    let!(:public_group) { create(:group, public: true) }

    subject { described_class.public_and_given_groups([group.id]) }

    it { is_expected.to eq([public_group, group]) }
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

  describe '#to_reference' do
    it 'returns a String reference to the object' do
      expect(group.to_reference).to eq "@#{group.name}"
    end
  end

  describe :users do
    it { expect(group.users).to eq(group.owners) }
  end

  describe :human_name do
    it { expect(group.human_name).to eq(group.name) }
  end

  describe :add_users do
    let(:user) { create(:user) }
    before { group.add_user(user, GroupMember::MASTER) }

    it { expect(group.group_members.masters.map(&:user)).to include(user) }
  end

  describe :add_users do
    let(:user) { create(:user) }
    before { group.add_users([user.id], GroupMember::GUEST) }

    it "should update the group permission" do
      expect(group.group_members.guests.map(&:user)).to include(user)
      group.add_users([user.id], GroupMember::DEVELOPER)
      expect(group.group_members.developers.map(&:user)).to include(user)
      expect(group.group_members.guests.map(&:user)).not_to include(user)
    end
  end

  describe :avatar_type do
    let(:user) { create(:user) }
    before { group.add_user(user, GroupMember::MASTER) }

    it "should be true if avatar is image" do
      group.update_attribute(:avatar, 'uploads/avatar.png')
      expect(group.avatar_type).to be_truthy
    end

    it "should be false if avatar is html page" do
      group.update_attribute(:avatar, 'uploads/avatar.html')
      expect(group.avatar_type).to eq(["only images allowed"])
    end
  end

  describe "public_profile?" do
    it "returns true for public group" do
      group = create(:group, public: true)
      expect(group.public_profile?).to be_truthy
    end

    it "returns true for non-public group with public project" do
      group = create(:group)
      create(:project, :public, group: group)
      expect(group.public_profile?).to be_truthy
    end

    it "returns false for non-public group with no public projects" do
      group = create(:group)
      create(:project, group: group)
      expect(group.public_profile?).to be_falsy
    end
  end
end
