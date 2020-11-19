# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectHooks, 'ProjectHooks' do
  let(:user) { create(:user) }
  let(:user3) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id, namespace: user.namespace) }
  let!(:hook) do
    create(:project_hook,
           :all_events_enabled,
           project: project,
           url: 'http://example.com',
           enable_ssl_verification: true,
           push_events_branch_filter: 'master')
  end

  before do
    project.add_maintainer(user)
    project.add_developer(user3)
  end

  describe "GET /projects/:id/hooks" do
    context "authorized user" do
      it "returns project hooks" do
        get api("/projects/#{project.id}/hooks", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(response).to include_pagination_headers
        expect(json_response.count).to eq(1)
        expect(json_response.first['url']).to eq("http://example.com")
        expect(json_response.first['issues_events']).to eq(true)
        expect(json_response.first['confidential_issues_events']).to eq(true)
        expect(json_response.first['push_events']).to eq(true)
        expect(json_response.first['merge_requests_events']).to eq(true)
        expect(json_response.first['tag_push_events']).to eq(true)
        expect(json_response.first['note_events']).to eq(true)
        expect(json_response.first['confidential_note_events']).to eq(true)
        expect(json_response.first['job_events']).to eq(true)
        expect(json_response.first['pipeline_events']).to eq(true)
        expect(json_response.first['wiki_page_events']).to eq(true)
        expect(json_response.first['deployment_events']).to eq(true)
        expect(json_response.first['releases_events']).to eq(true)
        expect(json_response.first['enable_ssl_verification']).to eq(true)
        expect(json_response.first['push_events_branch_filter']).to eq('master')
      end
    end

    context "unauthorized user" do
      it "does not access project hooks" do
        get api("/projects/#{project.id}/hooks", user3)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe "GET /projects/:id/hooks/:hook_id" do
    context "authorized user" do
      it "returns a project hook" do
        get api("/projects/#{project.id}/hooks/#{hook.id}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['url']).to eq(hook.url)
        expect(json_response['issues_events']).to eq(hook.issues_events)
        expect(json_response['confidential_issues_events']).to eq(hook.confidential_issues_events)
        expect(json_response['push_events']).to eq(hook.push_events)
        expect(json_response['merge_requests_events']).to eq(hook.merge_requests_events)
        expect(json_response['tag_push_events']).to eq(hook.tag_push_events)
        expect(json_response['note_events']).to eq(hook.note_events)
        expect(json_response['confidential_note_events']).to eq(hook.confidential_note_events)
        expect(json_response['job_events']).to eq(hook.job_events)
        expect(json_response['pipeline_events']).to eq(hook.pipeline_events)
        expect(json_response['wiki_page_events']).to eq(hook.wiki_page_events)
        expect(json_response['releases_events']).to eq(hook.releases_events)
        expect(json_response['deployment_events']).to eq(true)
        expect(json_response['enable_ssl_verification']).to eq(hook.enable_ssl_verification)
      end

      it "returns a 404 error if hook id is not available" do
        get api("/projects/#{project.id}/hooks/#{non_existing_record_id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "unauthorized user" do
      it "does not access an existing hook" do
        get api("/projects/#{project.id}/hooks/#{hook.id}", user3)
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe "POST /projects/:id/hooks" do
    it "adds hook to project" do
      expect do
        post(api("/projects/#{project.id}/hooks", user),
             params: { url: "http://example.com", issues_events: true,
                       confidential_issues_events: true, wiki_page_events: true,
                       job_events: true, deployment_events: true, releases_events: true,
                       push_events_branch_filter: 'some-feature-branch' })
      end.to change {project.hooks.count}.by(1)

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['url']).to eq('http://example.com')
      expect(json_response['issues_events']).to eq(true)
      expect(json_response['confidential_issues_events']).to eq(true)
      expect(json_response['push_events']).to eq(true)
      expect(json_response['merge_requests_events']).to eq(false)
      expect(json_response['tag_push_events']).to eq(false)
      expect(json_response['note_events']).to eq(false)
      expect(json_response['confidential_note_events']).to eq(nil)
      expect(json_response['job_events']).to eq(true)
      expect(json_response['pipeline_events']).to eq(false)
      expect(json_response['wiki_page_events']).to eq(true)
      expect(json_response['deployment_events']).to eq(true)
      expect(json_response['releases_events']).to eq(true)
      expect(json_response['enable_ssl_verification']).to eq(true)
      expect(json_response['push_events_branch_filter']).to eq('some-feature-branch')
      expect(json_response).not_to include('token')
    end

    it "adds the token without including it in the response" do
      token = "secret token"

      expect do
        post api("/projects/#{project.id}/hooks", user), params: { url: "http://example.com", token: token }
      end.to change {project.hooks.count}.by(1)

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response["url"]).to eq("http://example.com")
      expect(json_response).not_to include("token")

      hook = project.hooks.find(json_response["id"])

      expect(hook.url).to eq("http://example.com")
      expect(hook.token).to eq(token)
    end

    it "returns a 400 error if url not given" do
      post api("/projects/#{project.id}/hooks", user)
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "returns a 422 error if url not valid" do
      post api("/projects/#{project.id}/hooks", user), params: { url: "ftp://example.com" }
      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it "returns a 422 error if branch filter is not valid" do
      post api("/projects/#{project.id}/hooks", user), params: { url: "http://example.com", push_events_branch_filter: '~badbranchname/' }
      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end
  end

  describe "PUT /projects/:id/hooks/:hook_id" do
    it "updates an existing project hook" do
      put api("/projects/#{project.id}/hooks/#{hook.id}", user),
        params: { url: 'http://example.org', push_events: false, job_events: true }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['url']).to eq('http://example.org')
      expect(json_response['issues_events']).to eq(hook.issues_events)
      expect(json_response['confidential_issues_events']).to eq(hook.confidential_issues_events)
      expect(json_response['push_events']).to eq(false)
      expect(json_response['merge_requests_events']).to eq(hook.merge_requests_events)
      expect(json_response['tag_push_events']).to eq(hook.tag_push_events)
      expect(json_response['note_events']).to eq(hook.note_events)
      expect(json_response['confidential_note_events']).to eq(hook.confidential_note_events)
      expect(json_response['job_events']).to eq(hook.job_events)
      expect(json_response['pipeline_events']).to eq(hook.pipeline_events)
      expect(json_response['wiki_page_events']).to eq(hook.wiki_page_events)
      expect(json_response['releases_events']).to eq(hook.releases_events)
      expect(json_response['enable_ssl_verification']).to eq(hook.enable_ssl_verification)
    end

    it "adds the token without including it in the response" do
      token = "secret token"

      put api("/projects/#{project.id}/hooks/#{hook.id}", user), params: { url: "http://example.org", token: token }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response["url"]).to eq("http://example.org")
      expect(json_response).not_to include("token")

      expect(hook.reload.url).to eq("http://example.org")
      expect(hook.reload.token).to eq(token)
    end

    it "returns 404 error if hook id not found" do
      put api("/projects/#{project.id}/hooks/#{non_existing_record_id}", user), params: { url: 'http://example.org' }
      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns 400 error if url is not given" do
      put api("/projects/#{project.id}/hooks/#{hook.id}", user)
      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "returns a 422 error if url is not valid" do
      put api("/projects/#{project.id}/hooks/#{hook.id}", user), params: { url: 'ftp://example.com' }
      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /projects/:id/hooks/:hook_id" do
    it "deletes hook from project" do
      expect do
        delete api("/projects/#{project.id}/hooks/#{hook.id}", user)

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change {project.hooks.count}.by(-1)
    end

    it "returns a 404 error when deleting non existent hook" do
      delete api("/projects/#{project.id}/hooks/42", user)
      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns a 404 error if hook id not given" do
      delete api("/projects/#{project.id}/hooks", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns a 404 if a user attempts to delete project hooks they do not own" do
      test_user = create(:user)
      other_project = create(:project)
      other_project.add_maintainer(test_user)

      delete api("/projects/#{other_project.id}/hooks/#{hook.id}", test_user)
      expect(response).to have_gitlab_http_status(:not_found)
      expect(WebHook.exists?(hook.id)).to be_truthy
    end

    it_behaves_like '412 response' do
      let(:request) { api("/projects/#{project.id}/hooks/#{hook.id}", user) }
    end
  end
end
