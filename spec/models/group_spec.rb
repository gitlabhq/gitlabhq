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
    it { should have_many :users_groups }
  end

  it { should validate_presence_of :name }
  it { should validate_uniqueness_of(:name) }
  it { should validate_presence_of :path }
  it { should validate_uniqueness_of(:path) }
  it { should_not validate_presence_of :owner }

  describe :users do
    it { expect(group.users).to eq(group.owners) }
  end

  describe :human_name do
    it { expect(group.human_name).to eq(group.name) }
  end

  describe :add_users do
    let(:user) { create(:user) }
    before { group.add_user(user, UsersGroup::MASTER) }

    it { expect(group.users_groups.masters.map(&:user)).to include(user) }
  end

  describe :add_users do
    let(:user) { create(:user) }
    before { group.add_users([user.id], UsersGroup::GUEST) }

    it "should update the group permission" do
      expect(group.users_groups.guests.map(&:user)).to include(user)
      group.add_users([user.id], UsersGroup::DEVELOPER)
      expect(group.users_groups.developers.map(&:user)).to include(user)
      expect(group.users_groups.guests.map(&:user)).not_to include(user)
    end
  end

  describe :avatar_type do
    let(:user) { create(:user) }
    before { group.add_user(user, UsersGroup::MASTER) }

    it "should be true if avatar is image" do
      group.update_attribute(:avatar, 'uploads/avatar.png')
      expect(group.avatar_type).to be_true
    end

    it "should be false if avatar is html page" do
      group.update_attribute(:avatar, 'uploads/avatar.html')
      expect(group.avatar_type).to eq(["only images allowed"])
    end
  end
end
