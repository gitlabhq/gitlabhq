require 'spec_helper'

describe API::Jobs do
  let(:project) do
    create(:project, :repository, public_builds: false)
  end

  let(:pipeline) do
    create(:ci_empty_pipeline, project: project,
                               sha: project.commit.id,
                               ref: project.default_branch)
  end

  let(:job) { create(:ci_build, pipeline: pipeline) }

  let(:user) { create(:user) }
  let(:api_user) { user }
  let(:reporter) { create(:project_member, :reporter, project: project).user }
  let(:guest) { create(:project_member, :guest, project: project).user }

  before do
    project.add_developer(user)
  end

  describe 'GET /projects/:id/jobs' do
    let(:query) { Hash.new }

    before do
      job
      get api("/projects/#{project.id}/jobs", api_user), query
    end

    context 'authorized user' do
      it 'returns project jobs' do
        expect(response).to have_http_status(200)
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

      context 'filter project with one scope element' do
        let(:query) { { 'scope' => 'pending' } }

        it do
          expect(response).to have_http_status(200)
          expect(json_response).to be_an Array
        end
      end

      context 'filter project with array of scope elements' do
        let(:query) { { scope: %w(pending running) } }

        it do
          expect(response).to have_http_status(200)
          expect(json_response).to be_an Array
        end
      end

      context 'respond 400 when scope contains invalid state' do
        let(:query) { { scope: %w(unknown running) } }

        it { expect(response).to have_http_status(400) }
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not return project jobs' do
        expect(response).to have_http_status(401)
      end
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
        expect(response).to have_http_status(200)
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
          expect(response).to have_http_status(200)
          expect(json_response).to be_an Array
        end
      end

      context 'filter jobs with array of scope elements' do
        let(:query) { { scope: %w(pending running) } }

        it do
          expect(response).to have_http_status(200)
          expect(json_response).to be_an Array
        end
      end

      context 'respond 400 when scope contains invalid state' do
        let(:query) { { scope: %w(unknown running) } }

        it { expect(response).to have_http_status(400) }
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
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'GET /projects/:id/jobs/:job_id' do
    before do
      get api("/projects/#{project.id}/jobs/#{job.id}", api_user)
    end

    context 'authorized user' do
      it 'returns specific job data' do
        expect(response).to have_http_status(200)
        expect(json_response['name']).to eq('test')
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
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'GET /projects/:id/jobs/:job_id/artifacts' do
    before do
      stub_artifacts_object_storage
      job
      get api("/projects/#{project.id}/jobs/#{job.id}/artifacts", api_user)
    end

    context 'job with artifacts' do
      context 'when artifacts are stored locally' do
        let(:job) { create(:ci_build, :artifacts, pipeline: pipeline) }

        context 'authorized user' do
          let(:download_headers) do
            { 'Content-Transfer-Encoding' => 'binary',
              'Content-Disposition' => 'attachment; filename=ci_build_artifacts.zip' }
          end

          it 'returns specific job artifacts' do
            expect(response).to have_http_status(200)
            expect(response.headers).to include(download_headers)
            expect(response.body).to match_file(job.artifacts_file.file.file)
          end
        end

        context 'unauthorized user' do
          let(:api_user) { nil }

          it 'does not return specific job artifacts' do
            expect(response).to have_http_status(401)
          end
        end
      end

      context 'when artifacts are stored remotely' do
        let(:job) { create(:ci_build, :artifacts, :remote_store, pipeline: pipeline) }

        it 'returns location redirect' do
          expect(response).to have_http_status(302)
        end
      end
    end

    it 'does not return job artifacts if not uploaded' do
      expect(response).to have_http_status(404)
    end
  end

  describe 'GET /projects/:id/artifacts/:ref_name/download?job=name' do
    let(:api_user) { reporter }
    let(:job) { create(:ci_build, :artifacts, pipeline: pipeline) }

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

      it 'gives 401' do
        expect(response).to have_http_status(401)
      end
    end

    context 'when logging as guest' do
      let(:api_user) { guest }

      before do
        get_for_ref
      end

      it 'gives 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'non-existing job' do
      shared_examples 'not found' do
        it { expect(response).to have_http_status(:not_found) }
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

          it { expect(response).to have_http_status(200) }
          it { expect(response.headers).to include(download_headers) }
        end

        context 'when artifacts are stored remotely' do
          let(:job) { create(:ci_build, :artifacts, :remote_store, pipeline: pipeline) }

          it 'returns location redirect' do
            expect(response).to have_http_status(302)
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
    let(:job) { create(:ci_build, :trace, pipeline: pipeline) }

    before do
      get api("/projects/#{project.id}/jobs/#{job.id}/trace", api_user)
    end

    context 'authorized user' do
      it 'returns specific job trace' do
        expect(response).to have_http_status(200)
        expect(response.body).to eq(job.trace.raw)
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not return specific job trace' do
        expect(response).to have_http_status(401)
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
          expect(response).to have_http_status(201)
          expect(project.builds.first.status).to eq('canceled')
        end
      end

      context 'user without :update_build permission' do
        let(:api_user) { reporter }

        it 'does not cancel job' do
          expect(response).to have_http_status(403)
        end
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not cancel job' do
        expect(response).to have_http_status(401)
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
          expect(response).to have_http_status(201)
          expect(project.builds.first.status).to eq('canceled')
          expect(json_response['status']).to eq('pending')
        end
      end

      context 'user without :update_build permission' do
        let(:api_user) { reporter }

        it 'does not retry job' do
          expect(response).to have_http_status(403)
        end
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not retry job' do
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'POST /projects/:id/jobs/:job_id/erase' do
    before do
      post api("/projects/#{project.id}/jobs/#{job.id}/erase", user)
    end

    context 'job is erasable' do
      let(:job) { create(:ci_build, :trace, :artifacts, :success, project: project, pipeline: pipeline) }

      it 'erases job content' do
        expect(response).to have_http_status(201)
        expect(job).not_to have_trace
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
      let(:job) { create(:ci_build, :trace, project: project, pipeline: pipeline) }

      it 'responds with forbidden' do
        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'POST /projects/:id/jobs/:job_id/artifacts/keep' do
    before do
      post api("/projects/#{project.id}/jobs/#{job.id}/artifacts/keep", user)
    end

    context 'artifacts did not expire' do
      let(:job) do
        create(:ci_build, :trace, :artifacts, :success,
               project: project, pipeline: pipeline, artifacts_expire_at: Time.now + 7.days)
      end

      it 'keeps artifacts' do
        expect(response).to have_http_status(200)
        expect(job.reload.artifacts_expire_at).to be_nil
      end
    end

    context 'no artifacts' do
      let(:job) { create(:ci_build, project: project, pipeline: pipeline) }

      it 'responds with not found' do
        expect(response).to have_http_status(404)
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
          expect(response).to have_http_status(200)
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
            expect(response).to have_http_status(404)
          end
        end

        context 'when user is not allowed to trigger the manual action' do
          let(:api_user) { reporter }

          it 'does not trigger a manual action' do
            expect(job.reload).to be_manual
            expect(response).to have_http_status(403)
          end
        end
      end
    end

    context 'on a non-playable job' do
      it 'returns a status code 400, Bad Request' do
        expect(response).to have_http_status 400
        expect(response.body).to match("Unplayable Job")
      end
    end
  end
end
