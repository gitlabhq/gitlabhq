# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Jobs do
  include HttpBasicAuthHelpers
  include DependencyProxyHelpers

  using RSpec::Parameterized::TableSyntax
  include HttpIOHelpers

  let_it_be(:project, reload: true) do
    create(:project, :repository, public_builds: false)
  end

  let_it_be(:pipeline, reload: true) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id,
                         ref: project.default_branch)
  end

  let(:user) { create(:user) }
  let(:api_user) { user }
  let(:reporter) { create(:project_member, :reporter, project: project).user }
  let(:guest) { create(:project_member, :guest, project: project).user }

  let(:running_job) do
    create(:ci_build, :running, project: project,
                                user: user,
                                pipeline: pipeline,
                                artifacts_expire_at: 1.day.since)
  end

  let!(:job) do
    create(:ci_build, :success, :tags, pipeline: pipeline,
                                artifacts_expire_at: 1.day.since)
  end

  before do
    project.add_developer(user)
  end

  shared_examples 'returns common pipeline data' do
    it 'returns common pipeline data' do
      expect(json_response['pipeline']).not_to be_empty
      expect(json_response['pipeline']['id']).to eq jobx.pipeline.id
      expect(json_response['pipeline']['project_id']).to eq jobx.pipeline.project_id
      expect(json_response['pipeline']['ref']).to eq jobx.pipeline.ref
      expect(json_response['pipeline']['sha']).to eq jobx.pipeline.sha
      expect(json_response['pipeline']['status']).to eq jobx.pipeline.status
    end
  end

  shared_examples 'returns common job data' do
    it 'returns common job data' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(jobx.id)
      expect(json_response['status']).to eq(jobx.status)
      expect(json_response['stage']).to eq(jobx.stage)
      expect(json_response['name']).to eq(jobx.name)
      expect(json_response['ref']).to eq(jobx.ref)
      expect(json_response['tag']).to eq(jobx.tag)
      expect(json_response['coverage']).to eq(jobx.coverage)
      expect(json_response['allow_failure']).to eq(jobx.allow_failure)
      expect(Time.parse(json_response['created_at'])).to be_like_time(jobx.created_at)
      expect(Time.parse(json_response['started_at'])).to be_like_time(jobx.started_at)
      expect(Time.parse(json_response['artifacts_expire_at'])).to be_like_time(jobx.artifacts_expire_at)
      expect(json_response['artifacts_file']).to be_nil
      expect(json_response['artifacts']).to be_an Array
      expect(json_response['artifacts']).to be_empty
      expect(json_response['web_url']).to be_present
    end
  end

  shared_examples 'returns unauthorized' do
    it 'returns unauthorized' do
      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  describe 'GET /job' do
    shared_context 'with auth headers' do
      let(:headers_with_token) { header }
      let(:params_with_token) { {} }
    end

    shared_context 'with auth params' do
      let(:headers_with_token) { {} }
      let(:params_with_token) { param }
    end

    shared_context 'without auth' do
      let(:headers_with_token) { {} }
      let(:params_with_token) { {} }
    end

    before do |example|
      unless example.metadata[:skip_before_request]
        get api('/job'), headers: headers_with_token, params: params_with_token
      end
    end

    context 'when token is valid but not CI_JOB_TOKEN' do
      let(:token) { create(:personal_access_token, user: user) }

      include_context 'with auth headers' do
        let(:header) { { 'Private-Token' => token.token } }
      end

      it 'returns not found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with job token authentication header' do
      include_context 'with auth headers' do
        let(:header) { { API::Ci::Helpers::Runner::JOB_TOKEN_HEADER => running_job.token } }
      end

      it_behaves_like 'returns common job data' do
        let(:jobx) { running_job }
      end

      it 'returns specific job data' do
        expect(json_response['finished_at']).to be_nil
      end

      it_behaves_like 'returns common pipeline data' do
        let(:jobx) { running_job }
      end
    end

    context 'with job token authentication params' do
      include_context 'with auth params' do
        let(:param) { { job_token: running_job.token } }
      end

      it_behaves_like 'returns common job data' do
        let(:jobx) { running_job }
      end

      it 'returns specific job data' do
        expect(json_response['finished_at']).to be_nil
      end

      it_behaves_like 'returns common pipeline data' do
        let(:jobx) { running_job }
      end
    end

    context 'with non running job' do
      include_context 'with auth headers' do
        let(:header) { { API::Ci::Helpers::Runner::JOB_TOKEN_HEADER => job.token } }
      end

      it_behaves_like 'returns unauthorized'
    end

    context 'with basic auth header' do
      let(:personal_access_token) { create(:personal_access_token, user: user) }
      let(:token) { personal_access_token.token}

      include_context 'with auth headers' do
        let(:header) { { Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER => token } }
      end

      it 'does not return a job' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'without authentication' do
      include_context 'without auth'

      it_behaves_like 'returns unauthorized'
    end
  end

  describe 'GET /projects/:id/jobs' do
    let(:query) { {} }

    before do |example|
      unless example.metadata[:skip_before_request]
        get api("/projects/#{project.id}/jobs", api_user), params: query
      end
    end

    context 'authorized user' do
      it 'returns project jobs' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
      end

      it 'returns correct values' do
        expect(json_response).not_to be_empty
        expect(json_response.first['commit']['id']).to eq project.commit.id
        expect(Time.parse(json_response.first['artifacts_expire_at'])).to be_like_time(job.artifacts_expire_at)
        expect(json_response.first['tag_list'].sort).to eq job.tag_list.sort
      end

      context 'without artifacts and trace' do
        it 'returns no artifacts nor trace data' do
          json_job = json_response.first

          expect(json_job['artifacts_file']).to be_nil
          expect(json_job['artifacts']).to be_an Array
          expect(json_job['artifacts']).to be_empty
        end
      end

      it_behaves_like 'a job with artifacts and trace' do
        let(:api_endpoint) { "/projects/#{project.id}/jobs" }
      end

      it 'returns pipeline data' do
        json_job = json_response.first

        expect(json_job['pipeline']).not_to be_empty
        expect(json_job['pipeline']['id']).to eq job.pipeline.id
        expect(json_job['pipeline']['ref']).to eq job.pipeline.ref
        expect(json_job['pipeline']['sha']).to eq job.pipeline.sha
        expect(json_job['pipeline']['status']).to eq job.pipeline.status
      end

      it 'avoids N+1 queries', :skip_before_request do
        first_build = create(:ci_build, :trace_artifact, :artifacts, :test_reports, pipeline: pipeline)
        first_build.runner = create(:ci_runner)
        first_build.user = create(:user)
        first_build.save!

        control_count = ActiveRecord::QueryRecorder.new { go }.count

        second_pipeline = create(:ci_empty_pipeline, project: project, sha: project.commit.id, ref: project.default_branch)
        second_build = create(:ci_build, :trace_artifact, :artifacts, :test_reports, pipeline: second_pipeline)
        second_build.runner = create(:ci_runner)
        second_build.user = create(:user)
        second_build.save!

        expect { go }.not_to exceed_query_limit(control_count)
      end

      context 'filter project with one scope element' do
        let(:query) { { 'scope' => 'pending' } }

        it do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Array
        end
      end

      context 'filter project with array of scope elements' do
        let(:query) { { scope: %w(pending running) } }

        it do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Array
        end
      end

      context 'respond 400 when scope contains invalid state' do
        let(:query) { { scope: %w(unknown running) } }

        it { expect(response).to have_gitlab_http_status(:bad_request) }
      end
    end

    context 'unauthorized user' do
      context 'when user is not logged in' do
        let(:api_user) { nil }

        it 'does not return project jobs' do
          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'when user is guest' do
        let(:api_user) { guest }

        it 'does not return project jobs' do
          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    def go
      get api("/projects/#{project.id}/jobs", api_user), params: query
    end
  end

  describe 'GET /projects/:id/jobs/:job_id' do
    before do |example|
      unless example.metadata[:skip_before_request]
        get api("/projects/#{project.id}/jobs/#{job.id}", api_user)
      end
    end

    context 'authorized user' do
      it_behaves_like 'returns common job data' do
        let(:jobx) { job }
      end

      it 'returns specific job data' do
        expect(Time.parse(json_response['finished_at'])).to be_like_time(job.finished_at)
        expect(json_response['duration']).to eq(job.duration)
      end

      it_behaves_like 'a job with artifacts and trace', result_is_array: false do
        let(:api_endpoint) { "/projects/#{project.id}/jobs/#{second_job.id}" }
      end

      it_behaves_like 'returns common pipeline data' do
        let(:jobx) { job }
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not return specific job data' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /projects/:id/jobs/:job_id/artifacts' do
    let!(:job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user) }

    before do
      delete api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
    end

    context 'when user is anonymous' do
      let(:api_user) { nil }

      it 'does not delete artifacts' do
        expect(job.job_artifacts.size).to eq 2
      end

      it 'returns status 401 (unauthorized)' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with developer' do
      it 'does not delete artifacts' do
        expect(job.job_artifacts.size).to eq 2
      end

      it 'returns status 403 (forbidden)' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with authorized user' do
      let(:maintainer) { create(:project_member, :maintainer, project: project).user }
      let!(:api_user) { maintainer }

      it 'deletes artifacts' do
        expect(job.job_artifacts.size).to eq 0
      end

      it 'returns status 204 (no content)' do
        expect(response).to have_gitlab_http_status(:no_content)
      end
    end
  end

  describe 'GET /projects/:id/jobs/:job_id/artifacts/:artifact_path' do
    context 'when job has artifacts' do
      let(:job) { create(:ci_build, :artifacts, pipeline: pipeline) }

      let(:artifact) do
        'other_artifacts_0.1.2/another-subdirectory/banana_sample.gif'
      end

      context 'when user is anonymous' do
        let(:api_user) { nil }

        context 'when project is public' do
          it 'allows to access artifacts' do
            project.update_column(:visibility_level,
                                  Gitlab::VisibilityLevel::PUBLIC)
            project.update_column(:public_builds, true)

            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when project is public with artifacts that are non public' do
          let(:job) { create(:ci_build, :artifacts, :non_public_artifacts, pipeline: pipeline) }

          it 'rejects access to artifacts' do
            project.update_column(:visibility_level,
                                  Gitlab::VisibilityLevel::PUBLIC)
            project.update_column(:public_builds, true)

            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(:forbidden)
          end

          context 'with the non_public_artifacts feature flag disabled' do
            before do
              stub_feature_flags(non_public_artifacts: false)
            end

            it 'allows access to artifacts' do
              project.update_column(:visibility_level,
                                    Gitlab::VisibilityLevel::PUBLIC)
              project.update_column(:public_builds, true)

              get_artifact_file(artifact)

              expect(response).to have_gitlab_http_status(:ok)
            end
          end
        end

        context 'when project is public with builds access disabled' do
          it 'rejects access to artifacts' do
            project.update_column(:visibility_level,
                                  Gitlab::VisibilityLevel::PUBLIC)
            project.update_column(:public_builds, false)

            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when project is private' do
          it 'rejects access and hides existence of artifacts' do
            project.update_column(:visibility_level,
                                  Gitlab::VisibilityLevel::PRIVATE)
            project.update_column(:public_builds, true)

            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when user is authorized' do
        it 'returns a specific artifact file for a valid path' do
          expect(Gitlab::Workhorse)
            .to receive(:send_artifacts_entry)
            .and_call_original

          get_artifact_file(artifact)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers.to_h)
            .to include('Content-Type' => 'application/json',
                        'Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
        end

        context 'when artifacts are locked' do
          it 'allows access to expired artifact' do
            pipeline.artifacts_locked!
            job.update!(artifacts_expire_at: Time.now - 7.days)

            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end

    context 'when job does not have artifacts' do
      it 'does not return job artifact file' do
        get_artifact_file('some/artifact')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def get_artifact_file(artifact_path)
      get api("/projects/#{project.id}/jobs/#{job.id}/" \
              "artifacts/#{artifact_path}", api_user)
    end
  end

  describe 'GET /projects/:id/jobs/:job_id/artifacts' do
    shared_examples 'downloads artifact' do
      let(:download_headers) do
        { 'Content-Transfer-Encoding' => 'binary',
          'Content-Disposition' => %q(attachment; filename="ci_build_artifacts.zip"; filename*=UTF-8''ci_build_artifacts.zip) }
      end

      it 'returns specific job artifacts' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers.to_h).to include(download_headers)
        expect(response.body).to match_file(job.artifacts_file.file.file)
      end
    end

    context 'normal authentication' do
      context 'job with artifacts' do
        context 'when artifacts are stored locally' do
          let(:job) { create(:ci_build, :artifacts, pipeline: pipeline) }

          before do
            get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
          end

          context 'authorized user' do
            it_behaves_like 'downloads artifact'
          end

          context 'unauthorized user' do
            let(:api_user) { nil }

            it 'does not return specific job artifacts' do
              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end

        context 'when artifacts are stored remotely' do
          let(:proxy_download) { false }
          let(:job) { create(:ci_build, pipeline: pipeline) }
          let(:artifact) { create(:ci_job_artifact, :archive, :remote_store, job: job) }

          before do
            stub_artifacts_object_storage(proxy_download: proxy_download)

            artifact
            job.reload

            get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
          end

          context 'when proxy download is enabled' do
            let(:proxy_download) { true }

            it 'responds with the workhorse send-url' do
              expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("send-url:")
            end
          end

          context 'when proxy download is disabled' do
            it 'returns location redirect' do
              expect(response).to have_gitlab_http_status(:found)
            end
          end

          context 'authorized user' do
            it 'returns the file remote URL' do
              expect(response).to redirect_to(artifact.file.url)
            end
          end

          context 'unauthorized user' do
            let(:api_user) { nil }

            it 'does not return specific job artifacts' do
              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end

        context 'when public project guest and artifacts are non public' do
          let(:api_user) { guest }
          let(:job) { create(:ci_build, :artifacts, :non_public_artifacts, pipeline: pipeline) }

          before do
            project.update_column(:visibility_level,
              Gitlab::VisibilityLevel::PUBLIC)
            project.update_column(:public_builds, true)
            get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
          end

          it 'rejects access and hides existence of artifacts' do
            expect(response).to have_gitlab_http_status(:forbidden)
          end

          context 'with the non_public_artifacts feature flag disabled' do
            before do
              stub_feature_flags(non_public_artifacts: false)
              get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
            end

            it 'allows access to artifacts' do
              expect(response).to have_gitlab_http_status(:ok)
            end
          end
        end

        it 'does not return job artifacts if not uploaded' do
          get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET /projects/:id/artifacts/:ref_name/download?job=name' do
    let(:api_user) { reporter }
    let(:job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user) }

    before do
      stub_artifacts_object_storage
      job.success
    end

    def get_for_ref(ref = pipeline.ref, job_name = job.name)
      get api("/projects/#{project.id}/jobs/artifacts/#{ref}/download", api_user), params: { job: job_name }
    end

    context 'when not logged in' do
      let(:api_user) { nil }

      before do
        get_for_ref
      end

      it 'does not find a resource in a private project' do
        expect(project).to be_private
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when logging as guest' do
      let(:api_user) { guest }

      before do
        get_for_ref
      end

      it 'gives 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'non-existing job' do
      shared_examples 'not found' do
        it { expect(response).to have_gitlab_http_status(:not_found) }
      end

      context 'has no such ref' do
        before do
          get_for_ref('TAIL')
        end

        it_behaves_like 'not found'
      end

      context 'has no such job' do
        before do
          get_for_ref(pipeline.ref, 'NOBUILD')
        end

        it_behaves_like 'not found'
      end
    end

    context 'find proper job' do
      let(:job_with_artifacts) { job }

      shared_examples 'a valid file' do
        context 'when artifacts are stored locally', :sidekiq_might_not_need_inline do
          let(:download_headers) do
            { 'Content-Transfer-Encoding' => 'binary',
              'Content-Disposition' =>
              %Q(attachment; filename="#{job_with_artifacts.artifacts_file.filename}"; filename*=UTF-8''#{job.artifacts_file.filename}) }
          end

          it { expect(response).to have_gitlab_http_status(:ok) }
          it { expect(response.headers.to_h).to include(download_headers) }
        end

        context 'when artifacts are stored remotely' do
          let(:job) { create(:ci_build, pipeline: pipeline, user: api_user) }
          let!(:artifact) { create(:ci_job_artifact, :archive, :remote_store, job: job) }

          before do
            job.reload

            get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
          end

          it 'returns location redirect' do
            expect(response).to have_gitlab_http_status(:found)
          end
        end
      end

      context 'with regular branch' do
        before do
          pipeline.reload
          pipeline.update!(ref: 'master',
                          sha: project.commit('master').sha)

          get_for_ref('master')
        end

        it_behaves_like 'a valid file'
      end

      context 'with branch name containing slash' do
        before do
          pipeline.reload
          pipeline.update!(ref: 'improve/awesome', sha: project.commit('improve/awesome').sha)
          get_for_ref('improve/awesome')
        end

        it_behaves_like 'a valid file'
      end

      context 'with job name in a child pipeline' do
        let(:child_pipeline) { create(:ci_pipeline, child_of: pipeline) }
        let!(:child_job) { create(:ci_build, :artifacts, :success, name: 'rspec', pipeline: child_pipeline) }
        let(:job_with_artifacts) { child_job }

        before do
          get_for_ref('master', child_job.name)
        end

        it_behaves_like 'a valid file'
      end
    end
  end

  describe 'GET id/jobs/artifacts/:ref_name/raw/*artifact_path?job=name' do
    context 'when job has artifacts' do
      let(:job) { create(:ci_build, :artifacts, pipeline: pipeline, user: api_user) }
      let(:artifact) { 'other_artifacts_0.1.2/another-subdirectory/banana_sample.gif' }
      let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
      let(:public_builds) { true }

      before do
        stub_artifacts_object_storage
        job.success

        project.update!(visibility_level: visibility_level,
                       public_builds: public_builds)

        get_artifact_file(artifact)
      end

      context 'when user is anonymous' do
        let(:api_user) { nil }

        context 'when project is public' do
          let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
          let(:public_builds) { true }

          it 'allows to access artifacts', :sidekiq_might_not_need_inline do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response.headers.to_h)
              .to include('Content-Type' => 'application/json',
                          'Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
          end
        end

        context 'when project is public with builds access disabled' do
          let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
          let(:public_builds) { false }

          it 'rejects access to artifacts' do
            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response).to have_key('message')
            expect(response.headers.to_h)
              .not_to include('Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
          end
        end

        context 'when project is public with non public artifacts' do
          let(:job) { create(:ci_build, :artifacts, :non_public_artifacts, pipeline: pipeline, user: api_user) }
          let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
          let(:public_builds) { true }

          it 'rejects access and hides existence of artifacts', :sidekiq_might_not_need_inline do
            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response).to have_key('message')
            expect(response.headers.to_h)
              .not_to include('Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
          end

          context 'with the non_public_artifacts feature flag disabled' do
            before do
              stub_feature_flags(non_public_artifacts: false)
            end

            it 'allows access to artifacts', :sidekiq_might_not_need_inline do
              get_artifact_file(artifact)

              expect(response).to have_gitlab_http_status(:ok)
            end
          end
        end

        context 'when project is private' do
          let(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
          let(:public_builds) { true }

          it 'rejects access and hides existence of artifacts' do
            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response).to have_key('message')
            expect(response.headers.to_h)
              .not_to include('Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
          end
        end
      end

      context 'when user is authorized' do
        let(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
        let(:public_builds) { true }

        it 'returns a specific artifact file for a valid path', :sidekiq_might_not_need_inline do
          expect(Gitlab::Workhorse)
            .to receive(:send_artifacts_entry)
                  .and_call_original

          get_artifact_file(artifact)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers.to_h)
            .to include('Content-Type' => 'application/json',
                        'Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
        end
      end

      context 'with branch name containing slash' do
        before do
          pipeline.reload
          pipeline.update!(ref: 'improve/awesome',
                          sha: project.commit('improve/awesome').sha)
        end

        it 'returns a specific artifact file for a valid path', :sidekiq_might_not_need_inline do
          get_artifact_file(artifact, 'improve/awesome')

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers.to_h)
            .to include('Content-Type' => 'application/json',
                        'Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
        end
      end

      context 'non-existing job' do
        shared_examples 'not found' do
          it { expect(response).to have_gitlab_http_status(:not_found) }
        end

        context 'has no such ref' do
          before do
            get_artifact_file('some/artifact', 'wrong-ref')
          end

          it_behaves_like 'not found'
        end

        context 'has no such job' do
          before do
            get_artifact_file('some/artifact', pipeline.ref, 'wrong-job-name')
          end

          it_behaves_like 'not found'
        end
      end
    end

    context 'when job does not have artifacts' do
      let(:job) { create(:ci_build, pipeline: pipeline, user: api_user) }

      it 'does not return job artifact file' do
        get_artifact_file('some/artifact')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def get_artifact_file(artifact_path, ref = pipeline.ref, job_name = job.name)
      get api("/projects/#{project.id}/jobs/artifacts/#{ref}/raw/#{artifact_path}", api_user), params: { job: job_name }
    end
  end

  describe 'GET /projects/:id/jobs/:job_id/trace' do
    before do
      get api("/projects/#{project.id}/jobs/#{job.id}/trace", api_user)
    end

    context 'authorized user' do
      context 'when trace is in ObjectStorage' do
        let!(:job) { create(:ci_build, :trace_artifact, pipeline: pipeline) }
        let(:url) { 'http://object-storage/trace' }
        let(:file_path) { expand_fixture_path('trace/sample_trace') }

        before do
          stub_remote_url_206(url, file_path)
          allow_next_instance_of(JobArtifactUploader) do |instance|
            allow(instance).to receive(:file_storage?) { false }
            allow(instance).to receive(:url) { url }
            allow(instance).to receive(:size) { File.size(file_path) }
          end
        end

        it 'returns specific job trace' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to eq(job.trace.raw)
        end
      end

      context 'when trace is artifact' do
        let(:job) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

        it 'returns specific job trace' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to eq(job.trace.raw)
        end
      end

      context 'when trace is file' do
        let(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }

        it 'returns specific job trace' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to eq(job.trace.raw)
        end
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not return specific job trace' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when ci_debug_trace is set to true' do
      before_all do
        create(:ci_instance_variable, key: 'CI_DEBUG_TRACE', value: true)
      end

      where(:public_builds, :user_project_role, :expected_status) do
        true         | 'developer'     | :ok
        true         | 'guest'         | :forbidden
        false        | 'developer'     | :ok
        false        | 'guest'         | :forbidden
      end

      with_them do
        before do
          project.update!(public_builds: public_builds)
          project.add_role(user, user_project_role)

          get api("/projects/#{project.id}/jobs/#{job.id}/trace", api_user)
        end

        it 'renders trace to authorized users' do
          expect(response).to have_gitlab_http_status(expected_status)
        end
      end
    end
  end

  describe 'POST /projects/:id/jobs/:job_id/cancel' do
    before do
      post api("/projects/#{project.id}/jobs/#{job.id}/cancel", api_user)
    end

    context 'authorized user' do
      context 'user with :update_build persmission' do
        it 'cancels running or pending job' do
          expect(response).to have_gitlab_http_status(:created)
          expect(project.builds.first.status).to eq('success')
        end
      end

      context 'user without :update_build permission' do
        let(:api_user) { reporter }

        it 'does not cancel job' do
          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not cancel job' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /projects/:id/jobs/:job_id/retry' do
    let(:job) { create(:ci_build, :canceled, pipeline: pipeline) }

    before do
      post api("/projects/#{project.id}/jobs/#{job.id}/retry", api_user)
    end

    context 'authorized user' do
      context 'user with :update_build permission' do
        it 'retries non-running job' do
          expect(response).to have_gitlab_http_status(:created)
          expect(project.builds.first.status).to eq('canceled')
          expect(json_response['status']).to eq('pending')
        end
      end

      context 'user without :update_build permission' do
        let(:api_user) { reporter }

        it 'does not retry job' do
          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not retry job' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /projects/:id/jobs/:job_id/erase' do
    let(:role) { :maintainer }

    before do
      project.add_role(user, role)

      post api("/projects/#{project.id}/jobs/#{job.id}/erase", user)
    end

    context 'job is erasable' do
      let(:job) { create(:ci_build, :trace_artifact, :artifacts, :test_reports, :success, project: project, pipeline: pipeline) }

      it 'erases job content' do
        expect(response).to have_gitlab_http_status(:created)
        expect(job.job_artifacts.count).to eq(0)
        expect(job.trace.exist?).to be_falsy
        expect(job.artifacts_file.present?).to be_falsy
        expect(job.artifacts_metadata.present?).to be_falsy
        expect(job.has_job_artifacts?).to be_falsy
      end

      it 'updates job' do
        job.reload

        expect(job.erased_at).to be_truthy
        expect(job.erased_by).to eq(user)
      end
    end

    context 'job is not erasable' do
      let(:job) { create(:ci_build, :trace_live, project: project, pipeline: pipeline) }

      it 'responds with forbidden' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when a developer erases a build' do
      let(:role) { :developer }
      let(:job) { create(:ci_build, :trace_artifact, :artifacts, :success, project: project, pipeline: pipeline, user: owner) }

      context 'when the build was created by the developer' do
        let(:owner) { user }

        it { expect(response).to have_gitlab_http_status(:created) }
      end

      context 'when the build was created by the other' do
        let(:owner) { create(:user) }

        it { expect(response).to have_gitlab_http_status(:forbidden) }
      end
    end
  end

  describe 'POST /projects/:id/jobs/:job_id/artifacts/keep' do
    before do
      post api("/projects/#{project.id}/jobs/#{job.id}/artifacts/keep", user)
    end

    context 'artifacts did not expire' do
      let(:job) do
        create(:ci_build, :trace_artifact, :artifacts, :success,
               project: project, pipeline: pipeline, artifacts_expire_at: Time.now + 7.days)
      end

      it 'keeps artifacts' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(job.reload.artifacts_expire_at).to be_nil
      end
    end

    context 'no artifacts' do
      let(:job) { create(:ci_build, project: project, pipeline: pipeline) }

      it 'responds with not found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /projects/:id/jobs/:job_id/play' do
    before do
      post api("/projects/#{project.id}/jobs/#{job.id}/play", api_user)
    end

    context 'on a playable job' do
      let_it_be(:job) { create(:ci_bridge, :playable, pipeline: pipeline, downstream: project) }

      before do
        project.add_developer(user)
      end

      context 'when user is authorized to trigger a manual action' do
        context 'that is a bridge' do
          it 'plays the job' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['user']['id']).to eq(user.id)
            expect(json_response['id']).to eq(job.id)
            expect(job.reload).to be_pending
          end
        end

        context 'that is a build' do
          let_it_be(:job) { create(:ci_build, :manual, project: project, pipeline: pipeline) }

          it 'plays the job' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['user']['id']).to eq(user.id)
            expect(json_response['id']).to eq(job.id)
            expect(job.reload).to be_pending
          end
        end
      end

      context 'when user is not authorized to trigger a manual action' do
        context 'when user does not have access to the project' do
          let(:api_user) { create(:user) }

          it 'does not trigger a manual action' do
            expect(job.reload).to be_manual
            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when user is not allowed to trigger the manual action' do
          let(:api_user) { reporter }

          it 'does not trigger a manual action' do
            expect(job.reload).to be_manual
            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end
    end

    context 'on a non-playable job' do
      it 'returns a status code 400, Bad Request' do
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response.body).to match("Unplayable Job")
      end
    end
  end
end
