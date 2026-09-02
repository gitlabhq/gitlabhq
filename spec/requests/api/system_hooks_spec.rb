# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::SystemHooks, feature_category: :webhooks do
  let_it_be(:non_admin) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be_with_refind(:hook) { create(:system_hook, url: "http://example.com") }

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
