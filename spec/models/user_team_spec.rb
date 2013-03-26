# == Schema Information
#
# Table name: user_teams
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  path        :string(255)
#  owner_id    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  description :string(255)      default(""), not null
#

require 'spec_helper'

describe UserTeam do
  let(:team) { FactoryGirl.create :user_team }

  context ".add_member" do
    let(:user) { FactoryGirl.create :user }

    it "should work" do
      team.add_member(user, UsersProject::DEVELOPER, false)
      team.members.should include(user)
    end
  end

  context ".remove_member" do
    let(:user) { FactoryGirl.create :user }
    before { team.add_member(user, UsersProject::DEVELOPER, false) }

    it "should work" do
      team.remove_member(user)
      team.members.should_not include(user)
    end
  end
end
