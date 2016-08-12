require 'spec_helper'

describe API::API, api: true do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:api_user) { user }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:developer) { create(:project_member, :developer, user: user, project: project) }
  let(:reporter) { create(:project_member, :reporter, project: project) }
  let(:guest) { create(:project_member, :guest, project: project) }
  let!(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.id, ref: project.default_branch) }
  let!(:build) { create(:ci_build, pipeline: pipeline) }

  describe 'GET /projects/:id/builds ' do
    let(:query) { '' }

    before { get api("/projects/#{project.id}/builds?#{query}", api_user) }

    context 'authorized user' do
      it 'returns project builds' do
        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
      end

      it 'returns correct values' do
        expect(json_response).not_to be_empty
        expect(json_response.first['commit']['id']).to eq project.commit.id
      end

      context 'filter project with one scope element' do
        let(:query) { 'scope=pending' }

        it do
          expect(response).to have_http_status(200)
          expect(json_response).to be_an Array
        end
      end

      context 'filter project with array of scope elements' do
        let(:query) { 'scope[0]=pending&scope[1]=running' }

        it do
          expect(response).to have_http_status(200)
          expect(json_response).to be_an Array
        end
      end

      context 'respond 400 when scope contains invalid state' do
        let(:query) { 'scope[0]=pending&scope[1]=unknown_status' }

        it { expect(response).to have_http_status(400) }
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not return project builds' do
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'GET /projects/:id/repository/commits/:sha/builds' do
    context 'when commit does not exist in repository' do
      before do
        get api("/projects/#{project.id}/repository/commits/1a271fd1/builds", api_user)
      end

      it 'responds with 404' do
        expect(response).to have_http_status(404)
      end
    end

    context 'when commit exists in repository' do
      context 'when user is authorized' do
        context 'when pipeline has builds' do
          before do
            create(:ci_pipeline, project: project, sha: project.commit.id)
            create(:ci_build, pipeline: pipeline)
            create(:ci_build)

            get api("/projects/#{project.id}/repository/commits/#{project.commit.id}/builds", api_user)
          end

          it 'returns project builds for specific commit' do
            expect(response).to have_http_status(200)
            expect(json_response).to be_an Array
            expect(json_response.size).to eq 2
          end
        end

        context 'when pipeline has no builds' do
          before do
            branch_head = project.commit('feature').id
            get api("/projects/#{project.id}/repository/commits/#{branch_head}/builds", api_user)
          end

          it 'returns an empty array' do
            expect(response).to have_http_status(200)
            expect(json_response).to be_an Array
            expect(json_response).to be_empty
          end
        end
      end

      context 'when user is not authorized' do
        before do
          create(:ci_pipeline, project: project, sha: project.commit.id)
          create(:ci_build, pipeline: pipeline)

          get api("/projects/#{project.id}/repository/commits/#{project.commit.id}/builds", nil)
        end

        it 'does not return project builds' do
          expect(response).to have_http_status(401)
          expect(json_response.except('message')).to be_empty
        end
      end
    end
  end

  describe 'GET /projects/:id/builds/:build_id' do
    before { get api("/projects/#{project.id}/builds/#{build.id}", api_user) }

    context 'authorized user' do
      it 'returns specific build data' do
        expect(response).to have_http_status(200)
        expect(json_response['name']).to eq('test')
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not return specific build data' do
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'GET /projects/:id/builds/:build_id/artifacts' do
    before { get api("/projects/#{project.id}/builds/#{build.id}/artifacts", api_user) }

    context 'build with artifacts' do
      let(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

      context 'authorized user' do
        let(:download_headers) do
          { 'Content-Transfer-Encoding' => 'binary',
            'Content-Disposition' => 'attachment; filename=ci_build_artifacts.zip' }
        end

        it 'returns specific build artifacts' do
          expect(response).to have_http_status(200)
          expect(response.headers).to include(download_headers)
        end
      end

      context 'unauthorized user' do
        let(:api_user) { nil }

        it 'does not return specific build artifacts' do
          expect(response).to have_http_status(401)
        end
      end
    end

    it 'does not return build artifacts if not uploaded' do
      expect(response).to have_http_status(404)
    end
  end

  describe 'GET /projects/:id/artifacts/:ref_name/download?job=name' do
    let(:api_user) { reporter.user }
    let(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

    before do
      build.success
    end

    def path_for_ref(ref = pipeline.ref, job = build.name)
      api("/projects/#{project.id}/builds/artifacts/#{ref}/download?job=#{job}", api_user)
    end

    context 'when not logged in' do
      let(:api_user) { nil }

      before do
        get path_for_ref
      end

      it 'gives 401' do
        expect(response).to have_http_status(401)
      end
    end

    context 'when logging as guest' do
      let(:api_user) { guest.user }

      before do
        get path_for_ref
      end

      it 'gives 403' do
        expect(response).to have_http_status(403)
      end
    end

    context 'non-existing build' do
      shared_examples 'not found' do
        it { expect(response).to have_http_status(:not_found) }
      end

      context 'has no such ref' do
        before do
          get path_for_ref('TAIL', build.name)
        end

        it_behaves_like 'not found'
      end

      context 'has no such build' do
        before do
          get path_for_ref(pipeline.ref, 'NOBUILD')
        end

        it_behaves_like 'not found'
      end
    end

    context 'find proper build' do
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

          get path_for_ref('master')
        end

        it_behaves_like 'a valid file'
      end

      context 'with branch name containing slash' do
        before do
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
    let(:build) { create(:ci_build, :trace, pipeline: pipeline) }

    before do
      get api("/projects/#{project.id}/builds/#{build.id}/trace", api_user)
    end

    context 'authorized user' do
      it 'returns specific build trace' do
        expect(response).to have_http_status(200)
        expect(response.body).to eq(build.trace)
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not return specific build trace' do
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'POST /projects/:id/builds/:build_id/cancel' do
    before { post api("/projects/#{project.id}/builds/#{build.id}/cancel", api_user) }

    context 'authorized user' do
      context 'user with :update_build persmission' do
        it 'cancels running or pending build' do
          expect(response).to have_http_status(201)
          expect(project.builds.first.status).to eq('canceled')
        end
      end

      context 'user without :update_build permission' do
        let(:api_user) { reporter.user }

        it 'does not cancel build' do
          expect(response).to have_http_status(403)
        end
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not cancel build' do
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'POST /projects/:id/builds/:build_id/retry' do
    let(:build) { create(:ci_build, :canceled, pipeline: pipeline) }

    before { post api("/projects/#{project.id}/builds/#{build.id}/retry", api_user) }

    context 'authorized user' do
      context 'user with :update_build permission' do
        it 'retries non-running build' do
          expect(response).to have_http_status(201)
          expect(project.builds.first.status).to eq('canceled')
          expect(json_response['status']).to eq('pending')
        end
      end

      context 'user without :update_build permission' do
        let(:api_user) { reporter.user }

        it 'does not retry build' do
          expect(response).to have_http_status(403)
        end
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'does not retry build' do
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'POST /projects/:id/builds/:build_id/erase' do
    before do
      post api("/projects/#{project.id}/builds/#{build.id}/erase", user)
    end

    context 'build is erasable' do
      let(:build) { create(:ci_build, :trace, :artifacts, :success, project: project, pipeline: pipeline) }

      it 'erases build content' do
        expect(response.status).to eq 201
        expect(build.trace).to be_empty
        expect(build.artifacts_file.exists?).to be_falsy
        expect(build.artifacts_metadata.exists?).to be_falsy
      end

      it 'updates build' do
        expect(build.reload.erased_at).to be_truthy
        expect(build.reload.erased_by).to eq user
      end
    end

    context 'build is not erasable' do
      let(:build) { create(:ci_build, :trace, project: project, pipeline: pipeline) }

      it 'responds with forbidden' do
        expect(response.status).to eq 403
      end
    end
  end

  describe 'POST /projects/:id/builds/:build_id/artifacts/keep' do
    before do
      post api("/projects/#{project.id}/builds/#{build.id}/artifacts/keep", user)
    end

    context 'artifacts did not expire' do
      let(:build) do
        create(:ci_build, :trace, :artifacts, :success,
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
end
