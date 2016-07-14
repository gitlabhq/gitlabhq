require 'spec_helper'
require_relative '../shared/artifacts_context'

describe Projects::ArtifactsController do
  describe 'GET /:project/builds/artifacts/:ref_name/browse?job=name' do
    include_context 'artifacts from ref and build name'

    before do
      login_as(user)
    end

    def path_from_ref(
      ref = pipeline.sha, job = build.name, path = 'browse')
      search_namespace_project_artifacts_path(
        project.namespace,
        project,
        ref,
        path,
        job: job)
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

      it_behaves_like 'artifacts from ref successfully'
    end
  end
end
