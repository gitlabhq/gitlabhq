# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectHooks, 'ProjectHooks', feature_category: :webhooks do
  let_it_be(:user) { create(:user) }
  let_it_be(:user3) { create(:user) }
  let_it_be_with_reload(:project) do
    create(:project, :repository, creator_id: user.id, namespace: user.namespace, maintainers: user, developers: user3)
  end

  let_it_be_with_refind(:hook) do
    create(
      :project_hook,
      :all_events_enabled,
      project: project,
      url: 'http://example.com',
      enable_ssl_verification: true,
      push_events_branch_filter: 'master'
    )
  end

  it_behaves_like 'web-hook API endpoints', '/projects/:id' do
    let(:unauthorized_user) { user3 }

    def scope
      project.hooks
    end

    def collection_uri
      "/projects/#{project.id}/hooks"
    end

    def match_collection_schema
      match_response_schema('public_api/v4/project_hooks')
    end

    def hook_uri(hook_id = hook.id)
      "/projects/#{project.id}/hooks/#{hook_id}"
    end

    def match_hook_schema
      match_response_schema('public_api/v4/project_hook')
    end

    def event_names
      %i[
        push_events
        tag_push_events
        merge_requests_events
        issues_events
        confidential_issues_events
        note_events
        confidential_note_events
        pipeline_events
        wiki_page_events
        job_events
        deployment_events
        feature_flag_events
        releases_events
        emoji_events
        resource_access_token_events
      ]
    end

    let(:default_values) do
      { push_events: true, confidential_note_events: nil }
    end

    it_behaves_like 'test web-hook endpoint'
    it_behaves_like 'POST webhook API endpoints with a branch filter', '/projects/:id'
    it_behaves_like 'PUT webhook API endpoints with a branch filter', '/projects/:id'
    it_behaves_like 'resend web-hook event endpoint' do
      let(:unauthorized_user) { user3 }
    end

    it_behaves_like 'get web-hook event endpoint' do
      let(:unauthorized_user) { user3 }
    end
  end
end
