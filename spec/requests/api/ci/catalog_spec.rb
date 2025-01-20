# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Catalog, feature_category: :pipeline_composition do
  include HttpBasicAuthHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :catalog_resource_with_components) }
  let_it_be(:catalog_resource) { create(:ci_catalog_resource, project: project) }
  let_it_be(:release) do
    create(:release, project: project, sha: project.repository.root_ref_sha, author: user)
  end

  let(:metadata) do
    {
      components: [
        { name: 'hello-component', spec: { inputs: { hello: nil } }, component_type: 'template' },
        { name: 'world-component', spec: { inputs: { world: { default: 'abc' } } }, component_type: 'template' }
      ]
    }
  end

  describe 'POST /projects/:id/catalog/publish' do
    let(:url) { "/projects/#{project.id}/catalog/publish" }

    subject(:publish) do
      post api(url, user), params: { version: release.tag, metadata: metadata }
    end

    it_behaves_like 'enforcing job token policies', :admin_releases do
      before_all do
        project.add_developer(user)
      end

      let(:request) do
        post api(url), params: { version: release.tag, metadata: metadata, job_token: target_job.token }
      end
    end

    context 'when the project does not exist' do
      let(:url) { "/projects/invalid-path/catalog/publish" }

      it 'returns a 404 response' do
        publish

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Project Not Found')
      end
    end

    context 'when the user is not authorized to project' do
      it 'returns a 403 response' do
        publish

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq('403 Forbidden')
      end
    end

    context 'when the user is not authorized to update the release' do
      before_all do
        project.add_guest(user)
      end

      it 'returns a 403 response' do
        publish

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq('403 Forbidden')
      end
    end

    context 'when the user is authorized as developer' do
      before_all do
        project.add_developer(user)
      end

      it 'returns a success response' do
        publish

        expect(response).to have_gitlab_http_status(:created)

        expect(json_response['catalog_url']).to eq(
          "http://localhost/explore/catalog/#{project.full_path}"
        )
      end

      it 'publishes the release to the catalog' do
        expect do
          expect do
            publish
          end.to change { project.catalog_resource_versions.count }.by(1)
        end.to change { project.ci_components.count }.by(2)

        release = project.releases.last
        version = project.catalog_resource_versions.last
        components = project.ci_components.last(2)

        expect(version.release).to eq(release)
        expect(version.name).to eq(release.tag)
        expect(components.map(&:name)).to match_array(%w[hello-component world-component])
        expect(components.map(&:spec)).to match_array(
          [
            { 'inputs' => { 'hello' => nil } },
            { 'inputs' => { 'world' => { 'default' => 'abc' } } }
          ]
        )
        expect(components.map(&:component_type)).to all(eq('template'))
      end

      context 'when the release was already published' do
        before do
          post api(url, user), params: { version: release.tag, metadata: metadata }
        end

        it 'returns an error response' do
          publish

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq('Release has already been published')
        end
      end

      context 'when the release author is different' do
        let(:release) { create(:release, project: project, sha: project.repository.root_ref_sha) }

        it 'returns a 403 response' do
          publish

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq('Published by must be the same as the release author')
        end
      end

      context 'when the release does not exist' do
        let(:release) { create(:release) }

        it 'returns a 404 response' do
          publish

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Not found')
        end
      end
    end
  end
end
