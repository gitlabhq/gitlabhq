require 'spec_helper'

describe Gitlab::UserTeamManager do

  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace, creator: user) }
  let!(:team) { create(:user_team, owner: user) }

  describe "Team Access" do
    let(:master) { create(:user) }
    let(:developer) { create(:user) }
    let(:reporter) { create(:user) }

    before do
      project.team << [master, :master]
      project.team << [developer, :developer]
      project.team << [reporter, :reporter]

      team.add_members([master.id, developer.id, reporter.id], UsersProject::DEVELOPER, false)
    end

    it "should assign team to project with correct permissions result" do
      team.assign_to_project(project, UsersProject::MASTER)

      project.users_projects.find_by_user_id(master).project_access.should == UsersProject::MASTER
      project.users_projects.find_by_user_id(developer).project_access.should == UsersProject::DEVELOPER
      project.users_projects.find_by_user_id(reporter).project_access.should == UsersProject::DEVELOPER
    end
  end

  describe "Team Members" do
    
    before do
      team.assign_to_project(project, UserTeam.access_roles["Master"])
    end

    describe "Add member to team and associated project" do
      it "should add the user to the associated project" do
        project.users.map {|u| u.username}.should == []
        team.add_member(user, UserTeam.access_roles["Developer"], false)
        project.users.reload
        project.users.map {|u| u.username}.should == [user.username]
      end
    end

    describe "Delete member from team and associated project" do
      before do
        team.add_member(user, UserTeam.access_roles["Developer"], false)
      end

      it "should remove user from team and project" do
        project.users.map {|u| u.username}.should == [user.username]
        team.remove_member(user)
        project.users.reload
        project.users.map {|u| u.username}.should == []
      end
    end
  end
end
