require 'spec_helper'

describe API::API, 'ProjectHooks', api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:user3) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id, namespace: user.namespace) }
  let!(:hook) { create(:project_hook, project: project, url: "http://example.com") }

  before do
    project.team << [user, :master]
    project.team << [user3, :developer]
  end

  describe "GET /projects/:id/hooks" do
    context "authorized user" do
      it "should return project hooks" do
        get api("/projects/#{project.id}/hooks", user)
        expect(response.status).to eq(200)

        expect(json_response).to be_an Array
        expect(json_response.count).to eq(1)
        expect(json_response.first['url']).to eq("http://example.com")
      end
    end

    context "unauthorized user" do
      it "should not access project hooks" do
        get api("/projects/#{project.id}/hooks", user3)
        expect(response.status).to eq(403)
      end
    end
  end

  describe "GET /projects/:id/hooks/:hook_id" do
    context "authorized user" do
      it "should return a project hook" do
        get api("/projects/#{project.id}/hooks/#{hook.id}", user)
        expect(response.status).to eq(200)
        expect(json_response['url']).to eq(hook.url)
      end

      it "should return a 404 error if hook id is not available" do
        get api("/projects/#{project.id}/hooks/1234", user)
        expect(response.status).to eq(404)
      end
    end

    context "unauthorized user" do
      it "should not access an existing hook" do
        get api("/projects/#{project.id}/hooks/#{hook.id}", user3)
        expect(response.status).to eq(403)
      end
    end

    it "should return a 404 error if hook id is not available" do
      get api("/projects/#{project.id}/hooks/1234", user)
      expect(response.status).to eq(404)
    end
  end

  describe "POST /projects/:id/hooks" do
    it "should add hook to project" do
      expect do
        post api("/projects/#{project.id}/hooks", user), url: "http://example.com", issues_events: true
      end.to change {project.hooks.count}.by(1)
      expect(response.status).to eq(201)
    end

    it "should return a 400 error if url not given" do
      post api("/projects/#{project.id}/hooks", user)
      expect(response.status).to eq(400)
    end

    it "should return a 422 error if url not valid" do
      post api("/projects/#{project.id}/hooks", user), "url" => "ftp://example.com"
      expect(response.status).to eq(422)
    end
  end

  describe "PUT /projects/:id/hooks/:hook_id" do
    it "should update an existing project hook" do
      put api("/projects/#{project.id}/hooks/#{hook.id}", user),
        url: 'http://example.org', push_events: false
      expect(response.status).to eq(200)
      expect(json_response['url']).to eq('http://example.org')
    end

    it "should return 404 error if hook id not found" do
      put api("/projects/#{project.id}/hooks/1234", user), url: 'http://example.org'
      expect(response.status).to eq(404)
    end

    it "should return 400 error if url is not given" do
      put api("/projects/#{project.id}/hooks/#{hook.id}", user)
      expect(response.status).to eq(400)
    end

    it "should return a 422 error if url is not valid" do
      put api("/projects/#{project.id}/hooks/#{hook.id}", user), url: 'ftp://example.com'
      expect(response.status).to eq(422)
    end
  end

  describe "DELETE /projects/:id/hooks/:hook_id" do
    it "should delete hook from project" do
      expect do
        delete api("/projects/#{project.id}/hooks/#{hook.id}", user)
      end.to change {project.hooks.count}.by(-1)
      expect(response.status).to eq(200)
    end

    it "should return success when deleting hook" do
      delete api("/projects/#{project.id}/hooks/#{hook.id}", user)
      expect(response.status).to eq(200)
    end

    it "should return success when deleting non existent hook" do
      delete api("/projects/#{project.id}/hooks/42", user)
      expect(response.status).to eq(200)
    end

    it "should return a 405 error if hook id not given" do
      delete api("/projects/#{project.id}/hooks", user)
      expect(response.status).to eq(405)
    end
  end
end
