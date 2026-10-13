# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::SystemHooks, :with_current_organization, feature_category: :webhooks do
  let_it_be(:non_admin) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be_with_refind(:hook) do
    create(:system_hook, url: "http://example.com", organization: current_organization)
  end

  describe 'POST /hooks/:hook_id' do
    it_behaves_like 'authorizing granular token permissions', :test_webhook do
      include StubRequests

      let(:boundary_object) { :instance }
      let(:user) { admin }

      before do
        stub_full_request(hook.url, method: :post).to_return(status: 200)
      end

      let(:request) { post api("/hooks/#{hook.id}", personal_access_token: pat) }
    end
  end

  it_behaves_like 'web-hook API endpoints', '' do
    let(:resource) { :instance }
    let(:user) { admin }
    let(:unauthorized_user) { non_admin }

    def scope
      SystemHook
    end

    def collection_uri
      "/hooks"
    end

    def match_collection_schema
      match_response_schema('public_api/v4/system_hooks')
    end

    def hook_uri(hook_id = hook.id)
      "/hooks/#{hook_id}"
    end

    def match_hook_schema
      match_response_schema('public_api/v4/system_hook')
    end

    def event_names
      %i[
        push_events
        tag_push_events
        merge_requests_events
        repository_update_events
      ]
    end

    def hook_param_overrides
      {}
    end

    let(:update_params) do
      {
        push_events: false,
        tag_push_events: true
      }
    end

    let(:default_values) do
      { repository_update_events: true }
    end

    it_behaves_like 'POST webhook API endpoints with a branch filter', ''
    it_behaves_like 'PUT webhook API endpoints with a branch filter', ''
  end

  describe 'organization scoping', :aggregate_failures do
    let_it_be(:other_organization) { create(:organization) }
    let_it_be_with_refind(:other_hook) do
      create(:system_hook,
        url: 'http://other.example.com',
        url_variables: { 'abc' => 'other secret' },
        custom_headers: { 'X-Other' => 'other value' },
        organization: other_organization)
    end

    let(:other_hook_uri) { "/hooks/#{other_hook.id}" }

    def admin_api(path)
      api(path, admin, admin_mode: true)
    end

    describe 'GET /hooks' do
      it 'returns only hooks of the current organization' do
        get admin_api('/hooks')

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to contain_exactly(hook.id)
      end
    end

    describe 'GET /hooks/:hook_id' do
      it 'returns 404 for a hook in another organization' do
        get admin_api(other_hook_uri)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'POST /hooks' do
      it 'creates the hook in the current organization' do
        post admin_api('/hooks'), params: { url: 'http://example.com/new' }

        expect(response).to have_gitlab_http_status(:created)
        expect(SystemHook.find(json_response['id']).organization).to eq(current_organization)
      end
    end

    describe 'PUT /hooks/:hook_id' do
      it 'returns 404 and does not update a hook in another organization' do
        expect do
          put admin_api(other_hook_uri), params: { url: 'http://changed.example.com' }
        end.not_to change { other_hook.reload.attributes }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'DELETE /hooks/:hook_id' do
      it 'returns 404 and does not delete a hook in another organization' do
        expect do
          delete admin_api(other_hook_uri)
        end.not_to change { SystemHook.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'POST /hooks/:hook_id' do
      it 'returns 404 and does not execute a hook in another organization' do
        expect(WebHookService).not_to receive(:new)

        post admin_api(other_hook_uri)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'PUT /hooks/:hook_id/url_variables/:key' do
      it 'returns 404 and does not change a hook in another organization' do
        expect do
          put admin_api("#{other_hook_uri}/url_variables/abc"), params: { value: 'changed' }
        end.not_to change { other_hook.reload.url_variables }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'DELETE /hooks/:hook_id/url_variables/:key' do
      it 'returns 404 and does not change a hook in another organization' do
        expect do
          delete admin_api("#{other_hook_uri}/url_variables/abc")
        end.not_to change { other_hook.reload.url_variables }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'PUT /hooks/:hook_id/custom_headers/:key' do
      it 'returns 404 and does not change a hook in another organization' do
        expect do
          put admin_api("#{other_hook_uri}/custom_headers/X-Other"), params: { value: 'changed' }
        end.not_to change { other_hook.reload.custom_headers }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    describe 'DELETE /hooks/:hook_id/custom_headers/:key' do
      it 'returns 404 and does not change a hook in another organization' do
        expect do
          delete admin_api("#{other_hook_uri}/custom_headers/X-Other")
        end.not_to change { other_hook.reload.custom_headers }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  # System hooks share the web_hooks table, so the column exists on them, but this
  # endpoint does not declare the attribute and has no container to gate it on. Sending
  # it must stay a no-op rather than start failing the request.
  describe 'duo_flow_callback_enabled' do
    it 'ignores the attribute on create' do
      post api('/hooks', admin, admin_mode: true), params: {
        url: 'http://example.com/system-hook',
        duo_flow_callback_enabled: true
      }

      expect(response).to have_gitlab_http_status(:created)
      expect(SystemHook.last.duo_flow_callback_enabled).to be(false)
    end

    it 'ignores the attribute on update' do
      put api("/hooks/#{hook.id}", admin, admin_mode: true), params: {
        duo_flow_callback_enabled: true,
        push_events: false
      }

      expect(response).to have_gitlab_http_status(:ok)
      expect(hook.reload.duo_flow_callback_enabled).to be(false)
    end
  end
end
