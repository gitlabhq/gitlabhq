require 'spec_helper'

describe API::V3::Builds do
  set(:user) { create(:user) }
  let(:api_user) { user }
  set(:project) { create(:project, :repository, creator: user, public_builds: false) }
  let!(:developer) { create(:project_member, :developer, user: user, project: project) }
  let(:reporter) { create(:project_member, :reporter, project: project) }
  let(:guest) { create(:project_member, :guest, project: project) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.id, ref: project.default_branch) }
  let(:build) { create(:ci_build, pipeline: pipeline) }

  describe 'GET /projects/:id/builds ' do
    let(:query) { '' }

    before do |example|
      build

      create(:ci_build, :skipped, pipeline: pipeline)

      unless example.metadata[:skip_before_request]
        get v3_api("/projects/#{project.id}/builds?#{query}", api_user)
      end
    end

    context 'authorized user' do
      it 'returns project builds' do
        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
      end

      it 'returns correct values' do
        expect(json_response).not_to be_empty
        expect(json_response.first['commit']['id']).to eq project.commit.id
      end

      it 'returns pipeline data' do
        json_build = json_response.first
        expect(json_build['pipeline']).not_to be_empty
        expect(json_build['pipeline']['id']).to eq build.pipeline.id
        expect(json_build['pipeline']['ref']).to eq build.pipeline.ref
        expect(json_build['pipeline']['sha']).to eq build.pipeline.sha
        expect(json_build['pipeline']['status']).to eq build.pipeline.status
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
        let(:query) { 'scope=pending' }

        it do
          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an Array
        end
      end

      context 'filter project with scope skipped' do
        let(:query) { 'scope=skipped' }
        let(:json_build) { json_response.first }

        it 'return builds with status skipped' do
          expect(response).to have_gitlab_http_status 200
          expect(json_response).to be_an Array
          expect(json_response.length).to eq 1
          expect(json_build['status']).to eq 'skipped'
        end
      end

      context 'filter project with array of scope elements' do
        let(:query) { 'scope[0]=pending&scope[1]=running' }

        it do
          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an Array
        end
      end

      context 'respond 400 when scope contains invalid state' do
        let(:query) { 'scope[0]=pending&scope[1]=unknown_status' }

        it { expect(response).to have_gitlab_http_status(400) }
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not return project builds' do
        expect(response).to have_gitlab_http_status(401)
      end
    end

    def go
      get v3_api("/projects/#{project.id}/builds?#{query}", api_user)
    end
  end

  describe 'GET /projects/:id/repository/commits/:sha/builds' do
    before do
      build
    end

    context 'when commit does not exist in repository' do
      before do
        get v3_api("/projects/#{project.id}/repository/commits/1a271fd1/builds", api_user)
      end

      it 'responds with 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when commit exists in repository' do
      context 'when user is authorized' do
        context 'when pipeline has jobs' do
          before do
            create(:ci_pipeline, project: project, sha: project.commit.id)
            create(:ci_build, pipeline: pipeline)
            create(:ci_build)

            get v3_api("/projects/#{project.id}/repository/commits/#{project.commit.id}/builds", api_user)
          end

          it 'returns project jobs for specific commit' do
            expect(response).to have_gitlab_http_status(200)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(json_response.size).to eq 2
          end

          it 'returns pipeline data' do
            json_build = json_response.first
            expect(json_build['pipeline']).not_to be_empty
            expect(json_build['pipeline']['id']).to eq build.pipeline.id
            expect(json_build['pipeline']['ref']).to eq build.pipeline.ref
            expect(json_build['pipeline']['sha']).to eq build.pipeline.sha
            expect(json_build['pipeline']['status']).to eq build.pipeline.status
          end
        end

        context 'when pipeline has no jobs' do
          before do
            branch_head = project.commit('feature').id
            get v3_api("/projects/#{project.id}/repository/commits/#{branch_head}/builds", api_user)
          end

          it 'returns an empty array' do
            expect(response).to have_gitlab_http_status(200)
            expect(json_response).to be_an Array
            expect(json_response).to be_empty
          end
        end
      end

      context 'when user is not authorized' do
        before do
          create(:ci_pipeline, project: project, sha: project.commit.id)
          create(:ci_build, pipeline: pipeline)

          get v3_api("/projects/#{project.id}/repository/commits/#{project.commit.id}/builds", nil)
        end

        it 'does not return project jobs' do
          expect(response).to have_gitlab_http_status(401)
          expect(json_response.except('message')).to be_empty
        end
      end
    end
  end

  describe 'GET /projects/:id/builds/:build_id' do
    before do
      get v3_api("/projects/#{project.id}/builds/#{build.id}", api_user)
    end

    context 'authorized user' do
      it 'returns specific job data' do
        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq('test')
      end

      it 'returns pipeline data' do
        json_build = json_response
        expect(json_build['pipeline']).not_to be_empty
        expect(json_build['pipeline']['id']).to eq build.pipeline.id
        expect(json_build['pipeline']['ref']).to eq build.pipeline.ref
        expect(json_build['pipeline']['sha']).to eq build.pipeline.sha
        expect(json_build['pipeline']['status']).to eq build.pipeline.status
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not return specific job data' do
        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'GET /projects/:id/builds/:build_id/artifacts' do
    before do
      stub_artifacts_object_storage
      get v3_api("/projects/#{project.id}/builds/#{build.id}/artifacts", api_user)
    end

    context 'job with artifacts' do
      context 'when artifacts are stored locally' do
        let(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

        context 'authorized user' do
          let(:download_headers) do
            { 'Content-Transfer-Encoding' => 'binary',
              'Content-Disposition' => 'attachment; filename=ci_build_artifacts.zip' }
          end

          it 'returns specific job artifacts' do
            expect(response).to have_http_status(200)
            expect(response.headers.to_h).to include(download_headers)
            expect(response.body).to match_file(build.artifacts_file.file.file)
          end
        end
      end

      context 'when artifacts are stored remotely' do
        let(:build) { create(:ci_build, pipeline: pipeline) }
        let!(:artifact) { create(:ci_job_artifact, :archive, :remote_store, job: build) }

        it 'returns location redirect' do
          get v3_api("/projects/#{project.id}/builds/#{build.id}/artifacts", api_user)

          expect(response).to have_gitlab_http_status(302)
        end
      end

      context 'unauthorized user' do
        let(:api_user) { nil }

        it 'does not return specific job artifacts' do
          expect(response).to have_gitlab_http_status(401)
        end
      end
    end

    it 'does not return job artifacts if not uploaded' do
      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'GET /projects/:id/artifacts/:ref_name/download?job=name' do
    let(:api_user) { reporter.user }
    let(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

    before do
      stub_artifacts_object_storage
      build.success
    end

    def path_for_ref(ref = pipeline.ref, job = build.name)
      v3_api("/projects/#{project.id}/builds/artifacts/#{ref}/download?job=#{job}", api_user)
    end

    context 'when not logged in' do
      let(:api_user) { nil }

      before do
        get path_for_ref
      end

      it 'gives 401' do
        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when logging as guest' do
      let(:api_user) { guest.user }

      before do
        get path_for_ref
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
          get path_for_ref('TAIL', build.name)
        end

        it_behaves_like 'not found'
      end

      context 'has no such job' do
        before do
          get path_for_ref(pipeline.ref, 'NOBUILD')
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
                "attachment; filename=#{build.artifacts_file.filename}" }
          end

          it { expect(response).to have_http_status(200) }
          it { expect(response.headers.to_h).to include(download_headers) }
        end

        context 'when artifacts are stored remotely' do
          let(:build) { create(:ci_build, pipeline: pipeline) }
          let!(:artifact) { create(:ci_job_artifact, :archive, :remote_store, job: build) }

          before do
            build.reload

            get v3_api("/projects/#{project.id}/builds/#{build.id}/artifacts", api_user)
          end

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

          get path_for_ref('master')
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
          get path_for_ref('improve/awesome')
        end

        it_behaves_like 'a valid file'
      end
    end
  end

  describe 'GET /projects/:id/builds/:build_id/trace' do
    let(:build) { create(:ci_build, :trace_live, pipeline: pipeline) }

    before do
      get v3_api("/projects/#{project.id}/builds/#{build.id}/trace", api_user)
    end

    context 'authorized user' do
      it 'returns specific job trace' do
        expect(response).to have_gitlab_http_status(200)
        expect(response.body).to eq(build.trace.raw)
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not return specific job trace' do
        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'POST /projects/:id/builds/:build_id/cancel' do
    before do
      post v3_api("/projects/#{project.id}/builds/#{build.id}/cancel", api_user)
    end

    context 'authorized user' do
      context 'user with :update_build persmission' do
        it 'cancels running or pending job' do
          expect(response).to have_gitlab_http_status(201)
          expect(project.builds.first.status).to eq('canceled')
        end
      end

      context 'user without :update_build permission' do
        let(:api_user) { reporter.user }

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

  describe 'POST /projects/:id/builds/:build_id/retry' do
    let(:build) { create(:ci_build, :canceled, pipeline: pipeline) }

    before do
      post v3_api("/projects/#{project.id}/builds/#{build.id}/retry", api_user)
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
        let(:api_user) { reporter.user }

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

  describe 'POST /projects/:id/builds/:build_id/erase' do
    before do
      project.add_master(user)

      post v3_api("/projects/#{project.id}/builds/#{build.id}/erase", user)
    end

    context 'job is erasable' do
      let(:build) { create(:ci_build, :trace_artifact, :artifacts, :success, project: project, pipeline: pipeline) }

      it 'erases job content' do
        expect(response.status).to eq 201
        expect(build).not_to have_trace
        expect(build.artifacts_file.exists?).to be_falsy
        expect(build.artifacts_metadata.exists?).to be_falsy
      end

      it 'updates job' do
        expect(build.reload.erased_at).to be_truthy
        expect(build.reload.erased_by).to eq user
      end
    end

    context 'job is not erasable' do
      let(:build) { create(:ci_build, :trace_live, project: project, pipeline: pipeline) }

      it 'responds with forbidden' do
        expect(response.status).to eq 403
      end
    end
  end

  describe 'POST /projects/:id/builds/:build_id/artifacts/keep' do
    before do
      post v3_api("/projects/#{project.id}/builds/#{build.id}/artifacts/keep", user)
    end

    context 'artifacts did not expire' do
      let(:build) do
        create(:ci_build, :trace_artifact, :artifacts, :success,
               project: project, pipeline: pipeline, artifacts_expire_at: Time.now + 7.days)
      end

      it 'keeps artifacts' do
        expect(response.status).to eq 200
        expect(build.reload.artifacts_expire_at).to be_nil
      end
    end

    context 'no artifacts' do
      let(:build) { create(:ci_build, project: project, pipeline: pipeline) }

      it 'responds with not found' do
        expect(response.status).to eq 404
      end
    end
  end

  describe 'POST /projects/:id/builds/:build_id/play' do
    before do
      post v3_api("/projects/#{project.id}/builds/#{build.id}/play", user)
    end

    context 'on an playable job' do
      let(:build) { create(:ci_build, :manual, project: project, pipeline: pipeline) }

      it 'plays the job' do
        expect(response).to have_gitlab_http_status 200
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['id']).to eq(build.id)
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
