require 'spec_helper'

describe API::API do
  include ApiHelpers

  # Create test objects
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:admin) { create(:admin) }
  let!(:group1) { create(:group, owner: user1) }
  let!(:group2) { create(:group, owner: user2) }
  let(:user_team1) { create(:user_team, owner: user1) }
  let(:user_team2) { create(:user_team, owner: user2) }
  let!(:project1) { create(:project, creator_id: admin.id) }
  let!(:project2) { create(:project, creator_id: admin.id) }


  before {
    # Add members to teams
    user_team1.add_member(user1, UsersProject::MASTER, false)
    user_team2.add_member(user2, UsersProject::MASTER, false)

    # Add projects to teams
    user_team1.assign_to_projects([project1.id], UsersProject::MASTER)
    user_team2.assign_to_projects([project2.id], UsersProject::MASTER)

  }

  describe "GET /user_teams" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/user_teams")
        response.status.should == 401
      end
    end

    context "when authenticated as user" do
      it "normal user: should return an array of user_teams of user1" do
        get api("/user_teams", user1)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 1
        json_response.first['name'].should == user_team1.name
      end
    end

    context "when authenticated as admin" do
      it "admin: should return an array of all user_teams" do
        get api("/user_teams", admin)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 2
      end
    end
  end

  describe "GET /user_teams/:id" do
    context "when authenticated as user" do
      it "should return one of user1's user_teams" do
        get api("/user_teams/#{user_team1.id}", user1)
        response.status.should == 200
        json_response['name'] == user_team1.name
      end

      it "should not return a non existing team" do
        get api("/user_teams/1328", user1)
        response.status.should == 404
      end

      it "should not return a user_team not attached to user1" do
        get api("/user_teams/#{user_team2.id}", user1)
        response.status.should == 404
      end
    end

    context "when authenticated as admin" do
      it "should return any existing user_team" do
        get api("/user_teams/#{user_team2.id}", admin)
        response.status.should == 200
        json_response['name'].should == user_team2.name
      end

      it "should not return a non existing user_team" do
        get api("/user_teams/1328", admin)
        response.status.should == 404
      end
    end
  end

  describe "POST /user_teams" do
    context "when authenticated as user" do
      it "should not create user_team" do
        count_before=UserTeam.count
        post api("/user_teams", user1), attributes_for(:user_team)
        response.status.should == 403
        UserTeam.count.should == count_before
      end
    end

    context "when authenticated as admin" do
      it "should create user_team" do
        count_before=UserTeam.count
        post api("/user_teams", admin), attributes_for(:user_team)
        response.status.should == 201
        UserTeam.count.should == count_before + 1
      end

      it "should not create user_team, duplicate" do
        post api("/user_teams", admin), {:name => "Duplicate Test", :path => user_team2.path}
        response.status.should == 404
      end

      it "should return 400 bad request error if name not given" do
        post api("/user_teams", admin), {:path => user_team2.path}
        response.status.should == 400
      end

      it "should return 400 bad request error if path not given" do
        post api("/user_teams", admin), {:name => 'test'}
        response.status.should == 400
      end
    end
  end

  # Members

  describe "GET /user_teams/:id/members" do
    context "when authenticated as user" do
      it "should return user1 as member of user1's user_teams" do
        get api("/user_teams/#{user_team1.id}/members", user1)
        response.status.should == 200
        json_response.first['name'].should == user1.name
        json_response.first['access_level'].should == UsersProject::MASTER
      end
    end

    context "when authenticated as admin" do
      it "should return member of any existing user_team" do
        get api("/user_teams/#{user_team2.id}/members", admin)
        response.status.should == 200
        json_response.first['name'].should == user2.name
        json_response.first['access_level'].should == UsersProject::MASTER
      end
    end
  end

  describe "POST /user_teams/:id/members" do
    context "when authenticated as user" do
      it "should not add user2 as member of user_team1" do
        post api("/user_teams/#{user_team1.id}/members", user1), user_id: user2.id, access_level: UsersProject::MASTER
        response.status.should == 403
      end
    end

    context "when authenticated as admin" do
      it "should return ok and add new member" do
        count_before=user_team1.user_team_user_relationships.count
        post api("/user_teams/#{user_team1.id}/members", admin), user_id: user2.id, access_level: UsersProject::MASTER
        response.status.should == 201
        json_response['name'].should == user2.name
        json_response['access_level'].should == UsersProject::MASTER
        user_team1.user_team_user_relationships.count.should == count_before + 1
      end
      it "should return ok if member already exists" do
        post api("/user_teams/#{user_team2.id}/members", admin), user_id: user2.id, access_level: UsersProject::MASTER
        response.status.should == 409
      end
      it "should return a 400 error when user id is not given" do
        post api("/user_teams/#{user_team2.id}/members", admin), access_level: UsersProject::MASTER
        response.status.should == 400
      end
      it "should return a 400 error when access level is not given" do
        post api("/user_teams/#{user_team2.id}/members", admin), user_id: user2.id
        response.status.should == 400
      end

      it "should return a 422 error when access level is not known" do
        post api("/user_teams/#{user_team2.id}/members", admin), user_id: user1.id, access_level: 1234
        response.status.should == 422
      end

    end
  end

  # Get single member
  describe "GET /user_teams/:id/members/:user_id" do
    context "when authenticated as member" do
      it "should show user1's membership of user_team1" do
        get api("/user_teams/#{user_team1.id}/members/#{user1.id}", user1)
        response.status.should == 200
        json_response['name'].should == user1.name
        json_response['access_level'].should == UsersProject::MASTER
      end
      it "should show that user2 is not member of user_team1" do
        get api("/user_teams/#{user_team1.id}/members/#{user2.id}", user1)
        response.status.should == 404
      end
    end

    context "when authenticated as non-member" do
      it "should not show user1's membership of user_team1" do
        get api("/user_teams/#{user_team1.id}/members/#{user1.id}", user2)
        response.status.should == 404
      end
    end

    context "when authenticated as admin" do
      it "should show user1's membership of user_team1" do
        get api("/user_teams/#{user_team1.id}/members/#{user1.id}", admin)
        response.status.should == 200
        json_response['name'].should == user1.name
        json_response['access_level'].should == UsersProject::MASTER
      end
      it "should return a 404 error when user id is not known" do
        get api("/user_teams/#{user_team2.id}/members/1328", admin)
        response.status.should == 404
      end
    end
  end

  describe "DELETE /user_teams/:id/members/:user_id" do
    context "when authenticated as user" do
      it "should not delete user1's membership of user_team1" do
        delete api("/user_teams/#{user_team1.id}/members/#{user1.id}", user1)
        response.status.should == 403
      end
    end

    context "when authenticated as admin" do
      it "should delete user1's membership of user_team1" do
        count_before=user_team1.user_team_user_relationships.count
        delete api("/user_teams/#{user_team1.id}/members/#{user1.id}", admin)
        response.status.should == 200
        user_team1.user_team_user_relationships.count.should == count_before - 1
      end
      it "should return a 404 error when user id is not known" do
        delete api("/user_teams/#{user_team2.id}/members/1328", admin)
        response.status.should == 404
      end
    end
  end

  # Projects

  describe "GET /user_teams/:id/projects" do
    context "when authenticated as user" do
      it "should return project1 as assigned to user_team1 as member user1" do
        get api("/user_teams/#{user_team1.id}/projects", user1)
        response.status.should == 200
        json_response.first['name'].should == project1.name
        json_response.length.should == user_team1.user_team_project_relationships.count
      end
    end

    context "when authenticated as admin" do
      it "should return project2 as assigned to user_team2 as non-member, but admin" do
        get api("/user_teams/#{user_team2.id}/projects", admin)
        response.status.should == 200
        json_response.first['name'].should == project2.name
        json_response.first['greatest_access_level'].should == UsersProject::MASTER
      end
    end
  end

  describe "POST /user_teams/:id/projects" do
    context "when authenticated as admin" do
      it "should return ok and add new project" do
        count_before=user_team1.user_team_project_relationships.count
        post api("/user_teams/#{user_team1.id}/projects", admin),
             project_id: project2.id,
             greatest_access_level: UsersProject::MASTER
        response.status.should == 201
        json_response['name'].should == project2.name
        json_response['greatest_access_level'].should == UsersProject::MASTER
        user_team1.user_team_project_relationships.count.should == count_before + 1
      end
      it "should return ok if project already exists" do
        post api("/user_teams/#{user_team2.id}/projects", admin),
             project_id: project2.id,
             greatest_access_level: UsersProject::MASTER
        response.status.should == 409
      end
      it "should return a 400 error when project id is not given" do
        post api("/user_teams/#{user_team2.id}/projects", admin), greatest_access_level: UsersProject::MASTER
        response.status.should == 400
      end
      it "should return a 400 error when access level is not given" do
        post api("/user_teams/#{user_team2.id}/projects", admin), project_id: project2.id
        response.status.should == 400
      end

      it "should return a 422 error when access level is not known" do
        post api("/user_teams/#{user_team2.id}/projects", admin),
             project_id: project2.id,
             greatest_access_level: 1234
        response.status.should == 422
      end

    end
  end


  describe "GET /user_teams/:id/projects/:project_id" do
    context "when authenticated as member" do
      it "should show project1's assignment to user_team1" do
        get api("/user_teams/#{user_team1.id}/projects/#{project1.id}", user1)
        response.status.should == 200
        json_response['name'].should == project1.name
        json_response['greatest_access_level'].should == UsersProject::MASTER
      end
      it "should show project2's is not assigned to user_team1" do
        get api("/user_teams/#{user_team1.id}/projects/#{project2.id}", user1)
        response.status.should == 404
      end
    end

    context "when authenticated as non-member" do
      it "should not show project1's assignment to user_team1" do
        get api("/user_teams/#{user_team1.id}/projects/#{project1.id}", user2)
        response.status.should == 404
      end
    end

    context "when authenticated as admin" do
      it "should show project1's assignment to user_team1" do
        get api("/user_teams/#{user_team1.id}/projects/#{project1.id}", admin)
        response.status.should == 200
        json_response['name'].should == project1.name
        json_response['greatest_access_level'].should == UsersProject::MASTER
      end
      it "should return a 404 error when project id is not known" do
        get api("/user_teams/#{user_team2.id}/projects/1328", admin)
        response.status.should == 404
      end
    end
  end

  describe "DELETE /user_teams/:id/projects/:project_id" do
    context "when authenticated as user" do
      it "should not delete project1's assignment to user_team2" do
        delete api("/user_teams/#{user_team2.id}/projects/#{project1.id}", user1)
        response.status.should == 403
      end
    end

    context "when authenticated as admin" do
      it "should delete project1's assignment to user_team1" do
        count_before=user_team1.user_team_project_relationships.count
        delete api("/user_teams/#{user_team1.id}/projects/#{project1.id}", admin)
        response.status.should == 200
        user_team1.user_team_project_relationships.count.should == count_before - 1
      end
      it "should return a 404 error when project id is not known" do
        delete api("/user_teams/#{user_team2.id}/projects/1328", admin)
        response.status.should == 404
      end
    end
  end

end
