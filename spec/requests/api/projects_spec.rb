require 'spec_helper'

describe Gitlab::API do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let!(:hook) { create(:project_hook, project: project, url: "http://example.com") }
  let!(:project) { create(:project, owner: user ) }
  let!(:snippet) { create(:snippet, author: user, project: project, title: 'example') }
  let!(:users_project) { create(:users_project, user: user, project: project, project_access: UsersProject::MASTER) }
  let!(:users_project2) { create(:users_project, user: user3, project: project, project_access: UsersProject::DEVELOPER) }
  before { project.add_access(user, :read) }

  describe "GET /projects" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/projects")
        response.status.should == 401
      end
    end

    context "when authenticated" do
      it "should return an array of projects" do
        get api("/projects", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.first['name'].should == project.name
        json_response.first['owner']['email'].should == user.email
      end
    end
  end

  describe "POST /projects" do
    it "should create new project without path" do
      expect { post api("/projects", user), name: 'foo' }.to change {Project.count}.by(1)
    end

    it "should not create new project without name" do
      expect { post api("/projects", user) }.to_not change {Project.count}
    end

    it "should respond with 201 on success" do
      post api("/projects", user), name: 'foo'
      response.status.should == 201
    end

    it "should respond with 404 on failure" do
      post api("/projects", user)
      response.status.should == 404
    end

    it "should assign attributes to project" do
      project = attributes_for(:project, {
        description: Faker::Lorem.sentence,
        default_branch: 'stable',
        issues_enabled: false,
        wall_enabled: false,
        merge_requests_enabled: false,
        wiki_enabled: false
      })

      post api("/projects", user), project

      project.each_pair do |k,v|
        next if k == :path
        json_response[k.to_s].should == v
      end
    end
  end

  describe "GET /projects/:id" do
    it "should return a project by id" do
      get api("/projects/#{project.id}", user)
      response.status.should == 200
      json_response['name'].should == project.name
      json_response['owner']['email'].should == user.email
    end

    it "should return a project by path name" do
      get api("/projects/#{project.path}", user)
      response.status.should == 200
      json_response['name'].should == project.name
    end

    it "should return a 404 error if not found" do
      get api("/projects/42", user)
      response.status.should == 404
      json_response['message'].should == '404 Not Found'
    end
  end

  describe "GET /projects/:id/repository/branches" do
    it "should return an array of project branches" do
      get api("/projects/#{project.path}/repository/branches", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['name'].should == project.repo.heads.sort_by(&:name).first.name
    end
  end

  describe "GET /projects/:id/repository/branches/:branch" do
    it "should return the branch information for a single branch" do
      get api("/projects/#{project.path}/repository/branches/new_design", user)
      response.status.should == 200

      json_response['name'].should == 'new_design'
      json_response['commit']['id'].should == '621491c677087aa243f165eab467bfdfbee00be1'
    end
  end

  describe "GET /projects/:id/members" do
    it "should return project team members" do
      get api("/projects/#{project.path}/members", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.count.should == 2
      json_response.first['email'].should == user.email
    end

    it "finds team members with query string" do
      get api("/projects/#{project.path}/members", user), query: user.username
      response.status.should == 200
      json_response.should be_an Array
      json_response.count.should == 1
      json_response.first['email'].should == user.email
    end
  end

  describe "GET /projects/:id/members/:user_id" do
    it "should return project team member" do
      get api("/projects/#{project.path}/members/#{user.id}", user)
      response.status.should == 200
      json_response['email'].should == user.email
      json_response['access_level'].should == UsersProject::MASTER
    end
  end

  describe "POST /projects/:id/members" do
    it "should add user to project team" do
      expect {
        post api("/projects/#{project.path}/members", user), user_id: user2.id,
          access_level: UsersProject::DEVELOPER
      }.to change { UsersProject.count }.by(1)

      response.status.should == 201
      json_response['email'].should == user2.email
      json_response['access_level'].should == UsersProject::DEVELOPER
    end
  end

  describe "PUT /projects/:id/members/:user_id" do
    it "should update project team member" do
      put api("/projects/#{project.path}/members/#{user3.id}", user), access_level: UsersProject::MASTER
      response.status.should == 200
      json_response['email'].should == user3.email
      json_response['access_level'].should == UsersProject::MASTER
    end
  end

  describe "DELETE /projects/:id/members/:user_id" do
    it "should remove user from project team" do
      expect {
        delete api("/projects/#{project.path}/members/#{user3.id}", user)
      }.to change { UsersProject.count }.by(-1)
    end
  end

  describe "GET /projects/:id/hooks" do
    it "should return project hooks" do
      get api("/projects/#{project.path}/hooks", user)

      response.status.should == 200

      json_response.should be_an Array
      json_response.count.should == 1
      json_response.first['url'].should == "http://example.com"
    end
  end

  describe "GET /projects/:id/hooks/:hook_id" do
    it "should return a project hook" do
      get api("/projects/#{project.path}/hooks/#{hook.id}", user)
      response.status.should == 200
      json_response['url'].should == hook.url
    end
  end

  describe "POST /projects/:id/hooks" do
    it "should add hook to project" do
      expect {
        post api("/projects/#{project.path}/hooks", user),
          "url" => "http://example.com"
      }.to change {project.hooks.count}.by(1)
    end
  end

  describe "PUT /projects/:id/hooks/:hook_id" do
    it "should update an existing project hook" do
      put api("/projects/#{project.path}/hooks/#{hook.id}", user),
        url: 'http://example.org'
      response.status.should == 200
      json_response['url'].should == 'http://example.org'
    end
  end


  describe "DELETE /projects/:id/hooks" do
    it "should delete hook from project" do
      expect {
        delete api("/projects/#{project.path}/hooks", user),
          hook_id: hook.id
      }.to change {project.hooks.count}.by(-1)
    end
  end

  describe "GET /projects/:id/repository/tags" do
    it "should return an array of project tags" do
      get api("/projects/#{project.path}/repository/tags", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['name'].should == project.repo.tags.sort_by(&:name).reverse.first.name
    end
  end

  describe "GET /projects/:id/repository/commits" do
    context "authorized user" do
      before { project.add_access(user2, :read) }

      it "should return project commits" do
        get api("/projects/#{project.path}/repository/commits", user)
        response.status.should == 200

        json_response.should be_an Array
        json_response.first['id'].should == project.commit.id
      end
    end

    context "unauthorized user" do
      it "should not return project commits" do
        get api("/projects/#{project.path}/repository/commits")
        response.status.should == 401
      end
    end
  end

  describe "GET /projects/:id/snippets" do
    it "should return an array of project snippets" do
      get api("/projects/#{project.path}/snippets", user)
      response.status.should == 200
      json_response.should be_an Array
      json_response.first['title'].should == snippet.title
    end
  end

  describe "GET /projects/:id/snippets/:snippet_id" do
    it "should return a project snippet" do
      get api("/projects/#{project.path}/snippets/#{snippet.id}", user)
      response.status.should == 200
      json_response['title'].should == snippet.title
    end
  end

  describe "POST /projects/:id/snippets" do
    it "should create a new project snippet" do
      post api("/projects/#{project.path}/snippets", user),
        title: 'api test', file_name: 'sample.rb', code: 'test'
      response.status.should == 201
      json_response['title'].should == 'api test'
    end
  end

  describe "PUT /projects/:id/snippets/:shippet_id" do
    it "should update an existing project snippet" do
      put api("/projects/#{project.path}/snippets/#{snippet.id}", user),
        code: 'updated code'
      response.status.should == 200
      json_response['title'].should == 'example'
      snippet.reload.content.should == 'updated code'
    end
  end

  describe "DELETE /projects/:id/snippets/:snippet_id" do
    it "should delete existing project snippet" do
      expect {
        delete api("/projects/#{project.path}/snippets/#{snippet.id}", user)
      }.to change { Snippet.count }.by(-1)
    end
  end

  describe "GET /projects/:id/snippets/:snippet_id/raw" do
    it "should get a raw project snippet" do
      get api("/projects/#{project.path}/snippets/#{snippet.id}/raw", user)
      response.status.should == 200
    end
  end

  describe "GET /projects/:id/:sha/blob" do
    it "should get the raw file contents" do
      get api("/projects/#{project.path}/repository/commits/master/blob?filepath=README.md", user)
      response.status.should == 200
    end

    it "should return 404 for invalid branch_name" do
      get api("/projects/#{project.path}/repository/commits/invalid_branch_name/blob?filepath=README.md", user)
      response.status.should == 404
    end

    it "should return 404 for invalid file" do
      get api("/projects/#{project.path}/repository/commits/master/blob?filepath=README.invalid", user)
      response.status.should == 404
    end
  end
end
