require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let!(:hook) { create(:system_hook, url: "http://example.com") }

  before { stub_request(:post, hook.url) }

  describe "GET /hooks" do
    context "when no user" do
      it "returns authentication error" do
        get api("/hooks")
        expect(response).to have_http_status(401)
      end
    end

    context "when not an admin" do
      it "returns forbidden error" do
        get api("/hooks", user)
        expect(response).to have_http_status(403)
      end
    end

    context "when authenticated as admin" do
      it "returns an array of hooks" do
        get api("/hooks", admin)
        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['url']).to eq(hook.url)
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
      expect(response).to have_http_status(400)
    end

    it "does not create new hook without url" do
      expect do
        post api("/hooks", admin)
      end.not_to change { SystemHook.count }
    end
  end

  describe "GET /hooks/:id" do
    it "returns hook by id" do
      get api("/hooks/#{hook.id}", admin)
      expect(response).to have_http_status(200)
      expect(json_response['event_name']).to eq('project_create')
    end

    it "returns 404 on failure" do
      get api("/hooks/404", admin)
      expect(response).to have_http_status(404)
    end
  end

  describe "DELETE /hooks/:id" do
    it "deletes a hook" do
      expect do
        delete api("/hooks/#{hook.id}", admin)
      end.to change { SystemHook.count }.by(-1)
    end

    it 'returns 404 if the system hook does not exist' do
      delete api('/hooks/12345', admin)

      expect(response).to have_http_status(404)
    end
  end
end
