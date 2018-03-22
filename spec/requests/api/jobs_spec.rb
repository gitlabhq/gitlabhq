require 'spec_helper'

describe API::Jobs do
  include HttpIOHelpers

  set(:project) do
    create(:project, :repository, public_builds: false)
  end

  set(:pipeline) do
    create(:ci_empty_pipeline, project: project,
                               sha: project.commit.id,
                               ref: project.default_branch)
  end

  let!(:job) { create(:ci_build, :success, pipeline: pipeline) }

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
        get api("/projects/#{project.id}/jobs", api_user), query
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
        first_build = create(:ci_build, :artifacts, pipeline: pipeline)
        first_build.runner = create(:ci_runner)
        first_build.user = create(:user)
        first_build.save

        control_count = ActiveRecord::QueryRecorder.new { go }.count

        second_pipeline = create(:ci_empty_pipeline, project: project, sha: project.commit.id, ref: project.default_branch)
        second_build = create(:ci_build, :artifacts, pipeline: second_pipeline)
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
      let(:api_user) { nil }

      it 'does not return project jobs' do
        expect(response).to have_gitlab_http_status(401)
      end
    end

    def go
      get api("/projects/#{project.id}/jobs", api_user), query
    end
  end

  describe 'GET /projects/:id/pipelines/:pipeline_id/jobs' do
    let(:query) { Hash.new }

    before do
      job
      get api("/projects/#{project.id}/pipelines/#{pipeline.id}/jobs", api_user), query
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
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not return jobs' do
        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'GET /projects/:id/jobs/:job_id' do
    before do
      get api("/projects/#{project.id}/jobs/#{job.id}", api_user)
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
        expect(Time.parse(json_response['created_at'])).to be_like_time(job.created_at)
        expect(Time.parse(json_response['started_at'])).to be_like_time(job.started_at)
        expect(Time.parse(json_response['finished_at'])).to be_like_time(job.finished_at)
        expect(json_response['duration']).to eq(job.duration)
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
          expect(response.headers)
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
          'Content-Disposition' => 'attachment; filename=ci_build_artifacts.zip' }
      end

      it 'returns specific job artifacts' do
        expect(response).to have_gitlab_http_status(200)
        expect(response.headers).to include(download_headers)
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
      get api("/projects/#{project.id}/jobs/artifacts/#{ref}/download", api_user), job: job_name
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
        context 'when artifacts are stored locally' do
          let(:download_headers) do
            { 'Content-Transfer-Encoding' => 'binary',
              'Content-Disposition' =>
                "attachment; filename=#{job.artifacts_file.filename}" }
          end

          it { expect(response).to have_http_status(:ok) }
          it { expect(response.headers).to include(download_headers) }
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

  describe 'GET /projects/:id/jobs/:job_id/trace' do
    before do
      get api("/projects/#{project.id}/jobs/#{job.id}/trace", api_user)
    end

    context 'authorized user' do
      context 'when trace is in ObjectStorage' do
        let!(:job) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

        before do
          stub_remote_trace_206
          allow_any_instance_of(JobArtifactUploader).to receive(:file_storage?) { false }
          allow_any_instance_of(JobArtifactUploader).to receive(:url) { remote_trace_url }
          allow_any_instance_of(JobArtifactUploader).to receive(:size) { remote_trace_size }
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
    let(:role) { :master }

    before do
      project.add_role(user, role)

      post api("/projects/#{project.id}/jobs/#{job.id}/erase", user)
    end

    context 'job is erasable' do
      let(:job) { create(:ci_build, :trace_artifact, :artifacts, :success, project: project, pipeline: pipeline) }

      it 'erases job content' do
        expect(response).to have_gitlab_http_status(201)
        expect(job.trace.exist?).to be_falsy
        expect(job.artifacts_file.exists?).to be_falsy
        expect(job.artifacts_metadata.exists?).to be_falsy
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
