require 'spec_helper'

describe API::SystemHooks do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let!(:hook) { create(:system_hook, url: "http://example.com") }

  before do
    stub_request(:post, hook.url)
  end

  describe "GET /hooks" do
    context "when no user" do
      it "returns authentication error" do
        get api("/hooks")

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context "when not an admin" do
      it "returns forbidden error" do
        get api("/hooks", user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context "when authenticated as admin" do
      it "returns an array of hooks" do
        get api("/hooks", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['url']).to eq(hook.url)
        expect(json_response.first['push_events']).to be false
        expect(json_response.first['tag_push_events']).to be false
        expect(json_response.first['merge_requests_events']).to be false
        expect(json_response.first['repository_update_events']).to be true
      end
    end
  end

  describe "POST /hooks" do
    it "creates new hook" do
      expect do
        post api("/hooks", admin), url: 'http://example.com'
      end.to change { SystemHook.count }.by(1)
    end

    it "responds with 400 if url not given" do
      post api("/hooks", admin)

      expect(response).to have_gitlab_http_status(400)
    end

    it "responds with 400 if url is invalid" do
      post api("/hooks", admin), url: 'hp://mep.mep'

      expect(response).to have_gitlab_http_status(400)
    end

    it "does not create new hook without url" do
      expect do
        post api("/hooks", admin)
      end.not_to change { SystemHook.count }
    end

    it 'sets default values for events' do
      post api('/hooks', admin), url: 'http://mep.mep'

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['enable_ssl_verification']).to be true
      expect(json_response['push_events']).to be false
      expect(json_response['tag_push_events']).to be false
      expect(json_response['merge_requests_events']).to be false
    end

    it 'sets explicit values for events' do
      post api('/hooks', admin),
        url: 'http://mep.mep',
        enable_ssl_verification: false,
        push_events: true,
        tag_push_events: true,
        merge_requests_events: true

      expect(response).to have_http_status(201)
      expect(json_response['enable_ssl_verification']).to be false
      expect(json_response['push_events']).to be true
      expect(json_response['tag_push_events']).to be true
      expect(json_response['merge_requests_events']).to be true
    end
  end

  describe "GET /hooks/:id" do
    it "returns hook by id" do
      get api("/hooks/#{hook.id}", admin)
      expect(response).to have_gitlab_http_status(200)
      expect(json_response['event_name']).to eq('project_create')
    end

    it "returns 404 on failure" do
      get api("/hooks/404", admin)
      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe "DELETE /hooks/:id" do
    it "deletes a hook" do
      expect do
        delete api("/hooks/#{hook.id}", admin)

        expect(response).to have_gitlab_http_status(204)
      end.to change { SystemHook.count }.by(-1)
    end

    it 'returns 404 if the system hook does not exist' do
      delete api('/hooks/12345', admin)

      expect(response).to have_gitlab_http_status(404)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/hooks/#{hook.id}", admin) }
    end
  end
end
