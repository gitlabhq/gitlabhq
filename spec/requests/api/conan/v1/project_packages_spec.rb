# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Conan::V1::ProjectPackages, feature_category: :package_registry do
  include_context 'conan api setup'

  let(:project_id) { project.id }

  shared_examples 'accept get request on private project with access to package registry for everyone' do
    subject { get api(url) }

    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
    end

    it_behaves_like 'returning response status', :ok
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v1/ping' do
    let(:url) { "/projects/#{project.id}/packages/conan/v1/ping" }

    it_behaves_like 'conan ping endpoint' do
      let(:x_conan_server_capabilities_header) { 'revisions' }
    end

    context 'when the conan_package_revisions_support FF is disabled' do
      before do
        stub_feature_flags(conan_package_revisions_support: false)
      end

      it 'contains "" in the X-Conan-Server-Capabilities header' do
        get api(url), headers: headers

        expect(response.headers['X-Conan-Server-Capabilities']).to be_empty
      end
    end
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v1/conans/search' do
    let(:url) { "/projects/#{project.id}/packages/conan/v1/conans/search" }

    it_behaves_like 'conan search endpoint'

    it_behaves_like 'conan FIPS mode' do
      let(:params) { { q: package.conan_recipe } }

      subject { get api(url), params: params }
    end

    it_behaves_like 'conan search endpoint with access to package registry for everyone'
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v1/users/authenticate' do
    let(:url) { "/projects/#{project.id}/packages/conan/v1/users/authenticate" }

    it_behaves_like 'conan authenticate endpoint'
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v1/users/check_credentials' do
    let(:url) { "/projects/#{project.id}/packages/conan/v1/users/check_credentials" }

    it_behaves_like 'conan check_credentials endpoint'
  end

  context 'with recipe endpoints' do
    include_context 'conan recipe endpoints'

    let(:url_prefix) { "#{Settings.gitlab.base_url}/api/v4/projects/#{project_id}" }
    let(:recipe_path) { package.conan_recipe_path }

    subject(:request) { get api(url), headers: headers }

    describe 'GET /api/v4/projects/:id/packages/conan/v1/conans/:package_name/package_version/:package_username' \
      '/:package_channel' do
      let(:url) { "/projects/#{project_id}/packages/conan/v1/conans/#{recipe_path}" }

      it_behaves_like 'recipe snapshot endpoint'
      it_behaves_like 'accept get request on private project with access to package registry for everyone'
    end

    describe 'GET /api/v4/projects/:id/packages/conan/v1/conans/:package_name/package_version/:package_username' \
      '/:package_channel/packages/:conan_package_reference' do
      let(:url) do
        "/projects/#{project_id}/packages/conan/v1/conans/#{recipe_path}/packages/#{conan_package_reference}"
      end

      it_behaves_like 'package snapshot endpoint'
      it_behaves_like 'accept get request on private project with access to package registry for everyone'
    end

    describe 'GET /api/v4/projects/:id/packages/conan/v1/conans/:package_name/package_version/:package_username' \
      '/:package_channel/digest' do
      let(:url) { "/projects/#{project_id}/packages/conan/v1/conans/#{recipe_path}/digest" }

      it_behaves_like 'recipe download_urls endpoint'
      it_behaves_like 'accept get request on private project with access to package registry for everyone'
    end

    describe 'GET /api/v4/projects/:id/packages/conan/v1/conans/:package_name/package_version/:package_username' \
      '/:package_channel/packages/:conan_package_reference/download_urls' do
      let(:url) do
        "/projects/#{project_id}/packages/conan/v1/conans/#{recipe_path}/packages/#{conan_package_reference}" \
          "/download_urls"
      end

      it_behaves_like 'package download_urls endpoint'
      it_behaves_like 'accept get request on private project with access to package registry for everyone'
    end

    describe 'GET /api/v4/projects/:id/packages/conan/v1/conans/:package_name/package_version/:package_username' \
      '/:package_channel/download_urls' do
      let(:url) { "/projects/#{project_id}/packages/conan/v1/conans/#{recipe_path}/download_urls" }

      it_behaves_like 'recipe download_urls endpoint'
      it_behaves_like 'accept get request on private project with access to package registry for everyone'
    end

    describe 'GET /api/v4/projects/:id/packages/conan/v1/conans/:package_name/package_version/:package_username' \
      '/:package_channel/packages/:conan_package_reference/digest' do
      let(:url) do
        "/projects/#{project_id}/packages/conan/v1/conans/#{recipe_path}/packages/#{conan_package_reference}/digest"
      end

      it_behaves_like 'package download_urls endpoint'
      it_behaves_like 'accept get request on private project with access to package registry for everyone'
    end

    describe 'POST /api/v4/projects/:id/packages/conan/v1/conans/:package_name/package_version/:package_username' \
      '/:package_channel/upload_urls' do
      subject(:request) do
        post api("/projects/#{project_id}/packages/conan/v1/conans/#{recipe_path}/upload_urls"), params: params.to_json,
          headers: headers
      end

      it_behaves_like 'recipe upload_urls endpoint'
    end

    describe 'POST /api/v4/projects/:id/packages/conan/v1/conans/:package_name/package_version/:package_username' \
      '/:package_channel/packages/:conan_package_reference/upload_urls' do
      subject(:request) do
        post api("/projects/#{project_id}/packages/conan/v1/conans/#{recipe_path}/packages/123456789/upload_urls"),
          params: params.to_json, headers: headers
      end

      it_behaves_like 'package upload_urls endpoint'
    end

    describe 'DELETE /api/v4/projects/:id/packages/conan/v1/conans/:package_name/package_version/:package_username' \
      '/:package_channel' do
      let_it_be_with_reload(:package) { create(:conan_package, project: project) }

      subject(:request) do
        delete api("/projects/#{project_id}/packages/conan/v1/conans/#{recipe_path}"), headers: headers
      end

      it_behaves_like 'delete package endpoint'
    end
  end

  context 'with file download endpoints' do
    include_context 'conan file download endpoints'

    subject(:request) { get api(url), headers: headers }

    describe 'GET /api/v4/projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username' \
      '/:package_channel/:recipe_revision/export/:file_name' do
      let(:url) do
        "/projects/#{project_id}/packages/conan/v1/files/#{recipe_path}/#{metadata.recipe_revision_value}" \
          "/export/#{recipe_file.file_name}"
      end

      it_behaves_like 'recipe file download endpoint'
      it_behaves_like 'project not found by project id'
      it_behaves_like 'accept get request on private project with access to package registry for everyone'
    end

    describe 'GET /api/v4/projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username' \
      '/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name' do
      let(:url) do
        "/projects/#{project_id}/packages/conan/v1/files/#{recipe_path}/#{metadata.recipe_revision_value}/package" \
          "/#{metadata.conan_package_reference}/#{metadata.package_revision_value}/#{package_file.file_name}"
      end

      it_behaves_like 'package file download endpoint'
      it_behaves_like 'project not found by project id'
      it_behaves_like 'accept get request on private project with access to package registry for everyone'
    end
  end

  context 'with file upload endpoints' do
    include_context 'conan file upload endpoints'

    describe 'PUT /api/v4/projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username' \
      '/:package_channel/:recipe_revision/export/:file_name/authorize' do
      let(:file_name) { 'conanfile.py' }

      subject(:request) do
        put api("/projects/#{project_id}/packages/conan/v1/files/#{recipe_path}/0/export/#{file_name}/authorize"),
          headers: headers_with_token
      end

      it_behaves_like 'workhorse authorize endpoint'
    end

    describe 'PUT /api/v4/projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username' \
      '/:package_channel/:recipe_revision/export/:conan_package_reference/:package_revision/:file_name/authorize' do
      let(:file_name) { 'conaninfo.txt' }

      subject(:request) do
        put api("/projects/#{project_id}/packages/conan/v1/files/#{recipe_path}/0/package/123456789/0/#{file_name}" \
          "/authorize"),
          headers: headers_with_token
      end

      it_behaves_like 'workhorse authorize endpoint'
    end

    describe 'PUT /api/v4/projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username' \
      '/:package_channel/:recipe_revision/export/:file_name' do
      let(:url) { "/api/v4/projects/#{project_id}/packages/conan/v1/files/#{recipe_path}/0/export/#{file_name}" }

      it_behaves_like 'workhorse recipe file upload endpoint'
    end

    describe 'PUT /api/v4/projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username' \
      '/:package_channel/:recipe_revision/export/:conan_package_reference/:package_revision/:file_name' do
      let(:url) do
        "/api/v4/projects/#{project_id}/packages/conan/v1/files/#{recipe_path}/0/package/123456789/0/#{file_name}"
      end

      it_behaves_like 'workhorse package file upload endpoint'
    end
  end
end
