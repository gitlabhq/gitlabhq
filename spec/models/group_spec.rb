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
#

require 'spec_helper'

describe Group do
  let!(:group) { create(:group) }

  describe "Associations" do
    it { should have_many :projects }
    it { should have_many :group_members }
  end

  it { should validate_presence_of :name }
  it { should validate_uniqueness_of(:name) }
  it { should validate_presence_of :path }
  it { should validate_uniqueness_of(:path) }
  it { should_not validate_presence_of :owner }

  describe :users do
    it { group.users.should == group.owners }
  end

  describe :human_name do
    it { group.human_name.should == group.name }
  end

  describe :add_users do
    let(:user) { create(:user) }
    before { group.add_user(user, GroupMember::MASTER) }

    it { group.group_members.masters.map(&:user).should include(user) }
  end

  describe :add_users do
    let(:user) { create(:user) }
    before { group.add_users([user.id], GroupMember::GUEST) }

    it "should update the group permission" do
      group.group_members.guests.map(&:user).should include(user)
      group.add_users([user.id], GroupMember::DEVELOPER)
      group.group_members.developers.map(&:user).should include(user)
      group.group_members.guests.map(&:user).should_not include(user)
    end
  end

  describe :avatar_type do
    let(:user) { create(:user) }
    before { group.add_user(user, GroupMember::MASTER) }

    it "should be true if avatar is image" do
      group.update_attribute(:avatar, 'uploads/avatar.png')
      group.avatar_type.should be_true
    end

    it "should be false if avatar is html page" do
      group.update_attribute(:avatar, 'uploads/avatar.html')
      group.avatar_type.should == ["only images allowed"]
    end
  end
end
