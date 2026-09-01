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
      created_at: 3.days.ago)
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
        get api('/pipelines', user) # warm up

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { get api('/pipelines', user) }

        create_list(:project, 3, maintainers: user).each do |other_project|
          create(:ci_empty_pipeline, project: other_project, user: user)
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
