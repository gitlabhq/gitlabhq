require 'spec_helper'

describe Projects::ArtifactsController do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) do
    create(:ci_pipeline, project: project, sha: project.commit('fix').sha)
  end
  let(:build) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }

  before do
    login_as(user)
    project.team << [user, :developer]
  end

  describe 'GET /:project/artifacts/:ref/:build_name/browse' do
    context '404' do
      it 'has no such ref' do
        get search_namespace_project_artifacts_path(
          project.namespace,
          project,
          'TAIL',
          build.name,
          'browse')

        expect(response.status).to eq(404)
      end

      it 'has no such build' do
        get search_namespace_project_artifacts_path(
          project.namespace,
          project,
          pipeline.sha,
          'NOBUILD',
          'browse')

        expect(response.status).to eq(404)
      end

      it 'has no path' do
        get search_namespace_project_artifacts_path(
          project.namespace,
          project,
          pipeline.sha,
          build.name,
          '')

        expect(response.status).to eq(404)
      end
    end

    context '302' do
      def path_from_sha
        search_namespace_project_artifacts_path(
          project.namespace,
          project,
          pipeline.sha,
          build.name,
          'browse')
      end

      shared_examples 'redirect to the build' do
        it 'redirects' do
          path = browse_namespace_project_build_artifacts_path(
            project.namespace,
            project,
            build)

          expect(response).to redirect_to(path)
        end
      end

      context 'with sha' do
        before do
          get path_from_sha
        end

        it_behaves_like 'redirect to the build'
      end

      context 'with regular branch' do
        before do
          pipeline.update(sha: project.commit('master').sha)
        end

        before do
          get search_namespace_project_artifacts_path(
            project.namespace,
            project,
            'master',
            build.name,
            'browse')
        end

        it_behaves_like 'redirect to the build'
      end

      context 'with branch name containing slash' do
        before do
          pipeline.update(sha: project.commit('improve/awesome').sha)
        end

        before do
          get search_namespace_project_artifacts_path(
            project.namespace,
            project,
            'improve/awesome',
            build.name,
            'browse')
        end

        it_behaves_like 'redirect to the build'
      end

      context 'with latest build' do
        before do
          3.times do # creating some old builds
            create(:ci_build, :success, :artifacts, pipeline: pipeline)
          end
        end

        before do
          get path_from_sha
        end

        it_behaves_like 'redirect to the build'
      end

      context 'with success build' do
        before do
          build # make sure build was old, but still the latest success one
          create(:ci_build, :pending, :artifacts, pipeline: pipeline)
        end

        before do
          get path_from_sha
        end

        it_behaves_like 'redirect to the build'
      end
    end
  end
end
