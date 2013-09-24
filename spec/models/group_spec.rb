# == Schema Information
#
# Table name: namespaces
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  path        :string(255)      not null
#  owner_id    :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  type        :string(255)
#  description :string(255)      default(""), not null
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
  it { should validate_presence_of :owner }

  describe :users do
    it { group.users.should == [group.owner] }
  end

  describe :human_name do
    it { group.human_name.should == group.name }
  end

  describe :add_users do
    let(:user) { create(:user) }
    before { group.add_users([user.id], UsersGroup::MASTER) }

    it { group.users_groups.masters.map(&:user).should include(user) }
  end
end
