require 'spec_helper'

describe Gitlab::UserTeamManager do
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
