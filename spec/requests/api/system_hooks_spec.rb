# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::SystemHooks do
  include StubRequests

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let!(:hook) { create(:system_hook, url: "http://example.com") }

  before do
    stub_full_request(hook.url, method: :post)
  end

  describe "GET /hooks" do
    context "when no user" do
      it "returns authentication error" do
        get api("/hooks")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when not an admin" do
      it "returns forbidden error" do
        get api("/hooks", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context "when authenticated as admin" do
      it "returns an array of hooks" do
        get api("/hooks", admin)

        expect(response).to have_gitlab_http_status(:ok)
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
        post api("/hooks", admin), params: { url: 'http://example.com' }
      end.to change { SystemHook.count }.by(1)
    end

    it "responds with 400 if url not given" do
      post api("/hooks", admin)

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "responds with 400 if url is invalid" do
      post api("/hooks", admin), params: { url: 'hp://mep.mep' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it "does not create new hook without url" do
      expect do
        post api("/hooks", admin)
      end.not_to change { SystemHook.count }
    end

    it 'sets default values for events' do
      stub_full_request('http://mep.mep', method: :post)

      post api('/hooks', admin), params: { url: 'http://mep.mep' }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['enable_ssl_verification']).to be true
      expect(json_response['push_events']).to be false
      expect(json_response['tag_push_events']).to be false
      expect(json_response['merge_requests_events']).to be false
      expect(json_response['repository_update_events']).to be true
    end

    it 'sets explicit values for events' do
      stub_full_request('http://mep.mep', method: :post)

      post api('/hooks', admin),
        params: {
          url: 'http://mep.mep',
          enable_ssl_verification: false,
          push_events: true,
          tag_push_events: true,
          merge_requests_events: true,
          repository_update_events: false
        }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['enable_ssl_verification']).to be false
      expect(json_response['push_events']).to be true
      expect(json_response['tag_push_events']).to be true
      expect(json_response['merge_requests_events']).to be true
      expect(json_response['repository_update_events']).to be false
    end
  end

  describe 'POST /hooks/:id' do
    it "returns and trigger hook by id" do
      post api("/hooks/#{hook.id}", admin)
      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['event_name']).to eq('project_create')
    end

    it "returns 404 on failure" do
      post api("/hooks/404", admin)
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "DELETE /hooks/:id" do
    it "deletes a hook" do
      expect do
        delete api("/hooks/#{hook.id}", admin)

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { SystemHook.count }.by(-1)
    end

    it 'returns 404 if the system hook does not exist' do
      delete api("/hooks/#{non_existing_record_id}", admin)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/hooks/#{hook.id}", admin) }
    end
  end
end
