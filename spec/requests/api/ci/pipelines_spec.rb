# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Pipelines, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:project2) { create(:project, creator: user) }

  # We need to reload as the shared example 'pipelines visibility table' is changing project
  let_it_be(:project, reload: true) do
    create(:project, :repository, creator: user, maintainers: user)
  end

  let_it_be(:pipeline) do
    create(
      :ci_empty_pipeline,
      project: project,
      sha: project.commit.id,
      ref: project.default_branch,
      user: user,
      name: 'Build pipeline'
    )
  end

  describe 'GET /projects/:id/pipelines ' do
    it_behaves_like 'pipelines visibility table'

    it_behaves_like 'enforcing job token policies', :read_pipelines,
      allow_public_access_for_enabled_project_features: [:repository, :builds] do
      let(:request) do
        get api("/projects/#{project.id}/pipelines"), params: { job_token: target_job.token }
      end
    end

    context 'authorized user' do
      it 'returns project pipelines', :aggregate_failures do
        get api("/projects/#{project.id}/pipelines", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['sha']).to match(/\A\h{40}\z/)
        expect(json_response.first['id']).to eq pipeline.id
        expect(json_response.first['iid']).to eq pipeline.iid
        expect(json_response.first['web_url']).to be_present
      end

      describe 'keys in the response' do
        it 'includes pipeline source' do
          get api("/projects/#{project.id}/pipelines", user)

          expect(json_response.first.keys).to contain_exactly(*%w[id iid project_id sha ref status web_url created_at updated_at source name])
        end
      end

      it 'avoids N+1 queries' do
        # Call to trigger any one time queries
        get api("/projects/#{project.id}/pipelines", user), params: {}

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          get api("/projects/#{project.id}/pipelines", user), params: {}
        end

        3.times do
          create(
            :ci_empty_pipeline,
            project: project,
            sha: project.commit.id,
            ref: project.default_branch,
            user: user,
            name: 'Build pipeline')
        end

        expect do
          get api("/projects/#{project.id}/pipelines", user), params: {}
        end.not_to exceed_all_query_limit(control)
      end

      context 'when parameter is passed' do
        %w[running pending].each do |target|
          context "when scope is #{target}" do
            before do
              create(:ci_pipeline, project: project, status: target)
            end

            it 'returns matched pipelines', :aggregate_failures do
              get api("/projects/#{project.id}/pipelines", user), params: { scope: target }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              json_response.each { |r| expect(r['status']).to eq(target) }
            end
          end
        end

        context 'when scope is finished' do
          before do
            create(:ci_pipeline, project: project, status: 'success')
            create(:ci_pipeline, project: project, status: 'failed')
            create(:ci_pipeline, project: project, status: 'canceled')
          end

          it 'returns matched pipelines' do
            get api("/projects/#{project.id}/pipelines", user), params: { scope: 'finished' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response).not_to be_empty
            json_response.each { |r| expect(r['status']).to be_in(%w[success failed canceled]) }
          end
        end

        context 'when scope is branches or tags' do
          let_it_be(:pipeline_branch) { create(:ci_pipeline, project: project) }
          let_it_be(:pipeline_tag) { create(:ci_pipeline, project: project, ref: 'v1.0.0', tag: true) }

          context 'when scope is branches' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), params: { scope: 'branches' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              expect(json_response.last['id']).to eq(pipeline_branch.id)
            end
          end

          context 'when scope is tags' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), params: { scope: 'tags' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              expect(json_response.last['id']).to eq(pipeline_tag.id)
            end
          end
        end

        context 'when scope is invalid' do
          it 'returns bad_request' do
            get api("/projects/#{project.id}/pipelines", user), params: { scope: 'invalid-scope' }

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        Ci::HasStatus::AVAILABLE_STATUSES.each do |target|
          context "when status is #{target}" do
            before do
              create(:ci_pipeline, project: project, status: target)
              exception_status = Ci::HasStatus::AVAILABLE_STATUSES - [target]
              create(:ci_pipeline, project: project, status: exception_status.sample)
            end

            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), params: { status: target }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              json_response.each { |r| expect(r['status']).to eq(target) }
            end
          end
        end

        context 'when status is invalid' do
          it 'returns bad_request' do
            get api("/projects/#{project.id}/pipelines", user), params: { status: 'invalid-status' }

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context 'when ref is specified' do
          before do
            create(:ci_pipeline, project: project)
          end

          context 'when ref exists' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), params: { ref: 'master' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).not_to be_empty
              json_response.each { |r| expect(r['ref']).to eq('master') }
            end
          end

          context 'when ref does not exist' do
            it 'returns empty' do
              get api("/projects/#{project.id}/pipelines", user), params: { ref: 'invalid-ref' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).to be_empty
            end
          end
        end

        context 'when username is specified' do
          let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }

          context 'when username exists' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), params: { username: user.username }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response.first['id']).to eq(pipeline.id)
            end
          end

          context 'when username does not exist' do
            it 'returns empty' do
              get api("/projects/#{project.id}/pipelines", user), params: { username: 'invalid-username' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response).to be_empty
            end
          end
        end

        context 'when yaml_errors is specified' do
          let_it_be(:pipeline1) { create(:ci_pipeline, project: project, yaml_errors: 'Syntax error') }
          let_it_be(:pipeline2) { create(:ci_pipeline, project: project) }

          context 'when yaml_errors is true' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), params: { yaml_errors: true }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response.first['id']).to eq(pipeline1.id)
            end
          end

          context 'when yaml_errors is false' do
            it 'returns matched pipelines' do
              get api("/projects/#{project.id}/pipelines", user), params: { yaml_errors: false }

              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to include_pagination_headers
              expect(json_response.first['id']).to eq(pipeline2.id)
            end
          end

          context 'when yaml_errors is invalid' do
            it 'returns bad_request' do
              get api("/projects/#{project.id}/pipelines", user), params: { yaml_errors: 'invalid-yaml_errors' }

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end

        context 'when updated_at filters are specified' do
          let_it_be(:pipeline1) { create(:ci_pipeline, project: project, updated_at: 2.days.ago) }
          let_it_be(:pipeline2) { create(:ci_pipeline, project: project, updated_at: 4.days.ago) }
          let_it_be(:pipeline3) { create(:ci_pipeline, project: project, updated_at: 1.hour.ago) }

          it 'returns pipelines with last update date in specified datetime range' do
            get api("/projects/#{project.id}/pipelines", user), params: { updated_before: 1.day.ago, updated_after: 3.days.ago }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response.first['id']).to eq(pipeline1.id)
          end
        end

        context 'when order_by and sort are specified' do
          context 'when order_by user_id' do
            before do
              create_list(:user, 3).each do |some_user|
                create(:ci_pipeline, project: project, user: some_user)
              end
            end

            context 'when sort parameter is valid' do
              it 'sorts as user_id: :desc' do
                get api("/projects/#{project.id}/pipelines", user), params: { order_by: 'user_id', sort: 'desc' }

                expect(response).to have_gitlab_http_status(:ok)
                expect(response).to include_pagination_headers
                expect(json_response).not_to be_empty

                pipeline_ids = Ci::Pipeline.all.order(user_id: :desc).pluck(:id)
                expect(json_response.map { |r| r['id'] }).to eq(pipeline_ids)
              end
            end

            context 'when sort parameter is invalid' do
              it 'returns bad_request' do
                get api("/projects/#{project.id}/pipelines", user), params: { order_by: 'user_id', sort: 'invalid_sort' }

                expect(response).to have_gitlab_http_status(:bad_request)
              end
            end
          end

          context 'when order_by is invalid' do
            it 'returns bad_request' do
              get api("/projects/#{project.id}/pipelines", user), params: { order_by: 'lock_version', sort: 'asc' }

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end

        context 'when a source is specified' do
          before do
            create(:ci_pipeline, project: project, source: :push)
            create(:ci_pipeline, project: project, source: :web)
            create(:ci_pipeline, project: project, source: :api)
          end

          it 'returns matched pipelines' do
            get api("/projects/#{project.id}/pipelines", user), params: { source: 'web' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response).not_to be_empty
            json_response.each { |r| expect(r['source']).to eq('web') }
          end

          context 'when source is invalid' do
            it 'returns bad_request' do
              get api("/projects/#{project.id}/pipelines", user), params: { source: 'invalid-source' }

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end

        context 'when name is provided' do
          let_it_be(:pipeline2) { create(:ci_empty_pipeline, project: project, user: user, name: 'Chatops pipeline') }

          it 'filters by name' do
            get api("/projects/#{project.id}/pipelines", user), params: { name: 'Build pipeline' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response.length).to eq(1)
            expect(json_response.first['name']).to eq('Build pipeline')
          end
        end
      end
    end

    context 'unauthorized user' do
      it 'does not return project pipelines', :aggregate_failures do
        get api("/projects/#{project.id}/pipelines", non_member)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq '404 Project Not Found'
        expect(json_response).not_to be_an Array
      end
    end
  end

  describe 'GET /projects/:id/pipelines/:pipeline_id/jobs' do
    let(:query) { {} }
    let(:api_user) { user }
    let_it_be(:job) do
      create(
        :ci_build,
        :success,
        name: 'build',
        pipeline: pipeline,
        artifacts_expire_at: 1.day.since
      )
    end

    let(:guest) { create(:project_member, :guest, project: project).user }

    context 'when public_builds is false' do
      before do |example|
        unless example.metadata[:skip_before_request]
          project.update!(public_builds: false)
          get api("/projects/#{project.id}/pipelines/#{pipeline.id}/jobs", api_user), params: query
        end
      end

      context 'authorized user' do
        it 'returns pipeline jobs', :aggregate_failures do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
        end

        context 'with oauth token that has ai_workflows scope' do
          let(:token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }

          it "allows access", :skip_before_request do
            get api("/projects/#{project.id}/pipelines/#{pipeline.id}/jobs", oauth_access_token: token), params: query
            project.update!(public_builds: false)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        it 'returns correct values', :aggregate_failures do
          expect(json_response).not_to be_empty
          expect(json_response.first['commit']['id']).to eq project.commit.id
          expect(Time.parse(json_response.first['artifacts_expire_at'])).to be_like_time(job.artifacts_expire_at)
          expect(json_response.first['artifacts_file']).to be_nil
          expect(json_response.first['artifacts']).to be_an Array
          expect(json_response.first['artifacts']).to be_empty
        end

        it_behaves_like 'a job with artifacts and trace' do
          let(:api_endpoint) { "/projects/#{project.id}/pipelines/#{pipeline.id}/jobs" }
        end

        it 'returns pipeline data', :aggregate_failures do
          json_job = json_response.first

          expect(json_job['pipeline']).not_to be_empty
          expect(json_job['pipeline']['id']).to eq job.pipeline.id
          expect(json_job['pipeline']['project_id']).to eq job.pipeline.project_id
          expect(json_job['pipeline']['ref']).to eq job.pipeline.ref
          expect(json_job['pipeline']['sha']).to eq job.pipeline.sha
          expect(json_job['pipeline']['status']).to eq job.pipeline.status
        end

        context 'filter jobs with one scope element' do
          let(:query) { { 'scope' => 'pending' } }

          it :aggregate_failures do
            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_an Array

            expect(json_response).to all match a_hash_including(
              'duration' => be_nil,
              'queued_duration' => (be >= 0.0)
            )
          end
        end

        context 'when filtering to only running jobs' do
          let(:query) { { 'scope' => 'running' } }

          it :aggregate_failures do
            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_an Array

            expect(json_response).to all match a_hash_including(
              'duration' => (be >= 0.0),
              'queued_duration' => (be >= 0.0)
            )
          end
        end

        context 'filter jobs with hash' do
          let(:query) { { scope: { hello: 'pending', world: 'running' } } }

          it { expect(response).to have_gitlab_http_status(:bad_request) }
        end

        context 'filter jobs with array of scope elements' do
          let(:query) { { scope: %w[pending running] } }

          it :aggregate_failures do
            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_an Array
          end
        end

        context 'respond 400 when scope contains invalid state' do
          let(:query) { { scope: %w[unknown running] } }

          it { expect(response).to have_gitlab_http_status(:bad_request) }
        end

        context 'jobs in different pipelines' do
          let!(:pipeline2) { create(:ci_empty_pipeline, project: project) }
          let!(:job2) { create(:ci_build, pipeline: pipeline2) }

          it 'excludes jobs from other pipelines' do
            json_response.each { |job| expect(job['pipeline']['id']).to eq(pipeline.id) }
          end
        end

        it 'avoids N+1 queries' do
          control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
            get api("/projects/#{project.id}/pipelines/#{pipeline.id}/jobs", api_user), params: query
          end

          create_list(:ci_build, 3, :trace_artifact, :artifacts, :test_reports, pipeline: pipeline)

          expect do
            get api("/projects/#{project.id}/pipelines/#{pipeline.id}/jobs", api_user), params: query
          end.not_to exceed_all_query_limit(control)
        end

        context 'pipeline has retried jobs' do
          before_all do
            job.update!(retried: true)
          end

          let_it_be(:successor) { create(:ci_build, :success, name: 'build', pipeline: pipeline) }

          it 'does not return retried jobs by default', :aggregate_failures do
            expect(json_response).to be_an Array
            expect(json_response.length).to eq(1)
          end

          context 'when include_retried is false' do
            let(:query) { { include_retried: false } }

            it 'does not return retried jobs', :aggregate_failures do
              expect(json_response).to be_an Array
              expect(json_response.length).to eq(1)
            end
          end

          context 'when include_retried is true' do
            let(:query) { { include_retried: true } }

            it 'returns retried jobs', :aggregate_failures do
              expect(json_response).to be_an Array
              expect(json_response.length).to eq(2)
              expect(json_response[0]['name']).to eq(json_response[1]['name'])
            end
          end
        end
      end

      context 'no pipeline is found' do
        it 'does not return jobs', :aggregate_failures do
          get api("/projects/#{project2.id}/pipelines/#{pipeline.id}/jobs", user)

          expect(json_response['message']).to eq '404 Project Not Found'
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'unauthorized user' do
        context 'when user is not logged in' do
          let(:api_user) { nil }

          it 'does not return jobs', :aggregate_failures do
            expect(json_response['message']).to eq '404 Project Not Found'
            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when user is guest' do
          let(:guest) { create(:project_member, :guest, project: project).user }
          let(:api_user) { guest }

          it 'does not return jobs' do
            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end
    end

    context 'when public_builds is true' do
      it_behaves_like 'enforcing job token policies', :read_jobs,
        allow_public_access_for_enabled_project_features: [:repository, :builds] do
        let(:request) do
          get api("/projects/#{project.id}/pipelines/#{pipeline.id}/jobs"), params: { job_token: target_job.token }
        end
      end
    end
  end

  describe 'GET /projects/:id/pipelines/:pipeline_id/bridges' do
    let_it_be(:bridge) { create(:ci_bridge, pipeline: pipeline, user: pipeline.user) }

    let(:downstream_pipeline) { create(:ci_pipeline) }

    let!(:pipeline_source) do
      create(
        :ci_sources_pipeline,
        source_pipeline: pipeline,
        source_project: project,
        source_job: bridge,
        pipeline: downstream_pipeline,
        project: downstream_pipeline.project
      )
    end

    let(:query) { {} }
    let(:api_user) { user }

    context 'when public_builds is false' do
      before do |example|
        unless example.metadata[:skip_before_request]
          project.update!(public_builds: false)
          get api("/projects/#{project.id}/pipelines/#{pipeline.id}/bridges", api_user), params: query
        end
      end

      context 'authorized user' do
        it 'returns pipeline bridges', :aggregate_failures do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
        end

        it 'returns correct values', :aggregate_failures do
          expect(json_response).not_to be_empty
          expect(json_response.first['commit']['id']).to eq project.commit.id
          expect(json_response.first['id']).to eq bridge.id
          expect(json_response.first['name']).to eq bridge.name
          expect(json_response.first['stage']).to eq bridge.stage
        end

        it 'returns pipeline data', :aggregate_failures do
          json_bridge = json_response.first

          expect(json_bridge['pipeline']).not_to be_empty
          expect(json_bridge['pipeline']['id']).to eq bridge.pipeline.id
          expect(json_bridge['pipeline']['project_id']).to eq bridge.pipeline.project_id
          expect(json_bridge['pipeline']['ref']).to eq bridge.pipeline.ref
          expect(json_bridge['pipeline']['sha']).to eq bridge.pipeline.sha
          expect(json_bridge['pipeline']['status']).to eq bridge.pipeline.status
        end

        it 'returns downstream pipeline data', :aggregate_failures do
          json_bridge = json_response.first

          expect(json_bridge['downstream_pipeline']).not_to be_empty
          expect(json_bridge['downstream_pipeline']['id']).to eq downstream_pipeline.id
          expect(json_bridge['downstream_pipeline']['project_id']).to eq downstream_pipeline.project_id
          expect(json_bridge['downstream_pipeline']['ref']).to eq downstream_pipeline.ref
          expect(json_bridge['downstream_pipeline']['sha']).to eq downstream_pipeline.sha
          expect(json_bridge['downstream_pipeline']['status']).to eq downstream_pipeline.status
        end

        context 'filter bridges' do
          before_all do
            create_bridge(pipeline, :pending)
            create_bridge(pipeline, :running)
          end

          context 'with one scope element' do
            let(:query) { { 'scope' => 'pending' } }

            it :skip_before_request, :aggregate_failures do
              get api("/projects/#{project.id}/pipelines/#{pipeline.id}/bridges", api_user), params: query

              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response).to be_an Array
              expect(json_response.count).to eq 1
              expect(json_response.first["status"]).to eq "pending"
            end
          end

          context 'with array of scope elements' do
            let(:query) { { scope: %w[pending running] } }

            it :skip_before_request, :aggregate_failures do
              get api("/projects/#{project.id}/pipelines/#{pipeline.id}/bridges", api_user), params: query

              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response).to be_an Array
              expect(json_response.count).to eq 2
              json_response.each { |r| expect(%w[pending running].include?(r['status'])).to be true }
            end
          end
        end

        context 'respond 400 when scope contains invalid state' do
          context 'in an array' do
            let(:query) { { scope: %w[unknown running] } }

            it { expect(response).to have_gitlab_http_status(:bad_request) }
          end

          context 'in a hash' do
            let(:query) { { scope: { unknown: true } } }

            it { expect(response).to have_gitlab_http_status(:bad_request) }
          end

          context 'in a string' do
            let(:query) { { scope: "unknown" } }

            it { expect(response).to have_gitlab_http_status(:bad_request) }
          end
        end

        context 'bridges in different pipelines' do
          let!(:pipeline2) { create(:ci_empty_pipeline, project: project) }
          let!(:bridge2) { create(:ci_bridge, pipeline: pipeline2) }

          it 'excludes bridges from other pipelines' do
            json_response.each { |bridge| expect(bridge['pipeline']['id']).to eq(pipeline.id) }
          end
        end

        it 'avoids N+1 queries', :use_sql_query_cache, :request_store do
          control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
            get api("/projects/#{project.id}/pipelines/#{pipeline.id}/bridges", api_user), params: query
          end

          3.times { create_bridge(pipeline) }

          expect do
            get api("/projects/#{project.id}/pipelines/#{pipeline.id}/bridges", api_user), params: query
          end.to issue_same_number_of_queries_as(control)
        end
      end

      context 'no pipeline is found' do
        it 'does not return bridges', :aggregate_failures do
          get api("/projects/#{project2.id}/pipelines/#{pipeline.id}/bridges", user)

          expect(json_response['message']).to eq '404 Project Not Found'
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'unauthorized user' do
        context 'when user is not logged in' do
          let(:api_user) { nil }

          it 'does not return bridges', :aggregate_failures do
            expect(json_response['message']).to eq '404 Project Not Found'
            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when user is guest' do
          let(:api_user) { guest }
          let(:guest) { create(:project_member, :guest, project: project).user }

          it 'does not return bridges' do
            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when user has no read_build access for project' do
          before do
            project.add_guest(api_user)
          end

          it 'does not return bridges' do
            get api("/projects/#{project.id}/pipelines/#{pipeline.id}/bridges", api_user)
            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end

      def create_bridge(pipeline, status = :created)
        create(:ci_bridge, status: status, pipeline: pipeline, user: pipeline.user).tap do |bridge|
          downstream_pipeline = create(:ci_pipeline)
          create(
            :ci_sources_pipeline,
            source_pipeline: pipeline,
            source_project: pipeline.project,
            source_job: bridge,
            pipeline: downstream_pipeline,
            project: downstream_pipeline.project
          )
        end
      end
    end

    context 'when public_builds is true' do
      it_behaves_like 'enforcing job token policies', :read_pipelines,
        allow_public_access_for_enabled_project_features: [:repository, :builds] do
        let(:request) do
          get api("/projects/#{project.id}/pipelines/#{pipeline.id}/bridges"), params: { job_token: target_job.token }
        end
      end
    end
  end

  describe 'POST /projects/:id/pipeline ' do
    def expect_variables(variables, expected_variables)
      variables.each_with_index do |variable, index|
        expected_variable = expected_variables[index]

        expect(variable.key).to eq(expected_variable['key'])
        expect(variable.value).to eq(expected_variable['value'])
        expect(variable.variable_type).to eq(expected_variable['variable_type'])
      end
    end

    context 'authorized user' do
      context 'with gitlab-ci.yml' do
        before do
          stub_ci_pipeline_to_return_yaml_file
        end

        it 'creates and returns a new pipeline', :aggregate_failures do
          expect do
            post api("/projects/#{project.id}/pipeline", user), params: { ref: project.default_branch }
          end.to change { project.ci_pipelines.count }.by(1)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to be_a Hash
          expect(json_response['sha']).to eq project.commit.id
        end

        context 'variables given' do
          let(:variables) { [{ 'variable_type' => 'file', 'key' => 'UPLOAD_TO_S3', 'value' => 'true' }] }

          before do
            project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
          end

          it 'creates and returns a new pipeline using the given variables', :aggregate_failures do
            expect do
              post api("/projects/#{project.id}/pipeline", user), params: { ref: project.default_branch, variables: variables }
            end.to change { project.ci_pipelines.count }.by(1)
            expect_variables(project.ci_pipelines.last.variables, variables)

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response).to be_a Hash
            expect(json_response['sha']).to eq project.commit.id
            expect(json_response).not_to have_key('variables')
          end
        end

        describe 'using variables conditions' do
          let(:variables) { [{ 'variable_type' => 'env_var', 'key' => 'STAGING', 'value' => 'true' }] }

          before do
            config = YAML.dump(test: { script: 'test', only: { variables: ['$STAGING'] } })
            stub_ci_pipeline_yaml_file(config)
            project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
          end

          it 'creates and returns a new pipeline using the given variables', :aggregate_failures do
            expect do
              post api("/projects/#{project.id}/pipeline", user), params: { ref: project.default_branch, variables: variables }
            end.to change { project.ci_pipelines.count }.by(1)
            expect_variables(project.ci_pipelines.last.variables, variables)

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response).to be_a Hash
            expect(json_response['sha']).to eq project.commit.id
            expect(json_response).not_to have_key('variables')
          end

          context 'condition unmatch' do
            let(:variables) { [{ 'key' => 'STAGING', 'value' => 'false' }] }

            it "doesn't create a job" do
              expect do
                post api("/projects/#{project.id}/pipeline", user), params: { ref: project.default_branch }
              end.not_to change { project.ci_pipelines.count }

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end

        it 'fails when using an invalid ref', :aggregate_failures do
          post api("/projects/#{project.id}/pipeline", user), params: { ref: 'invalid_ref' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['base'].first).to eq 'Reference not found'
          expect(json_response).not_to be_an Array
        end
      end

      context 'with gitlab-ci.yml including inputs' do
        let(:inputs) do
          {
            deploy_strategy: 'blue-green',
            job_stage: 'deploy',
            test_script: ['echo "test"'],
            parallel_jobs: 3,
            allow_failure: true,
            test_rules: [
              { if: '$CI_PIPELINE_SOURCE == "web"' }
            ]
          }
        end

        before do
          stub_ci_pipeline_yaml_file(
            File.read(Rails.root.join('spec/lib/gitlab/ci/config/yaml/fixtures/complex-included-ci.yml'))
          )
        end

        shared_examples 'creating a succesful pipeline' do
          it 'creates a pipeline using inputs' do
            expect { post_request }.to change { Ci::Pipeline.count }.by(1)

            expect(response).to have_gitlab_http_status(:created)

            pipeline = Ci::Pipeline.find(json_response['id'])

            expect(pipeline.builds.map { |b| "#{b.name} #{b.allow_failure}" }).to contain_exactly(
              'my-job-build 1/3 false', 'my-job-build 2/3 false', 'my-job-build 3/3 false',
              'my-job-test true', 'my-job-deploy false'
            )
          end
        end

        context 'when passing parameters as JSON' do
          let(:headers) do
            { 'Content-Type' => 'application/json' }
          end

          subject(:post_request) do
            post api("/projects/#{project.id}/pipeline", user),
              headers: headers,
              params: { ref: project.default_branch, inputs: inputs }.to_json
          end

          it_behaves_like 'creating a succesful pipeline'
        end

        context 'when passing parameters as form data' do
          let(:headers) do
            { 'Content-Type' => 'application/x-www-form-urlencoded' }
          end

          let(:transformed_values) do
            inputs.transform_values { |value| value.is_a?(String) ? value : value.to_json }
          end

          subject(:post_request) do
            post api("/projects/#{project.id}/pipeline", user),
              headers: headers,
              params: { ref: project.default_branch, inputs: transformed_values }
          end

          it_behaves_like 'creating a succesful pipeline'
        end
      end

      context 'without gitlab-ci.yml' do
        context 'without auto devops enabled' do
          before do
            project.update!(auto_devops_attributes: { enabled: false })
          end

          it 'fails to create pipeline', :aggregate_failures do
            post api("/projects/#{project.id}/pipeline", user), params: { ref: project.default_branch }

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']['base'].first).to eq 'Missing CI config file'
            expect(json_response).not_to be_an Array
          end
        end
      end
    end

    context 'unauthorized user' do
      it 'does not create pipeline', :aggregate_failures do
        post api("/projects/#{project.id}/pipeline", non_member), params: { ref: project.default_branch }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq '404 Project Not Found'
        expect(json_response).not_to be_an Array
      end
    end
  end

  describe 'GET /projects/:id/pipelines/:pipeline_id' do
    it_behaves_like 'pipelines visibility table' do
      let(:pipelines_api_path) do
        "/projects/#{project.id}/pipelines/#{pipeline.id}"
      end

      let(:api_response) { response_status == 200 ? response : json_response }
      let(:response_200) { match_response_schema('public_api/v4/pipeline/detail') }
    end

    it_behaves_like 'enforcing job token policies', :read_pipelines,
      allow_public_access_for_enabled_project_features: [:repository, :builds] do
      let(:request) do
        get api("/projects/#{project.id}/pipelines/#{pipeline.id}"), params: { job_token: target_job.token }
      end
    end

    context 'authorized user' do
      it 'exposes known attributes', :aggregate_failures do
        get api("/projects/#{project.id}/pipelines/#{pipeline.id}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/pipeline/detail')
      end

      it 'returns project pipeline', :aggregate_failures do
        get api("/projects/#{project.id}/pipelines/#{pipeline.id}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['sha']).to match(/\A\h{40}\z/)
        expect(json_response['name']).to eq('Build pipeline')
      end

      context 'with oauth token that has ai_workflows scope' do
        let(:token) { create(:oauth_access_token, user: user, scopes: [:ai_workflows]) }

        it "allows access", :skip_before_request do
          get api("/projects/#{project.id}/pipelines/#{pipeline.id}", oauth_access_token: token)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      it 'returns 404 when it does not exist', :aggregate_failures do
        get api("/projects/#{project.id}/pipelines/#{non_existing_record_id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq '404 Not found'
        expect(json_response['id']).to be_nil
      end

      context 'with coverage' do
        before do
          create(:ci_build, coverage: 30, pipeline: pipeline)
        end

        it 'exposes the coverage' do
          get api("/projects/#{project.id}/pipelines/#{pipeline.id}", user)

          expect(json_response["coverage"]).to eq('30.00')
        end
      end
    end

    context 'unauthorized user' do
      it 'does not return a project pipeline', :aggregate_failures do
        get api("/projects/#{project.id}/pipelines/#{pipeline.id}", non_member)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq '404 Project Not Found'
        expect(json_response['id']).to be_nil
      end
    end

    context 'when pipeline is a dangling pipeline' do
      let(:dangling_source) { Enums::Ci::Pipeline.dangling_sources.each_value.first }

      let(:dangling_pipeline) do
        create(:ci_pipeline, source: dangling_source, project: project)
      end

      it 'returns the specified pipeline', :aggregate_failures do
        get api("/projects/#{project.id}/pipelines/#{dangling_pipeline.id}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['sha']).to eq(dangling_pipeline.sha)
      end
    end
  end

  describe 'GET /projects/:id/pipelines/latest' do
    context 'authorized user' do
      let(:second_branch) { project.repository.branches[2] }

      let!(:second_pipeline) do
        create(
          :ci_empty_pipeline,
          project: project,
          sha: second_branch.target,
          ref: second_branch.name,
          user: user,
          name: 'Build pipeline'
        )
      end

      before do
        create(
          :ci_empty_pipeline,
          project: project,
          sha: project.commit.parent.id,
          ref: project.default_branch,
          user: user
        )
      end

      context 'default repository branch' do
        it 'gets the latest pipleine', :aggregate_failures do
          get api("/projects/#{project.id}/pipelines/latest", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/pipeline/detail')
          expect(json_response['ref']).to eq(project.default_branch)
          expect(json_response['sha']).to eq(project.commit.id)
          expect(json_response['name']).to eq('Build pipeline')
        end
      end

      context 'ref parameter' do
        it 'gets the latest pipleine', :aggregate_failures do
          get api("/projects/#{project.id}/pipelines/latest", user), params: { ref: second_branch.name }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/pipeline/detail')
          expect(json_response['ref']).to eq(second_branch.name)
          expect(json_response['sha']).to eq(second_branch.target)
        end
      end
    end

    context 'unauthorized user' do
      it 'does not return a project pipeline', :aggregate_failures do
        get api("/projects/#{project.id}/pipelines/#{pipeline.id}", non_member)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq '404 Project Not Found'
        expect(json_response['id']).to be_nil
      end
    end
  end

  describe 'GET /projects/:id/pipelines/:pipeline_id/variables' do
    subject { get api("/projects/#{project.id}/pipelines/#{pipeline.id}/variables", api_user) }

    let(:api_user) { user }

    context 'user is a mantainer' do
      it 'returns pipeline variables empty', :aggregate_failures do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_empty
      end

      context 'with variables' do
        let!(:variable) { create(:ci_pipeline_variable, pipeline: pipeline, key: 'foo', value: 'bar') }

        it 'returns pipeline variables', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to contain_exactly({
            "variable_type" => "env_var",
            "key" => "foo",
            "value" => "bar",
            "raw" => false
          })
        end
      end
    end

    context 'user is a developer' do
      let(:pipeline_owner_user) { create(:user) }
      let(:pipeline) { create(:ci_empty_pipeline, project: project, user: pipeline_owner_user) }

      before do
        project.add_developer(api_user)
      end

      context 'pipeline created by the developer user' do
        let(:api_user) { pipeline_owner_user }
        let!(:variable) { create(:ci_pipeline_variable, pipeline: pipeline, key: 'foo', value: 'bar') }

        it 'returns pipeline variables', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to contain_exactly({
            "variable_type" => "env_var",
            "key" => "foo",
            "value" => "bar",
            "raw" => false
          })
        end
      end

      context 'pipeline created is not created by the developer user' do
        let(:api_user) { create(:user) }

        it 'does not return pipeline variables' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'user is not a project member' do
      it 'does not return pipeline variables', :aggregate_failures do
        get api("/projects/#{project.id}/pipelines/#{pipeline.id}/variables", non_member)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq '404 Project Not Found'
      end
    end
  end

  describe 'DELETE /projects/:id/pipelines/:pipeline_id' do
    context 'authorized user' do
      let(:owner) { project.first_owner }

      it 'destroys the pipeline', :aggregate_failures do
        delete api("/projects/#{project.id}/pipelines/#{pipeline.id}", owner)

        expect(response).to have_gitlab_http_status(:no_content)
        expect { pipeline.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'returns 404 when it does not exist', :aggregate_failures do
        delete api("/projects/#{project.id}/pipelines/#{non_existing_record_id}", owner)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq '404 Not found'
      end

      it 'does not log an audit event' do
        expect { delete api("/projects/#{project.id}/pipelines/#{pipeline.id}", owner) }.not_to change { AuditEvent.count }
      end

      context 'when the pipeline has jobs' do
        let_it_be(:build) { create(:ci_build, project: project, pipeline: pipeline) }

        it 'destroys associated jobs', :aggregate_failures do
          delete api("/projects/#{project.id}/pipelines/#{pipeline.id}", owner)

          expect(response).to have_gitlab_http_status(:no_content)
          expect { build.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when project is undergoing stats refresh' do
        it_behaves_like 'preventing request because of ongoing project stats refresh' do
          let(:make_request) { delete api("/projects/#{project.id}/pipelines/#{pipeline.id}", owner) }

          it 'does not delete the pipeline' do
            make_request

            expect(pipeline.reload).to be_persisted
          end
        end
      end
    end

    context 'unauthorized user' do
      context 'when user is not member' do
        it 'returns a 404', :aggregate_failures do
          delete api("/projects/#{project.id}/pipelines/#{pipeline.id}", non_member)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq '404 Project Not Found'
        end
      end

      context 'when user is developer' do
        let(:developer) { create(:user) }

        before do
          project.add_developer(developer)
        end

        it 'returns a 403', :aggregate_failures do
          delete api("/projects/#{project.id}/pipelines/#{pipeline.id}", developer)

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq '403 Forbidden'
        end
      end
    end
  end

  describe 'PUT /projects/:id/pipelines/:pipeline_id/name' do
    let_it_be(:pipeline_creator) { create(:user) }
    let(:pipeline) { create(:ci_pipeline, project: project, user: pipeline_creator) }
    let(:name) { 'A new pipeline name' }

    subject(:execute) do
      put api("/projects/#{project.id}/pipelines/#{pipeline.id}/metadata", current_user), params: { name: name }
    end

    it_behaves_like 'enforcing job token policies', :admin_pipelines do
      let(:request) do
        put api("/projects/#{source_project.id}/pipelines/#{pipeline.id}/metadata"),
          params: { name: name, job_token: target_job.token }
      end
    end

    context 'authorized user' do
      let(:current_user) { create(:user) }

      before do
        project.add_developer(current_user)
      end

      it 'renames pipeline when name is valid', :aggregate_failures do
        expect { execute }.to change { pipeline.reload.name }.to(name)
        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when name is invalid' do
        let(:name) { 'a' * 256 }

        it 'does not rename pipeline', :aggregate_failures do
          expect { execute }.not_to change { pipeline.reload.name }
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq('Failed to update pipeline - Name is too long (maximum is 255 characters)')
        end
      end
    end

    context 'unauthorized user' do
      let(:current_user) { create(:user) }

      context 'when user is not a member' do
        it 'does not rename pipeline', :aggregate_failures do
          expect { execute }.not_to change { pipeline.reload.name }
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user is a member' do
        before do
          project.add_reporter(current_user)
        end

        it 'does not rename pipeline', :aggregate_failures do
          expect { execute }.not_to change { pipeline.reload.name }
          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when authorized with job token' do
      let(:job) { create(:ci_build, :running, pipeline: pipeline, project: project, user: pipeline.user) }

      before do
        project.add_developer(pipeline.user)
      end

      subject(:execute) do
        put api("/projects/#{project.id}/pipelines/#{pipeline.id}/metadata", nil, job_token: job.token), params: { name: name }
      end

      it 'renames pipeline when name is valid', :aggregate_failures do
        expect { execute }.to change { pipeline.reload.name }.to(name)
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'POST /projects/:id/pipelines/:pipeline_id/retry' do
    context 'authorized user' do
      let_it_be(:pipeline) do
        create(:ci_pipeline, project: project, sha: project.commit.id, ref: project.default_branch)
      end

      let_it_be(:build) { create(:ci_build, :failed, pipeline: pipeline) }

      it 'retries failed builds', :aggregate_failures do
        expect do
          post api("/projects/#{project.id}/pipelines/#{pipeline.id}/retry", user)
        end.to change { pipeline.builds.count }.from(1).to(2)

        expect(response).to have_gitlab_http_status(:created)
        expect(build.reload.retried?).to be true
      end
    end

    context 'unauthorized user' do
      it 'does not return a project pipeline', :aggregate_failures do
        post api("/projects/#{project.id}/pipelines/#{pipeline.id}/retry", non_member)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq '404 Project Not Found'
        expect(json_response['id']).to be_nil
      end
    end

    context 'handles errors' do
      before do
        service_response = ServiceResponse.error(http_status: 403, message: 'hello world')
        allow_next_instance_of(::Ci::RetryPipelineService) do |service|
          allow(service).to receive(:check_access).and_return(service_response)
        end
      end

      it 'returns error', :aggregate_failures do
        post api("/projects/#{project.id}/pipelines/#{pipeline.id}/retry", user)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq 'hello world'
        expect(json_response['id']).to be_nil
      end
    end
  end

  describe 'POST /projects/:id/pipelines/:pipeline_id/cancel' do
    let_it_be(:pipeline) do
      create(:ci_empty_pipeline, project: project, sha: project.commit.id, ref: project.default_branch)
    end

    let_it_be(:job) { create(:ci_build, :running, pipeline: pipeline) }

    context 'authorized user', :aggregate_failures do
      context 'when supports canceling is true' do
        include_context 'when canceling support'

        it 'cancels builds', :sidekiq_inline do
          post api("/projects/#{project.id}/pipelines/#{pipeline.id}/cancel", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['status']).to eq('canceling')
        end
      end

      context 'when cancel_gracefully is not supported by the runner' do
        it 'cancels builds', :sidekiq_inline do
          post api("/projects/#{project.id}/pipelines/#{pipeline.id}/cancel", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['status']).to eq('canceled')
        end
      end
    end

    context 'user without proper access rights' do
      let_it_be(:reporter) { create(:user) }

      before do
        project.add_reporter(reporter)
      end

      it 'rejects the action', :aggregate_failures do
        post api("/projects/#{project.id}/pipelines/#{pipeline.id}/cancel", reporter)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(pipeline.reload.status).to eq('pending')
      end
    end
  end

  describe 'GET /projects/:id/pipelines/:pipeline_id/test_report' do
    context 'authorized user' do
      subject { get api("/projects/#{project.id}/pipelines/#{pipeline.id}/test_report", user) }

      let(:pipeline) { create(:ci_pipeline, project: project) }

      context 'when pipeline does not have a test report' do
        it 'returns an empty test report', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['total_count']).to eq(0)
        end
      end

      context 'when pipeline has a test report' do
        let(:pipeline) { create(:ci_pipeline, :with_test_reports, project: project) }

        it 'returns the test report', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['total_count']).to eq(4)
        end
      end

      context 'when pipeline has corrupt test reports' do
        before do
          create(:ci_build, :broken_test_reports, name: 'rspec', pipeline: pipeline)
        end

        it 'returns a suite_error', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['test_suites'].first['suite_error']).to eq('JUnit XML parsing failed: 1:1: FATAL: Document is empty')
        end
      end

      context 'caching', :use_clean_rails_redis_caching, :clean_gitlab_redis_shared_state do
        context 'when the test report is not ready yet' do
          it 'does not cache the endpoint' do
            api("/projects/#{project.id}/pipelines/#{pipeline.id}/test_report", user)

            expect(TestReportEntity).to receive(:represent)

            get api("/projects/#{project.id}/pipelines/#{pipeline.id}/test_report", user)
          end
        end

        context 'when the test report is ready' do
          before do
            allow_next_found_instance_of(Ci::Pipeline) do |pipeline|
              allow(pipeline).to receive(:has_test_reports?).and_return(true)
            end
          end

          it 'caches the test report' do
            get api("/projects/#{project.id}/pipelines/#{pipeline.id}/test_report", user)

            expect(TestReportEntity).not_to receive(:represent)

            get api("/projects/#{project.id}/pipelines/#{pipeline.id}/test_report", user)
          end
        end
      end
    end

    context 'unauthorized user' do
      it 'does not return project pipelines', :aggregate_failures do
        get api("/projects/#{project.id}/pipelines/#{pipeline.id}/test_report", non_member)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq '404 Project Not Found'
      end
    end
  end

  describe 'GET /projects/:id/pipelines/:pipeline_id/test_report_summary' do
    subject { get api("/projects/#{project.id}/pipelines/#{pipeline.id}/test_report_summary", current_user) }

    context 'authorized user' do
      let(:current_user) { user }

      let(:pipeline) { create(:ci_pipeline, project: project) }

      context 'when pipeline does not have a test report summary' do
        it 'returns an empty test report summary', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['total']['count']).to eq(0)
        end
      end

      context 'when pipeline has a test report summary' do
        let(:pipeline) { create(:ci_pipeline, :with_report_results, project: project) }

        it 'returns the test report summary', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['total']['count']).to eq(2)
        end
      end
    end

    context 'unauthorized user' do
      it 'does not return project pipelines', :aggregate_failures do
        get api("/projects/#{project.id}/pipelines/#{pipeline.id}/test_report_summary", non_member)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq '404 Project Not Found'
      end
    end
  end
end
