require 'spec_helper'

describe Projects::ArtifactsController do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  let(:pipeline) do
    create(:ci_pipeline,
            project: project,
            sha: project.commit.sha,
            ref: project.default_branch,
            status: 'success')
  end

  let(:build) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }

  describe 'GET /:project/builds/artifacts/:ref_name/browse?job=name' do
    before do
      project.team << [user, :developer]

      login_as(user)
    end

    def path_from_ref(
      ref = pipeline.ref, job = build.name, path = 'browse')
      latest_succeeded_namespace_project_artifacts_path(
        project.namespace,
        project,
        [ref, path].join('/'),
        job: job)
    end

    context 'cannot find the build' do
      shared_examples 'not found' do
        it { expect(response).to have_http_status(:not_found) }
      end

      context 'has no such ref' do
        before do
          get path_from_ref('TAIL', build.name)
        end

        it_behaves_like 'not found'
      end

      context 'has no such build' do
        before do
          get path_from_ref(pipeline.ref, 'NOBUILD')
        end

        it_behaves_like 'not found'
      end

      context 'has no path' do
        before do
          get path_from_ref(pipeline.sha, build.name, '')
        end

        it_behaves_like 'not found'
      end
    end

    context 'found the build and redirect' do
      shared_examples 'redirect to the build' do
        it 'redirects' do
          path = browse_namespace_project_build_artifacts_path(
            project.namespace,
            project,
            build)

          expect(response).to redirect_to(path)
        end
      end

      context 'with regular branch' do
        before do
          pipeline.update(ref: 'master',
                          sha: project.commit('master').sha)

          get path_from_ref('master')
        end

        it_behaves_like 'redirect to the build'
      end

      context 'with branch name containing slash' do
        before do
          pipeline.update(ref: 'improve/awesome',
                          sha: project.commit('improve/awesome').sha)

          get path_from_ref('improve/awesome')
        end

        it_behaves_like 'redirect to the build'
      end

      context 'with branch name and path containing slashes' do
        before do
          pipeline.update(ref: 'improve/awesome',
                          sha: project.commit('improve/awesome').sha)

          get path_from_ref('improve/awesome', build.name, 'file/README.md')
        end

        it 'redirects' do
          path = file_namespace_project_build_artifacts_path(
            project.namespace,
            project,
            build,
            'README.md')

          expect(response).to redirect_to(path)
        end
      end
    end
  end
end
