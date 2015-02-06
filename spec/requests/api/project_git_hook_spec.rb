require 'spec_helper'

describe API::API, 'ProjectGitHook', api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:user3) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id, namespace: user.namespace) }

  before do
    project.team << [user, :master]
    project.team << [user3, :developer]
  end

  describe "GET /projects/:id/git_hook" do
    before do
      create(:git_hook, project: project)
    end

    context "authorized user" do
      it "should return project git hook" do
        get api("/projects/#{project.id}/git_hook", user)
        response.status.should eq(200)

        json_response.should be_an Hash
        json_response['project_id'].should eq(project.id)
      end
    end

    context "unauthorized user" do
      it "should not access project git hooks" do
        get api("/projects/#{project.id}/git_hook", user3)
        response.status.should eq(403)
      end
    end
  end


  describe "POST /projects/:id/git_hook" do
    context "authorized user" do
      it "should add git hook to project" do
        post api("/projects/#{project.id}/git_hook", user),
          deny_delete_tag: true
        response.status.should eq(201)

        json_response.should be_an Hash
        json_response['project_id'].should eq(project.id)
        json_response['deny_delete_tag'].should eq(true)
      end
    end

    context "unauthorized user" do
      it "should not add git hook to project" do
        post api("/projects/#{project.id}/git_hook", user3),
          deny_delete_tag: true
        response.status.should eq(403)
      end
    end
  end

  describe "POST /projects/:id/git_hook" do
    before do
      create(:git_hook, project: project)
    end

    context "with existing git hook" do
      it "should not add git hook to project" do
        post api("/projects/#{project.id}/git_hook", user),
          deny_delete_tag: true
        response.status.should eq(422)
      end
    end
  end

  describe "PUT /projects/:id/git_hook" do
    before do
      create(:git_hook, project: project)
    end

    it "should update an existing project git hook" do
      put api("/projects/#{project.id}/git_hook", user),
        deny_delete_tag: false, commit_message_regex: 'Fixes \d+\..*'
      response.status.should eq(200)

      json_response['deny_delete_tag'].should eq(false)
      json_response['commit_message_regex'].should eq('Fixes \d+\..*')
    end
  end

  describe "PUT /projects/:id/git_hook" do
    it "should error on non existing project git hook" do
      put api("/projects/#{project.id}/git_hook", user),
        deny_delete_tag: false, commit_message_regex: 'Fixes \d+\..*'
      response.status.should eq(404)
    end

    it "should not update git hook for unauthorized user" do
      post api("/projects/#{project.id}/git_hook", user3),
        deny_delete_tag: true
      response.status.should eq(403)
    end
  end

  describe "DELETE /projects/:id/git_hook" do
    before do
      create(:git_hook, project: project)
    end

    context "authorized user" do
      it "should delete git hook from project" do
        delete api("/projects/#{project.id}/git_hook", user)
        response.status.should eq(200)

        json_response.should be_an Hash
      end
    end

    context "unauthorized user" do
      it "should return a 403 error" do
        delete api("/projects/#{project.id}/git_hook", user3)
        response.status.should eq(403)
      end
    end
  end

  describe "DELETE /projects/:id/git_hook" do
    context "for non existing git hook" do
      it "should delete git hook from project" do
        delete api("/projects/#{project.id}/git_hook", user)
        response.status.should eq(404)

        json_response.should be_an Hash
        json_response['message'].should eq("404 Not Found")
      end

      it "should return a 403 error if not authorized" do
        delete api("/projects/#{project.id}/git_hook", user3)
        response.status.should eq(403)
      end
    end
  end
end
