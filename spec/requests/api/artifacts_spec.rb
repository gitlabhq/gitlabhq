require 'spec_helper'
require_relative '../shared/artifacts_context'

describe API::API, api: true  do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) do
    create(:ci_pipeline, project: project, sha: project.commit('fix').sha)
  end
  let(:build) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }

  before do
    project.team << [user, :developer]
  end

  describe 'GET /projects/:id/artifacts/:ref_name/:build_name' do
    def path_from_ref(ref = pipeline.sha, build_name = build.name, _ = '')
      api("/projects/#{project.id}/artifacts/#{ref}/#{build_name}", user)
    end

    context '401' do
      let(:user) { nil }

      before do
        get path_from_ref
      end

      it 'gives 401 for unauthorized user' do
        expect(response).to have_http_status(401)
      end
    end

    context '404' do
      def verify
        expect(response).to have_http_status(404)
      end

      it_behaves_like 'artifacts from ref with 404'
    end

    context '302' do
      def verify
        expect(response).to redirect_to(
          "/projects/#{project.id}/builds/#{build.id}/artifacts")
      end

      it_behaves_like 'artifacts from ref with 302'
    end
  end
end
