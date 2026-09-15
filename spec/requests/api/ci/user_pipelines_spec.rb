# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::UserPipelines, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: user) }
  let_it_be(:private_project) { create(:project, :private) }

  let_it_be(:pipeline) do
    create(:ci_empty_pipeline, project: project, user: user, name: 'Build pipeline', created_at: 1.day.ago)
  end

  let_it_be(:pipeline2) do
    create(:ci_empty_pipeline, project: project, user: user, status: 'success', source: :web,
      created_at: 3.days.ago, started_at: 3.days.ago + 60.seconds,
      finished_at: 3.days.ago + 187.seconds, duration: 127)
  end

  let_it_be(:child_pipeline) do
    create(:ci_empty_pipeline, project: project, user: user, source: :parent_pipeline)
  end

  let_it_be(:other_user_pipeline) do
    create(:ci_empty_pipeline, project: project, user: non_member)
  end

  let_it_be(:inaccessible_pipeline) do
    create(:ci_empty_pipeline, project: private_project, user: user, created_at: 5.days.ago)
  end

  describe 'GET /pipelines' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get api('/pipelines')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'returns pipelines triggered by the user, newest first', :aggregate_failures do
        get api('/pipelines', user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to eq([pipeline.id, pipeline2.id])
        expect(json_response.first['web_url']).to include("/-/pipelines/#{pipeline.id}")
        expect(json_response.first['name']).to eq('Build pipeline')
      end

      it 'includes the project of each pipeline' do
        get api('/pipelines', user)

        expect(json_response.first['project']).to include(
          'id' => project.id,
          'name' => project.name,
          'path' => project.path,
          'path_with_namespace' => project.full_path
        )
      end

      it 'includes timing information and the detailed status', :aggregate_failures do
        get api('/pipelines', user)

        entry = json_response.find { |p| p['id'] == pipeline2.id }
        expect(entry).to include('duration' => 127, 'queued_duration' => 60)
        expect(entry['started_at']).to be_present
        expect(entry['finished_at']).to be_present
        expect(entry['detailed_status']).to include(
          'icon' => 'status_success',
          'group' => 'success',
          'text' => 'Passed'
        )
      end

      context 'with merge request pipelines' do
        let_it_be(:mr_project) { create(:project, :repository, maintainers: user) }
        let_it_be(:merge_request) do
          create(:merge_request, source_project: mr_project, target_project: mr_project)
        end

        let_it_be(:mr_pipeline) do
          create(:ci_empty_pipeline, project: mr_project, user: user, source: :merge_request_event,
            merge_request: merge_request, created_at: 12.hours.ago)
        end

        it 'includes the merge request of merge request pipelines' do
          get api('/pipelines', user)

          entry = json_response.find { |p| p['id'] == mr_pipeline.id }
          expect(entry['merge_request']).to eq(
            'iid' => merge_request.iid,
            'title' => merge_request.title,
            'web_url' => Gitlab::UrlBuilder.build(merge_request)
          )
        end

        it 'does not include a merge request for other pipelines' do
          get api('/pipelines', user)

          entry = json_response.find { |p| p['id'] == pipeline.id }
          expect(entry).not_to have_key('merge_request')
        end

        context 'when the user cannot read the merge request' do
          let_it_be(:no_mr_project, freeze: false) { create(:project, :repository, maintainers: user) }

          let_it_be(:hidden_merge_request) do
            create(:merge_request, source_project: no_mr_project, target_project: no_mr_project)
          end

          let_it_be(:hidden_mr_pipeline) do
            create(:ci_empty_pipeline, project: no_mr_project, user: user, source: :merge_request_event,
              merge_request: hidden_merge_request, created_at: 11.hours.ago)
          end

          before_all do
            no_mr_project.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)
          end

          it 'returns the pipeline without its merge request', :aggregate_failures do
            get api('/pipelines', user)

            entry = json_response.find { |p| p['id'] == hidden_mr_pipeline.id }
            expect(entry).to be_present
            expect(entry).not_to have_key('merge_request')
          end
        end
      end

      it 'does not return counted offset pagination headers' do
        get api('/pipelines', user)

        expect(response.headers).not_to include('X-Total', 'X-Total-Pages', 'X-Page')
      end

      it 'paginates with keyset pagination', :aggregate_failures do
        get api('/pipelines', user), params: { per_page: 1 }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to eq([pipeline.id])
        expect(response.headers['Link']).to include('rel="next"')

        cursor = response.headers['X-Next-Cursor']
        expect(cursor).to be_present

        get api('/pipelines', user), params: { per_page: 1, cursor: cursor }

        expect(json_response.pluck('id')).to eq([pipeline2.id])
      end

      it 'ignores offset pagination params' do
        get api('/pipelines', user), params: { page: 2 }

        expect(json_response.pluck('id')).to match_array([pipeline.id, pipeline2.id])
      end

      it 'returns bad request when per_page is above the maximum' do
        get api('/pipelines', user), params: { per_page: 101 }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns bad request for an unsupported sort order' do
        get api('/pipelines', user), params: { sort: 'asc' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns bad request for an unsupported order_by column' do
        get api('/pipelines', user), params: { order_by: 'updated_at' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'does not return pipelines from projects the user cannot read' do
        get api('/pipelines', user)

        expect(json_response.pluck('id')).not_to include(inaccessible_pipeline.id)
      end

      it 'returns only child pipelines when source is parent_pipeline' do
        get api('/pipelines', user), params: { source: 'parent_pipeline' }

        expect(json_response.pluck('id')).to contain_exactly(child_pipeline.id)
      end

      it 'filters by creation date' do
        get api('/pipelines', user), params: { created_after: 2.days.ago.iso8601 }

        expect(json_response.pluck('id')).to contain_exactly(pipeline.id)
      end

      it 'avoids N+1 queries when pipelines from more projects are returned', :request_store, :use_sql_query_cache do
        control_mr_project = create(:project, :repository, maintainers: user)
        control_mr = create(:merge_request, source_project: control_mr_project, target_project: control_mr_project)
        create(:ci_empty_pipeline, project: control_mr_project, user: user, source: :merge_request_event,
          merge_request: control_mr)

        get api('/pipelines', user) # warm up

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { get api('/pipelines', user) }

        create_list(:project, 3, maintainers: user).each do |other_project|
          create(:ci_empty_pipeline, project: other_project, user: user)
        end

        create_list(:project, 2, :repository, maintainers: user).each do |other_project|
          merge_request = create(:merge_request, source_project: other_project, target_project: other_project)
          create(:ci_empty_pipeline, project: other_project, user: user, source: :merge_request_event,
            merge_request: merge_request)
        end

        expect { get api('/pipelines', user) }.to issue_same_number_of_queries_as(control)
      end
    end

    %i[ai_workflows mcp].each do |scope|
      context "when authenticating with a token scoped to #{scope}" do
        it 'does not authorize the token' do
          token = create(:oauth_access_token, resource_owner: user, scopes: [scope])

          get api('/pipelines', oauth_access_token: token)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    it_behaves_like 'authorizing granular token permissions', :read_pipeline do
      let(:boundary_object) { :user }
      let(:request) do
        get api('/pipelines', personal_access_token: pat)
      end
    end
  end
end
