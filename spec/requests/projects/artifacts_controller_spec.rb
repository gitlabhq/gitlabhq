require 'spec_helper'
require_relative '../shared/artifacts_context'

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
    def path_from_ref(ref = pipeline.sha, build_name = build.name,
                      path = 'browse')
      search_namespace_project_artifacts_path(
        project.namespace,
        project,
        ref,
        build_name,
        path)
    end

    context '404' do
      def verify
        expect(response.status).to eq(404)
      end

      it_behaves_like 'artifacts from ref with 404'

      context 'has no path' do
        before do
          get path_from_ref(pipeline.sha, build.name, '')
        end

        it('gives 404') { verify }
      end
    end

    context '302' do
      def verify
        path = browse_namespace_project_build_artifacts_path(
          project.namespace,
          project,
          build)

        expect(response).to redirect_to(path)
      end

      it_behaves_like 'artifacts from ref with 302'
    end
  end
end
