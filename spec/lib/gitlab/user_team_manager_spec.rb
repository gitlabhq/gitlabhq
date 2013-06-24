require 'spec_helper'

describe Gitlab::UserTeamManager do
  describe "Team assign on group" do
    before do
      @user = create :user
      @group = create :group
      @team = create :user_team
    end

    it "should assign team to group" do
      Gitlab::UserTeamManager.assign_to_group(@team, @group, UserTeam.access_roles.first.second)
      @group.user_teams.should_not be_blank
    end

    it "should resign team from group" do
      Gitlab::UserTeamManager.assign_to_group(@team, @group, UserTeam.access_roles.first.second)
      count_team_in_group = @group.user_teams.count

      Gitlab::UserTeamManager.resign_from_group(@team, @group)
      count_team_in_group_after_resign = @group.user_teams.count

      (count_team_in_group - count_team_in_group_after_resign).should == 1
    end

    it "shoul update team defoult access" do
      Gitlab::UserTeamManager.assign_to_group(@team, @group, UserTeam.access_roles.first.second)
      greatest_access = @group.user_team_group_relationships.last.greatest_access
      Gitlab::UserTeamManager.update_team_user_access_in_group(@team, @group, UserTeam.access_roles.dup.drop(1).last.second)
      @group.user_team_group_relationships.last.greatest_access.should_not be_equal(greatest_access)
    end

    it "should resign tema from group with one or more project in group" do
      project = create :project, creator: @user, namespace: @group
      second_project = create :project, creator: @user, namespace: @group
      project.users.count.should == 0

      additional_user = create :user
      Gitlab::UserTeamManager.add_member_into_team(@team, additional_user, UserTeam.access_roles.first.second, true)
      project.users.count.should == 0

      Gitlab::UserTeamManager.assign_to_group(@team, @group, UserTeam.access_roles.first.second)
      project.users.count.should == 1
      @group.user_teams.count.should == 1

      Gitlab::UserTeamManager.resign_from_group(@team, @group)
      @group.user_teams.count.should == 0
      project.users.count.should == 0

      Gitlab::UserTeamManager.assign_to_group(@team, @group, UserTeam.access_roles.first.second)
      project.users.count.should == 1
      @group.user_teams.count.should == 1

      second_team = create :user_team, owner: @user
      second_additional_user = create :user
      Gitlab::UserTeamManager.add_member_into_team(second_team, additional_user, UserTeam.access_roles.first.second, true)
      Gitlab::UserTeamManager.add_member_into_team(second_team, second_additional_user, UserTeam.access_roles.first.second, true)
      Gitlab::UserTeamManager.assign_to_group(second_team, @group, UserTeam.access_roles.first.second)

      project.users.count.should == 2
      @group.user_teams.count.should == 2

      Gitlab::UserTeamManager.resign_from_group(@team, @group)
      Gitlab::UserTeamManager.resign_from_group(second_team, @group)
      @group.user_teams.count.should == 0
      project.users.count.should == 0
    end
  end

  describe "User team assigned to project" do
    before do
      @user = create :user
      @project = create :project, creator: @user

      @master = create :user
      @developer = create :user
      @reporter = create :user

      @project.team << [@master, :master]
      @project.team << [@developer, :developer]
      @project.team << [@reporter, :reporter]

      @team = create :user_team, owner: @user

      @team.add_members([@master.id, @developer.id, @reporter.id], UsersProject::DEVELOPER, false)
    end

    it "should assign team to project with correct permissions result" do
      @team.assign_to_project(@project, UsersProject::MASTER)

      @project.users_projects.find_by_user_id(@master).project_access.should == UsersProject::MASTER
      @project.users_projects.find_by_user_id(@developer).project_access.should == UsersProject::DEVELOPER
      @project.users_projects.find_by_user_id(@reporter).project_access.should == UsersProject::DEVELOPER
    end
  end
end
