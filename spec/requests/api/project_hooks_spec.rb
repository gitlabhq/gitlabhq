require 'spec_helper'

describe API::API, 'ProjectHooks', api: true do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:user3) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id, namespace: user.namespace) }
  let!(:hook) do
    create(:project_hook,
           :all_events_enabled,
           project: project,
           url: 'http://example.com',
           enable_ssl_verification: true)
  end

  before do
    project.team << [user, :master]
    project.team << [user3, :developer]
  end

  describe "GET /projects/:id/hooks" do
    context "authorized user" do
      it "returns project hooks" do
        get api("/projects/#{project.id}/hooks", user)
        expect(response).to have_http_status(200)

        expect(json_response).to be_an Array
        expect(json_response.count).to eq(1)
        expect(json_response.first['url']).to eq("http://example.com")
        expect(json_response.first['issues_events']).to eq(true)
        expect(json_response.first['push_events']).to eq(true)
        expect(json_response.first['merge_requests_events']).to eq(true)
        expect(json_response.first['tag_push_events']).to eq(true)
        expect(json_response.first['note_events']).to eq(true)
        expect(json_response.first['build_events']).to eq(true)
        expect(json_response.first['pipeline_events']).to eq(true)
        expect(json_response.first['wiki_page_events']).to eq(true)
        expect(json_response.first['enable_ssl_verification']).to eq(true)
        expect(json_response.first['token']).to eq('S3cr3t')
      end
    end

    context "unauthorized user" do
      it "does not access project hooks" do
        get api("/projects/#{project.id}/hooks", user3)
        expect(response).to have_http_status(403)
      end
    end
  end

  describe "GET /projects/:id/hooks/:hook_id" do
    context "authorized user" do
      it "returns a project hook" do
        get api("/projects/#{project.id}/hooks/#{hook.id}", user)
        expect(response).to have_http_status(200)
        expect(json_response['url']).to eq(hook.url)
        expect(json_response['issues_events']).to eq(hook.issues_events)
        expect(json_response['push_events']).to eq(hook.push_events)
        expect(json_response['merge_requests_events']).to eq(hook.merge_requests_events)
        expect(json_response['tag_push_events']).to eq(hook.tag_push_events)
        expect(json_response['note_events']).to eq(hook.note_events)
        expect(json_response['build_events']).to eq(hook.build_events)
        expect(json_response['pipeline_events']).to eq(hook.pipeline_events)
        expect(json_response['wiki_page_events']).to eq(hook.wiki_page_events)
        expect(json_response['enable_ssl_verification']).to eq(hook.enable_ssl_verification)
        expect(json_response['token']).to eq(hook.token)
      end

      it "returns a 404 error if hook id is not available" do
        get api("/projects/#{project.id}/hooks/1234", user)
        expect(response).to have_http_status(404)
      end
    end

    context "unauthorized user" do
      it "does not access an existing hook" do
        get api("/projects/#{project.id}/hooks/#{hook.id}", user3)
        expect(response).to have_http_status(403)
      end
    end

    it "returns a 404 error if hook id is not available" do
      get api("/projects/#{project.id}/hooks/1234", user)
      expect(response).to have_http_status(404)
    end
  end

  describe "POST /projects/:id/hooks" do
    it "adds hook to project" do
      expect do
        post api("/projects/#{project.id}/hooks", user), url: "http://example.com", issues_events: true
      end.to change {project.hooks.count}.by(1)
      expect(response).to have_http_status(201)
      expect(json_response['url']).to eq('http://example.com')
      expect(json_response['issues_events']).to eq(true)
      expect(json_response['push_events']).to eq(true)
      expect(json_response['merge_requests_events']).to eq(false)
      expect(json_response['tag_push_events']).to eq(false)
      expect(json_response['note_events']).to eq(false)
      expect(json_response['build_events']).to eq(false)
      expect(json_response['pipeline_events']).to eq(false)
      expect(json_response['wiki_page_events']).to eq(false)
      expect(json_response['enable_ssl_verification']).to eq(true)
      expect(json_response['token']).to eq('S3cr3t')
    end

    it "returns a 400 error if url not given" do
      post api("/projects/#{project.id}/hooks", user)
      expect(response).to have_http_status(400)
    end

    it "returns a 422 error if url not valid" do
      post api("/projects/#{project.id}/hooks", user), "url" => "ftp://example.com"
      expect(response).to have_http_status(422)
    end
  end

  describe "PUT /projects/:id/hooks/:hook_id" do
    it "updates an existing project hook" do
      put api("/projects/#{project.id}/hooks/#{hook.id}", user),
        url: 'http://example.org', push_events: false
      expect(response).to have_http_status(200)
      expect(json_response['url']).to eq('http://example.org')
      expect(json_response['issues_events']).to eq(hook.issues_events)
      expect(json_response['push_events']).to eq(false)
      expect(json_response['merge_requests_events']).to eq(hook.merge_requests_events)
      expect(json_response['tag_push_events']).to eq(hook.tag_push_events)
      expect(json_response['note_events']).to eq(hook.note_events)
      expect(json_response['build_events']).to eq(hook.build_events)
      expect(json_response['pipeline_events']).to eq(hook.pipeline_events)
      expect(json_response['wiki_page_events']).to eq(hook.wiki_page_events)
      expect(json_response['enable_ssl_verification']).to eq(hook.enable_ssl_verification)
      expect(json_response['token']).to eq(hook.token)
    end

    it "returns 404 error if hook id not found" do
      put api("/projects/#{project.id}/hooks/1234", user), url: 'http://example.org'
      expect(response).to have_http_status(404)
    end

    it "returns 400 error if url is not given" do
      put api("/projects/#{project.id}/hooks/#{hook.id}", user)
      expect(response).to have_http_status(400)
    end

    it "returns a 422 error if url is not valid" do
      put api("/projects/#{project.id}/hooks/#{hook.id}", user), url: 'ftp://example.com'
      expect(response).to have_http_status(422)
    end
  end

  describe "DELETE /projects/:id/hooks/:hook_id" do
    it "deletes hook from project" do
      expect do
        delete api("/projects/#{project.id}/hooks/#{hook.id}", user)
      end.to change {project.hooks.count}.by(-1)
      expect(response).to have_http_status(200)
    end

    it "returns success when deleting hook" do
      delete api("/projects/#{project.id}/hooks/#{hook.id}", user)
      expect(response).to have_http_status(200)
    end

    it "returns a 404 error when deleting non existent hook" do
      delete api("/projects/#{project.id}/hooks/42", user)
      expect(response).to have_http_status(404)
    end

    it "returns a 404 error if hook id not given" do
      delete api("/projects/#{project.id}/hooks", user)

      expect(response).to have_http_status(404)
    end

    it "returns a 404 if a user attempts to delete project hooks he/she does not own" do
      test_user = create(:user)
      other_project = create(:project)
      other_project.team << [test_user, :master]

      delete api("/projects/#{other_project.id}/hooks/#{hook.id}", test_user)
      expect(response).to have_http_status(404)
      expect(WebHook.exists?(hook.id)).to be_truthy
    end
  end
end
