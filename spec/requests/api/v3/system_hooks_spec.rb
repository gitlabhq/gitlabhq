require 'spec_helper'

describe API::V3::SystemHooks do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let!(:hook) { create(:system_hook, url: "http://example.com") }

  before { stub_request(:post, hook.url) }

  describe "GET /hooks" do
    context "when no user" do
      it "returns authentication error" do
        get v3_api("/hooks")

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context "when not an admin" do
      it "returns forbidden error" do
        get v3_api("/hooks", user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context "when authenticated as admin" do
      it "returns an array of hooks" do
        get v3_api("/hooks", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.first['url']).to eq(hook.url)
        expect(json_response.first['push_events']).to be false
        expect(json_response.first['tag_push_events']).to be false
        expect(json_response.first['repository_update_events']).to be true
      end
    end
  end

  describe "DELETE /hooks/:id" do
    it "deletes a hook" do
      expect do
        delete v3_api("/hooks/#{hook.id}", admin)

        expect(response).to have_gitlab_http_status(200)
      end.to change { SystemHook.count }.by(-1)
    end

    it 'returns 404 if the system hook does not exist' do
      delete v3_api('/hooks/12345', admin)

      expect(response).to have_gitlab_http_status(404)
    end
  end
end
