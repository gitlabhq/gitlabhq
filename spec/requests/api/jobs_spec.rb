# frozen_string_literal: true

require 'spec_helper'

describe API::Jobs do
  include HttpIOHelpers

  shared_examples 'a job with artifacts and trace' do |result_is_array: true|
    context 'with artifacts and trace' do
      let!(:second_job) { create(:ci_build, :trace_artifact, :artifacts, :test_reports, pipeline: pipeline) }

      it 'returns artifacts and trace data', :skip_before_request do
        get api(api_endpoint, api_user)
        json_job = result_is_array ? json_response.select { |job| job['id'] == second_job.id }.first : json_response

        expect(json_job['artifacts_file']).not_to be_nil
        expect(json_job['artifacts_file']).not_to be_empty
        expect(json_job['artifacts_file']['filename']).to eq(second_job.artifacts_file.filename)
        expect(json_job['artifacts_file']['size']).to eq(second_job.artifacts_file.size)
        expect(json_job['artifacts']).not_to be_nil
        expect(json_job['artifacts']).to be_an Array
        expect(json_job['artifacts'].size).to eq(second_job.job_artifacts.length)
        json_job['artifacts'].each do |artifact|
          expect(artifact).not_to be_nil
          file_type = Ci::JobArtifact.file_types[artifact['file_type']]
          expect(artifact['size']).to eq(second_job.job_artifacts.where(file_type: file_type).first.size)
          expect(artifact['filename']).to eq(second_job.job_artifacts.where(file_type: file_type).first.filename)
          expect(artifact['file_format']).to eq(second_job.job_artifacts.where(file_type: file_type).first.file_format)
        end
      end
    end
  end

  set(:project) do
    create(:project, :repository, public_builds: false)
  end

  set(:pipeline) do
    create(:ci_empty_pipeline, project: project,
                               sha: project.commit.id,
                               ref: project.default_branch)
  end

  let!(:job) do
    create(:ci_build, :success, pipeline: pipeline,
                                artifacts_expire_at: 1.day.since)
  end

  let(:user) { create(:user) }
  let(:api_user) { user }
  let(:reporter) { create(:project_member, :reporter, project: project).user }
  let(:guest) { create(:project_member, :guest, project: project).user }

  before do
    project.add_developer(user)
  end

  describe 'GET /projects/:id/jobs' do
    let(:query) { Hash.new }

    before do |example|
      unless example.metadata[:skip_before_request]
        get api("/projects/#{project.id}/jobs", api_user), params: query
      end
    end

    context 'authorized user' do
      it 'returns project jobs' do
        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
      end

      it 'returns correct values' do
        expect(json_response).not_to be_empty
        expect(json_response.first['commit']['id']).to eq project.commit.id
        expect(Time.parse(json_response.first['artifacts_expire_at'])).to be_like_time(job.artifacts_expire_at)
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
        first_build.save

        control_count = ActiveRecord::QueryRecorder.new { go }.count

        second_pipeline = create(:ci_empty_pipeline, project: project, sha: project.commit.id, ref: project.default_branch)
        second_build = create(:ci_build, :trace_artifact, :artifacts, :test_reports, pipeline: second_pipeline)
        second_build.runner = create(:ci_runner)
        second_build.user = create(:user)
        second_build.save

        expect { go }.not_to exceed_query_limit(control_count)
      end

      context 'filter project with one scope element' do
        let(:query) { { 'scope' => 'pending' } }

        it do
          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an Array
        end
      end

      context 'filter project with array of scope elements' do
        let(:query) { { scope: %w(pending running) } }

        it do
          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an Array
        end
      end

      context 'respond 400 when scope contains invalid state' do
        let(:query) { { scope: %w(unknown running) } }

        it { expect(response).to have_gitlab_http_status(400) }
      end
    end

    context 'unauthorized user' do
      context 'when user is not logged in' do
        let(:api_user) { nil }

        it 'does not return project jobs' do
          expect(response).to have_gitlab_http_status(401)
        end
      end

      context 'when user is guest' do
        let(:api_user) { guest }

        it 'does not return project jobs' do
          expect(response).to have_gitlab_http_status(403)
        end
      end
    end

    def go
      get api("/projects/#{project.id}/jobs", api_user), params: query
    end
  end

  describe 'GET /projects/:id/pipelines/:pipeline_id/jobs' do
    let(:query) { Hash.new }

    before do |example|
      unless example.metadata[:skip_before_request]
        job
        get api("/projects/#{project.id}/pipelines/#{pipeline.id}/jobs", api_user), params: query
      end
    end

    context 'authorized user' do
      it 'returns pipeline jobs' do
        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
      end

      it 'returns correct values' do
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

      it 'returns pipeline data' do
        json_job = json_response.first

        expect(json_job['pipeline']).not_to be_empty
        expect(json_job['pipeline']['id']).to eq job.pipeline.id
        expect(json_job['pipeline']['ref']).to eq job.pipeline.ref
        expect(json_job['pipeline']['sha']).to eq job.pipeline.sha
        expect(json_job['pipeline']['status']).to eq job.pipeline.status
      end

      context 'filter jobs with one scope element' do
        let(:query) { { 'scope' => 'pending' } }

        it do
          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an Array
        end
      end

      context 'filter jobs with array of scope elements' do
        let(:query) { { scope: %w(pending running) } }

        it do
          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an Array
        end
      end

      context 'respond 400 when scope contains invalid state' do
        let(:query) { { scope: %w(unknown running) } }

        it { expect(response).to have_gitlab_http_status(400) }
      end

      context 'jobs in different pipelines' do
        let!(:pipeline2) { create(:ci_empty_pipeline, project: project) }
        let!(:job2) { create(:ci_build, pipeline: pipeline2) }

        it 'excludes jobs from other pipelines' do
          json_response.each { |job| expect(job['pipeline']['id']).to eq(pipeline.id) }
        end
      end

      it 'avoids N+1 queries' do
        control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          get api("/projects/#{project.id}/pipelines/#{pipeline.id}/jobs", api_user), params: query
        end.count

        3.times { create(:ci_build, :trace_artifact, :artifacts, :test_reports, pipeline: pipeline) }

        expect do
          get api("/projects/#{project.id}/pipelines/#{pipeline.id}/jobs", api_user), params: query
        end.not_to exceed_all_query_limit(control_count)
      end
    end

    context 'unauthorized user' do
      context 'when user is not logged in' do
        let(:api_user) { nil }

        it 'does not return jobs' do
          expect(response).to have_gitlab_http_status(401)
        end
      end

      context 'when user is guest' do
        let(:api_user) { guest }

        it 'does not return jobs' do
          expect(response).to have_gitlab_http_status(403)
        end
      end
    end
  end

  describe 'GET /projects/:id/jobs/:job_id' do
    before do |example|
      unless example.metadata[:skip_before_request]
        get api("/projects/#{project.id}/jobs/#{job.id}", api_user)
      end
    end

    context 'authorized user' do
      it 'returns specific job data' do
        expect(response).to have_gitlab_http_status(200)
        expect(json_response['id']).to eq(job.id)
        expect(json_response['status']).to eq(job.status)
        expect(json_response['stage']).to eq(job.stage)
        expect(json_response['name']).to eq(job.name)
        expect(json_response['ref']).to eq(job.ref)
        expect(json_response['tag']).to eq(job.tag)
        expect(json_response['coverage']).to eq(job.coverage)
        expect(json_response['allow_failure']).to eq(job.allow_failure)
        expect(Time.parse(json_response['created_at'])).to be_like_time(job.created_at)
        expect(Time.parse(json_response['started_at'])).to be_like_time(job.started_at)
        expect(Time.parse(json_response['finished_at'])).to be_like_time(job.finished_at)
        expect(Time.parse(json_response['artifacts_expire_at'])).to be_like_time(job.artifacts_expire_at)
        expect(json_response['artifacts_file']).to be_nil
        expect(json_response['artifacts']).to be_an Array
        expect(json_response['artifacts']).to be_empty
        expect(json_response['duration']).to eq(job.duration)
        expect(json_response['web_url']).to be_present
      end

      it_behaves_like 'a job with artifacts and trace', result_is_array: false do
        let(:api_endpoint) { "/projects/#{project.id}/jobs/#{second_job.id}" }
      end

      it 'returns pipeline data' do
        json_job = json_response

        expect(json_job['pipeline']).not_to be_empty
        expect(json_job['pipeline']['id']).to eq job.pipeline.id
        expect(json_job['pipeline']['ref']).to eq job.pipeline.ref
        expect(json_job['pipeline']['sha']).to eq job.pipeline.sha
        expect(json_job['pipeline']['status']).to eq job.pipeline.status
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not return specific job data' do
        expect(response).to have_gitlab_http_status(401)
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
        expect(response).to have_http_status :unauthorized
      end
    end

    context 'with developer' do
      it 'does not delete artifacts' do
        expect(job.job_artifacts.size).to eq 2
      end

      it 'returns status 403 (forbidden)' do
        expect(response).to have_http_status :forbidden
      end
    end

    context 'with authorized user' do
      let(:maintainer) { create(:project_member, :maintainer, project: project).user }
      let!(:api_user) { maintainer }

      it 'deletes artifacts' do
        expect(job.job_artifacts.size).to eq 0
      end

      it 'returns status 204 (no content)' do
        expect(response).to have_http_status :no_content
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

            expect(response).to have_gitlab_http_status(200)
          end
        end

        context 'when project is public with builds access disabled' do
          it 'rejects access to artifacts' do
            project.update_column(:visibility_level,
                                  Gitlab::VisibilityLevel::PUBLIC)
            project.update_column(:public_builds, false)

            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(403)
          end
        end

        context 'when project is private' do
          it 'rejects access and hides existence of artifacts' do
            project.update_column(:visibility_level,
                                  Gitlab::VisibilityLevel::PRIVATE)
            project.update_column(:public_builds, true)

            get_artifact_file(artifact)

            expect(response).to have_gitlab_http_status(404)
          end
        end
      end

      context 'when user is authorized' do
        it 'returns a specific artifact file for a valid path' do
          expect(Gitlab::Workhorse)
            .to receive(:send_artifacts_entry)
            .and_call_original

          get_artifact_file(artifact)

          expect(response).to have_gitlab_http_status(200)
          expect(response.headers.to_h)
            .to include('Content-Type' => 'application/json',
                        'Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
        end
      end
    end

    context 'when job does not have artifacts' do
      it 'does not return job artifact file' do
        get_artifact_file('some/artifact')

        expect(response).to have_gitlab_http_status(404)
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
        expect(response).to have_gitlab_http_status(200)
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
              expect(response).to have_gitlab_http_status(404)
            end
          end
        end

        context 'when artifacts are stored remotely' do
          let(:proxy_download) { false }

          before do
            stub_artifacts_object_storage(proxy_download: proxy_download)
          end

          let(:job) { create(:ci_build, pipeline: pipeline) }
          let!(:artifact) { create(:ci_job_artifact, :archive, :remote_store, job: job) }

          before do
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
              expect(response).to have_gitlab_http_status(302)
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
              expect(response).to have_gitlab_http_status(404)
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
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when logging as guest' do
      let(:api_user) { guest }

      before do
        get_for_ref
      end

      it 'gives 403' do
        expect(response).to have_gitlab_http_status(403)
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
      shared_examples 'a valid file' do
        context 'when artifacts are stored locally', :sidekiq_might_not_need_inline do
          let(:download_headers) do
            { 'Content-Transfer-Encoding' => 'binary',
              'Content-Disposition' =>
              %Q(attachment; filename="#{job.artifacts_file.filename}"; filename*=UTF-8''#{job.artifacts_file.filename}) }
          end

          it { expect(response).to have_http_status(:ok) }
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
            expect(response).to have_http_status(:found)
          end
        end
      end

      context 'with regular branch' do
        before do
          pipeline.reload
          pipeline.update(ref: 'master',
                          sha: project.commit('master').sha)

          get_for_ref('master')
        end

        it_behaves_like 'a valid file'
      end

      context 'with branch name containing slash' do
        before do
          pipeline.reload
          pipeline.update(ref: 'improve/awesome',
                          sha: project.commit('improve/awesome').sha)
        end

        before do
          get_for_ref('improve/awesome')
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

        project.update(visibility_level: visibility_level,
                       public_builds: public_builds)

        get_artifact_file(artifact)
      end

      context 'when user is anonymous' do
        let(:api_user) { nil }

        context 'when project is public' do
          let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
          let(:public_builds) { true }

          it 'allows to access artifacts', :sidekiq_might_not_need_inline do
            expect(response).to have_gitlab_http_status(200)
            expect(response.headers.to_h)
              .to include('Content-Type' => 'application/json',
                          'Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
          end
        end

        context 'when project is public with builds access disabled' do
          let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }
          let(:public_builds) { false }

          it 'rejects access to artifacts' do
            expect(response).to have_gitlab_http_status(403)
            expect(json_response).to have_key('message')
            expect(response.headers.to_h)
              .not_to include('Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
          end
        end

        context 'when project is private' do
          let(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }
          let(:public_builds) { true }

          it 'rejects access and hides existence of artifacts' do
            expect(response).to have_gitlab_http_status(404)
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

          expect(response).to have_gitlab_http_status(200)
          expect(response.headers.to_h)
            .to include('Content-Type' => 'application/json',
                        'Gitlab-Workhorse-Send-Data' => /artifacts-entry/)
        end
      end

      context 'with branch name containing slash' do
        before do
          pipeline.reload
          pipeline.update(ref: 'improve/awesome',
                          sha: project.commit('improve/awesome').sha)
        end

        it 'returns a specific artifact file for a valid path', :sidekiq_might_not_need_inline do
          get_artifact_file(artifact, 'improve/awesome')

          expect(response).to have_gitlab_http_status(200)
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

        expect(response).to have_gitlab_http_status(404)
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
          expect(response).to have_gitlab_http_status(200)
          expect(response.body).to eq(job.trace.raw)
        end
      end

      context 'when trace is artifact' do
        let(:job) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

        it 'returns specific job trace' do
          expect(response).to have_gitlab_http_status(200)
          expect(response.body).to eq(job.trace.raw)
        end
      end

      context 'when trace is file' do
        let(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }

        it 'returns specific job trace' do
          expect(response).to have_gitlab_http_status(200)
          expect(response.body).to eq(job.trace.raw)
        end
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not return specific job trace' do
        expect(response).to have_gitlab_http_status(401)
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
          expect(response).to have_gitlab_http_status(201)
          expect(project.builds.first.status).to eq('success')
        end
      end

      context 'user without :update_build permission' do
        let(:api_user) { reporter }

        it 'does not cancel job' do
          expect(response).to have_gitlab_http_status(403)
        end
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not cancel job' do
        expect(response).to have_gitlab_http_status(401)
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
          expect(response).to have_gitlab_http_status(201)
          expect(project.builds.first.status).to eq('canceled')
          expect(json_response['status']).to eq('pending')
        end
      end

      context 'user without :update_build permission' do
        let(:api_user) { reporter }

        it 'does not retry job' do
          expect(response).to have_gitlab_http_status(403)
        end
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not retry job' do
        expect(response).to have_gitlab_http_status(401)
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
        expect(response).to have_gitlab_http_status(201)
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
        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when a developer erases a build' do
      let(:role) { :developer }
      let(:job) { create(:ci_build, :trace_artifact, :artifacts, :success, project: project, pipeline: pipeline, user: owner) }

      context 'when the build was created by the developer' do
        let(:owner) { user }

        it { expect(response).to have_gitlab_http_status(201) }
      end

      context 'when the build was created by the other' do
        let(:owner) { create(:user) }

        it { expect(response).to have_gitlab_http_status(403) }
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
        expect(response).to have_gitlab_http_status(200)
        expect(job.reload.artifacts_expire_at).to be_nil
      end
    end

    context 'no artifacts' do
      let(:job) { create(:ci_build, project: project, pipeline: pipeline) }

      it 'responds with not found' do
        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'POST /projects/:id/jobs/:job_id/play' do
    before do
      post api("/projects/#{project.id}/jobs/#{job.id}/play", api_user)
    end

    context 'on an playable job' do
      let(:job) { create(:ci_build, :manual, project: project, pipeline: pipeline) }

      context 'when user is authorized to trigger a manual action' do
        it 'plays the job' do
          expect(response).to have_gitlab_http_status(200)
          expect(json_response['user']['id']).to eq(user.id)
          expect(json_response['id']).to eq(job.id)
          expect(job.reload).to be_pending
        end
      end

      context 'when user is not authorized to trigger a manual action' do
        context 'when user does not have access to the project' do
          let(:api_user) { create(:user) }

          it 'does not trigger a manual action' do
            expect(job.reload).to be_manual
            expect(response).to have_gitlab_http_status(404)
          end
        end

        context 'when user is not allowed to trigger the manual action' do
          let(:api_user) { reporter }

          it 'does not trigger a manual action' do
            expect(job.reload).to be_manual
            expect(response).to have_gitlab_http_status(403)
          end
        end
      end
    end

    context 'on a non-playable job' do
      it 'returns a status code 400, Bad Request' do
        expect(response).to have_gitlab_http_status 400
        expect(response.body).to match("Unplayable Job")
      end
    end
  end
end
