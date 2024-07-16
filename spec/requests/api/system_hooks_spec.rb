# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::SystemHooks, feature_category: :webhooks do
  let_it_be(:non_admin) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be_with_refind(:hook) { create(:system_hook, url: "http://example.com") }

  it_behaves_like 'web-hook API endpoints', '' do
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
end
