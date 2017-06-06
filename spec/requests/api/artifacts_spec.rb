require 'spec_helper'

describe API::Artifacts, :api do
  set(:project) { create(:project, :repository, public_builds: false) }

  set(:pipeline) do
    create(:ci_empty_pipeline, project: project,
           sha: project.commit.id,
           ref: project.default_branch)
  end

  set(:user) { create(:user) }

  let(:reporter) { create(:project_member, :reporter, project: project).user }
  let(:guest) { create(:project_member, :guest, project: project).user }


  before do
    project.add_developer(user)
  end

  describe 'GET /projects/:id/jobs/:job_id/artifacts' do
    let(:build) do
      create(:ci_build, 
             :artifacts, 
             :running, 
             pipeline: pipeline, 
             project: project,
             user: user)
    end

    context 'job with artifacts' do
      let(:download_headers) do
        { 'Content-Transfer-Encoding' => 'binary',
          'Content-Disposition' => 'attachment; filename=ci_build_artifacts.zip' }
      end

      context 'authorized user' do
        before do
          get api("/projects/#{project.id}/jobs/#{build.id}/artifacts", user)
        end

        it 'returns specific job artifacts' do
          expect(response).to have_http_status(200)
          expect(response.headers).to include(download_headers)
          expect(response.body).to match_file(build.artifacts_file.file.file)
        end
      end

      context 'authenticating with a gitlab-ci token' do
        it 'returns the specific job artifacts' do
          get api("/projects/#{project.id}/jobs/#{build.id}/artifacts"), gitlab_ci_token: build.token

          expect(response).to have_http_status(200)
          expect(response.headers).to include(download_headers)
          expect(response.body).to match_file(build.artifacts_file.file.file)
        end
      end

      context 'unauthorized user' do
        it 'does not return specific job artifacts' do
          get api("/projects/#{project.id}/jobs/#{build.id}/artifacts")

          expect(response).to have_http_status(404)
        end
      end
    end
  end

  describe 'GET /projects/:id/artifacts/:ref_name/download?job=name' do
    let(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

    before do
      build.success
    end

    def get_for_ref(ref = pipeline.ref, job = build.name)
      get api("/projects/#{project.id}/jobs/artifacts/#{ref}/download", user), job: job
    end

    context 'when not logged in' do
      let(:user) { nil }

      before do
        get_for_ref
      end

      it 'gives 401' do
        expect(response).to have_http_status(401)
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
        let(:download_headers) do
          { 'Content-Transfer-Encoding' => 'binary',
            'Content-Disposition' =>
          "attachment; filename=#{build.artifacts_file.filename}" }
        end

        it { expect(response).to have_http_status(200) }
        it { expect(response.headers).to include(download_headers) }
      end

      context 'with regular branch' do
        before do
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

  describe 'POST /projects/:id/jobs/:build_id/artifacts/keep' do
    before do
      post api("/projects/#{project.id}/jobs/#{build.id}/artifacts/keep", user)
    end

    context 'artifacts did not expire' do
      let(:build) do
        create(:ci_build, :trace, :artifacts, :success,
               project: project, pipeline: pipeline, artifacts_expire_at: Time.now + 7.days)
      end

      it 'keeps artifacts' do
        expect(response).to have_http_status(200)
        expect(build.reload.artifacts_expire_at).to be_nil
      end
    end

    context 'no artifacts' do
      let(:build) { create(:ci_build, project: project, pipeline: pipeline) }

      it 'responds with not found' do
        expect(response).to have_http_status(404)
      end
    end
  end
end

