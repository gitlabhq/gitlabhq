# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectHooks, 'ProjectHooks', feature_category: :webhooks do
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be_with_reload(:project) do
    create(:project, :repository, creator_id: user.id, namespace: user.namespace, maintainers: user, developers: user2)
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
    let(:resource) { project }
    let(:unauthorized_user) { user2 }

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
        milestone_events
        emoji_events
        resource_access_token_events
        resource_deploy_token_events
      ]
    end

    let(:default_values) do
      { push_events: true, confidential_note_events: nil }
    end

    it_behaves_like 'test web-hook endpoint'
    it_behaves_like 'POST webhook API endpoints with a branch filter', '/projects/:id'
    it_behaves_like 'PUT webhook API endpoints with a branch filter', '/projects/:id'
    it_behaves_like 'resend web-hook event endpoint' do
      let(:unauthorized_user) { user2 }
    end

    it_behaves_like 'get web-hook event endpoint' do
      let(:unauthorized_user) { user2 }
    end
  end

  describe 'duo_flow_callback_enabled' do
    before do
      stub_feature_flags(duo_flow_callback_hooks: project.root_ancestor)
    end

    it 'can be set when creating a project hook' do
      post api("/projects/#{project.id}/hooks", user), params: {
        url: 'https://example.com/callback',
        duo_flow_callback_enabled: true
      }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['duo_flow_callback_enabled']).to be(true)
    end

    it 'can be updated on an existing project hook' do
      put api("/projects/#{project.id}/hooks/#{hook.id}", user), params: {
        duo_flow_callback_enabled: true
      }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['duo_flow_callback_enabled']).to be(true)
    end

    it 'is returned in the hook response' do
      hook.update!(duo_flow_callback_enabled: true)

      get api("/projects/#{project.id}/hooks/#{hook.id}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/project_hook')
      expect(json_response['duo_flow_callback_enabled']).to be(true)
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(duo_flow_callback_hooks: false)
      end

      it 'rejects the attribute on create rather than dropping it' do
        post api("/projects/#{project.id}/hooks", user), params: {
          url: 'https://example.com/callback',
          duo_flow_callback_enabled: true
        }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'rejects the attribute on update rather than dropping it' do
        put api("/projects/#{project.id}/hooks/#{hook.id}", user), params: {
          duo_flow_callback_enabled: true
        }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'still accepts a request that does not mention the attribute' do
        put api("/projects/#{project.id}/hooks/#{hook.id}", user), params: { push_events: false }

        expect(response).to have_gitlab_http_status(:ok)
      end

      # Reads expose the attribute whatever the flag state, so a client that GETs a hook
      # and PUTs the payload back must not be rejected over a value it never changed.
      it 'still accepts a request that disables the attribute' do
        put api("/projects/#{project.id}/hooks/#{hook.id}", user), params: {
          duo_flow_callback_enabled: false
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['duo_flow_callback_enabled']).to be(false)
      end
    end
  end
end
