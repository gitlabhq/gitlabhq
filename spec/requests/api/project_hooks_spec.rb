# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectHooks, 'ProjectHooks', feature_category: :webhooks do
  include StubRequests
  let_it_be(:user) { create(:user) }
  let_it_be(:user3) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :repository, creator_id: user.id, namespace: user.namespace) }
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

  before_all do
    project.add_maintainer(user)
    project.add_developer(user3)
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
        releases_events
        emoji_events
        resource_access_token_events
      ]
    end

    let(:default_values) do
      { push_events: true, confidential_note_events: nil }
    end

    context "when trigger project webhook test", :aggregate_failures do
      using RSpec::Parameterized::TableSyntax

      before do
        stub_full_request(hook.url, method: :post).to_return(status: 200)
      end

      context 'when testing is not available for trigger' do
        where(:trigger_name) do
          %w[confidential_note_events deployment_events feature_flag_events]
        end
        with_them do
          it 'returns error message that testing is not available' do
            post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(json_response['message']).to eq('Testing not available for this hook')
          end
        end
      end

      context 'when push_events' do
        where(:trigger_name) do
          [
            ["push_events"],
            ["tag_push_events"]
          ]
        end
        with_them do
          it 'executes hook' do
            post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

            expect(response).to have_gitlab_http_status(:created)
          end
        end
      end

      context 'when issue_events' do
        where(:trigger_name) do
          %w[issues_events confidential_issues_events]
        end
        with_them do
          it 'executes hook' do
            create(:issue, project: project)

            post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

            expect(response).to have_gitlab_http_status(:created)
          end

          it 'returns error message if not enough data' do
            post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(json_response['message']).to eq('Ensure the project has issues.')
          end
        end
      end

      context 'when note_events' do
        where(:trigger_name) do
          [
            ["note_events"],
            ["emoji_events"]
          ]
        end
        with_them do
          it 'executes hook' do
            create(:note, :on_issue, project: project)

            post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

            expect(response).to have_gitlab_http_status(:created)
          end

          it 'returns error message if not enough data' do
            post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(json_response['message']).to eq('Ensure the project has notes.')
          end
        end
      end

      context 'when merge_request_events' do
        let(:trigger_name) { 'merge_requests_events' }

        it 'executes hook' do
          create(:merge_request, source_project: project, target_project: project)

          post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

          expect(response).to have_gitlab_http_status(:created)
        end

        it 'returns error message if not enough data' do
          post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq('Ensure the project has merge requests.')
        end
      end

      context 'when job_events' do
        let(:trigger_name) { 'job_events' }

        it 'executes hook' do
          create(:ci_build, project: project, name: 'build')

          post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

          expect(response).to have_gitlab_http_status(:created)
        end

        it 'returns error message if not enough data' do
          post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq('Ensure the project has CI jobs.')
        end
      end

      context 'when pipeline_events' do
        let(:trigger_name) { 'pipeline_events' }

        it 'executes hook' do
          create(:ci_pipeline, project: project, user: user)

          post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

          expect(response).to have_gitlab_http_status(:created)
        end

        it 'returns error message if not enough data' do
          post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq('Ensure the project has CI pipelines.')
        end
      end

      context 'when wiki_page_events' do
        let(:trigger_name) { 'wiki_page_events' }

        it 'executes hook' do
          create(:wiki_page, wiki: project.wiki)

          post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

          expect(response).to have_gitlab_http_status(:created)
        end

        it 'returns error message if wiki is not enabled' do
          project.project_feature.update!(wiki_access_level: ProjectFeature::DISABLED)

          post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq('Ensure the wiki is enabled and has pages.')
        end
      end

      context 'when release_events' do
        let(:trigger_name) { 'releases_events' }

        it 'executes hook' do
          create(:release, project: project)

          post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

          expect(response).to have_gitlab_http_status(:created)
        end

        it 'returns error message if not enough data' do
          post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq('Ensure the project has releases.')
        end
      end

      context 'when resource_access_token_events' do
        let(:trigger_name) { 'resource_access_token_events' }

        it 'executes hook' do
          post api("#{hook_uri}/test/#{trigger_name}", user, admin_mode: user.admin?), params: {}

          expect(response).to have_gitlab_http_status(:created)
        end
      end

      it "returns a 400 error when trigger is invalid" do
        post api("#{hook_uri}/test/xyz", user, admin_mode: user.admin?), params: {}

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('trigger does not have a valid value')
      end

      it "returns a 422 error when request trigger test is not successful" do
        stub_full_request(hook.url, method: :post).to_return(status: 400, body: 'Error response')

        post api("#{hook_uri}/test/push_events", user, admin_mode: user.admin?), params: {}

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message']).to eq('Error response')
      end
    end

    it_behaves_like 'web-hook API endpoints with branch-filter', '/projects/:id'
  end
end
