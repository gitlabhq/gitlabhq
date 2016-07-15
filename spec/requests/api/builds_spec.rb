require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:api_user) { user }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:developer) { create(:project_member, :developer, user: user, project: project) }
  let!(:reporter) { create(:project_member, :reporter, user: user2, project: project) }
  let!(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit.id) }
  let!(:build) { create(:ci_build, pipeline: pipeline) }

  describe 'GET /projects/:id/builds ' do
    let(:query) { '' }

    before { get api("/projects/#{project.id}/builds?#{query}", api_user) }

    context 'authorized user' do
      it 'should return project builds' do
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

      it 'should not return project builds' do
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

          it 'should return project builds for specific commit' do
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

        it 'should not return project builds' do
          expect(response).to have_http_status(401)
          expect(json_response.except('message')).to be_empty
        end
      end
    end
  end

  describe 'GET /projects/:id/builds/:build_id' do
    before { get api("/projects/#{project.id}/builds/#{build.id}", api_user) }

    context 'authorized user' do
      it 'should return specific build data' do
        expect(response).to have_http_status(200)
        expect(json_response['name']).to eq('test')
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'should not return specific build data' do
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

        it 'should return specific build artifacts' do
          expect(response).to have_http_status(200)
          expect(response.headers).to include(download_headers)
        end
      end

      context 'unauthorized user' do
        let(:api_user) { nil }

        it 'should not return specific build artifacts' do
          expect(response).to have_http_status(401)
        end
      end
    end

    it 'should not return build artifacts if not uploaded' do
      expect(response).to have_http_status(404)
    end
  end

  describe 'GET /projects/:id/builds/:build_id/trace' do
    let(:build) { create(:ci_build, :trace, pipeline: pipeline) }

    before { get api("/projects/#{project.id}/builds/#{build.id}/trace", api_user) }

    context 'authorized user' do
      it 'should return specific build trace' do
        expect(response).to have_http_status(200)
        expect(response.body).to eq(build.trace)
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'should not return specific build trace' do
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'POST /projects/:id/builds/:build_id/cancel' do
    before { post api("/projects/#{project.id}/builds/#{build.id}/cancel", api_user) }

    context 'authorized user' do
      context 'user with :update_build persmission' do
        it 'should cancel running or pending build' do
          expect(response).to have_http_status(201)
          expect(project.builds.first.status).to eq('canceled')
        end
      end

      context 'user without :update_build permission' do
        let(:api_user) { user2 }

        it 'should not cancel build' do
          expect(response).to have_http_status(403)
        end
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'should not cancel build' do
        expect(response).to have_http_status(401)
      end
    end
  end

  describe 'POST /projects/:id/builds/:build_id/retry' do
    let(:build) { create(:ci_build, :canceled, pipeline: pipeline) }

    before { post api("/projects/#{project.id}/builds/#{build.id}/retry", api_user) }

    context 'authorized user' do
      context 'user with :update_build permission' do
        it 'should retry non-running build' do
          expect(response).to have_http_status(201)
          expect(project.builds.first.status).to eq('canceled')
          expect(json_response['status']).to eq('pending')
        end
      end

      context 'user without :update_build permission' do
        let(:api_user) { user2 }

        it 'should not retry build' do
          expect(response).to have_http_status(403)
        end
      end
    end

    context 'unauthorized user' do
      let(:api_user) { nil }

      it 'should not retry build' do
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

      it 'should erase build content' do
        expect(response.status).to eq 201
        expect(build.trace).to be_empty
        expect(build.artifacts_file.exists?).to be_falsy
        expect(build.artifacts_metadata.exists?).to be_falsy
      end

      it 'should update build' do
        expect(build.reload.erased_at).to be_truthy
        expect(build.reload.erased_by).to eq user
      end
    end

    context 'build is not erasable' do
      let(:build) { create(:ci_build, :trace, project: project, pipeline: pipeline) }

      it 'should respond with forbidden' do
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
