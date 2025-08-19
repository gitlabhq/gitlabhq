# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Conan::V1::InstancePackages, feature_category: :package_registry do
  include_context 'with conan api setup'

  let_it_be_with_reload(:package) { create(:conan_package, project: project, without_revisions: true) }
  let(:snowplow_gitlab_standard_context) do
    { user: user, project: project, namespace: project.namespace, property: 'i_package_conan_user' }
  end

  describe 'GET /api/v4/packages/conan/v1/ping' do
    let_it_be(:url) { '/packages/conan/v1/ping' }

    it_behaves_like 'conan ping endpoint' do
      let(:x_conan_server_capabilities_header) { 'revisions' }
    end
  end

  describe 'GET /api/v4/packages/conan/v1/conans/search' do
    let_it_be(:url) { '/packages/conan/v1/conans/search' }

    it_behaves_like 'conan search endpoint', scope: :instance

    it_behaves_like 'conan FIPS mode' do
      let(:params) { { q: package.conan_recipe } }

      subject { get api(url), params: params }
    end

    it_behaves_like 'updating personal access token last used' do
      let(:params) { { q: package.conan_recipe } }

      subject { get api(url), params:, headers: }
    end
  end

  describe 'GET /api/v4/packages/conan/v1/users/authenticate' do
    let_it_be(:url) { '/packages/conan/v1/users/authenticate' }

    it_behaves_like 'conan authenticate endpoint'
  end

  describe 'GET /api/v4/packages/conan/v1/users/check_credentials' do
    let_it_be(:url) { "/packages/conan/v1/users/check_credentials" }

    it_behaves_like 'conan check_credentials endpoint'
  end

  context 'with recipe endpoints' do
    let(:project_id) { 9999 }
    let(:url_prefix) { "#{Settings.gitlab.base_url}/api/v4" }
    let(:recipe_path) { package.conan_recipe_path }

    describe 'GET /api/v4/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel' do
      let(:url) { "/packages/conan/v1/conans/#{recipe_path}" }

      it_behaves_like 'recipe snapshot endpoint'
    end

    describe 'GET /api/v4/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel' \
      '/packages/:conan_package_reference' do
      let(:url) { "/packages/conan/v1/conans/#{recipe_path}/packages/#{conan_package_reference}" }

      it_behaves_like 'package snapshot endpoint'
    end

    describe 'GET /api/v4/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel' \
      '/digest' do
      subject(:request) { get api("/packages/conan/v1/conans/#{recipe_path}/digest"), headers: headers }

      it_behaves_like 'recipe download_urls endpoint'
    end

    describe 'GET /api/v4/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel' \
      '/packages/:conan_package_reference/download_urls' do
      subject(:request) do
        get api("/packages/conan/v1/conans/#{recipe_path}/packages/#{conan_package_reference}/download_urls"),
          headers: headers
      end

      it_behaves_like 'package download_urls endpoint'
    end

    describe 'GET /api/v4/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel' \
      '/download_urls' do
      subject(:request) { get api("/packages/conan/v1/conans/#{recipe_path}/download_urls"), headers: headers }

      it_behaves_like 'recipe download_urls endpoint'
    end

    describe 'GET /api/v4/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel' \
      '/packages/:conan_package_reference/digest' do
      subject(:request) do
        get api("/packages/conan/v1/conans/#{recipe_path}/packages/#{conan_package_reference}/digest"), headers: headers
      end

      it_behaves_like 'package download_urls endpoint'
    end

    describe 'POST /api/v4/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel' \
      '/upload_urls' do
      subject(:request) do
        post api("/packages/conan/v1/conans/#{recipe_path}/upload_urls"), params: params.to_json, headers: headers
      end

      it_behaves_like 'recipe upload_urls endpoint'
    end

    describe 'POST /api/v4/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel' \
      '/packages/:conan_package_reference/upload_urls' do
      subject(:request) do
        post api("/packages/conan/v1/conans/#{recipe_path}/packages/123456789/upload_urls"), params: params.to_json,
          headers: headers
      end

      it_behaves_like 'package upload_urls endpoint'
    end

    describe 'DELETE /api/v4/packages/conan/v1/conans/:package_name/:package_version/:package_username' \
      '/:package_channel' do
      let_it_be_with_reload(:package) { create(:conan_package, project: project) }

      subject(:request) { delete api("/packages/conan/v1/conans/#{recipe_path}"), headers: headers }

      it_behaves_like 'delete package endpoint'
    end

    describe 'GET /api/v4/packages/conan/v1/conans/:package_name/:package_version/:package_username' \
      '/:package_channel/search' do
      let(:url) { "/packages/conan/v1/conans/#{recipe_path}/search" }

      it_behaves_like 'GET package references metadata endpoint'
    end
  end

  context 'with file download endpoints' do
    include_context 'for conan file download endpoints'

    describe 'GET /api/v4/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel' \
      '/:recipe_revision/export/:file_name' do
      subject(:request) do
        get api("/packages/conan/v1/files/#{recipe_path}/#{recipe_file_metadata.recipe_revision_value}/export/" \
          "#{recipe_file.file_name}"),
          headers: headers
      end

      it_behaves_like 'recipe file download endpoint'
      it_behaves_like 'project not found by recipe'
    end

    describe 'GET /api/v4/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel' \
      '/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name' do
      subject(:request) do
        get api("/packages/conan/v1/files/#{recipe_path}/#{package_file_metadata.recipe_revision_value}/package" \
          "/#{package_file_metadata.package_reference_value}/#{package_file_metadata.package_revision_value}" \
          "/#{package_file.file_name}"),
          headers: headers
      end

      it_behaves_like 'package file download endpoint'
      it_behaves_like 'project not found by recipe'
    end
  end

  context 'with file upload endpoints' do
    include_context 'for conan file upload endpoints'
    let(:recipe_revision) { ::Packages::Conan::FileMetadatum::DEFAULT_REVISION }
    let(:package_revision) { ::Packages::Conan::FileMetadatum::DEFAULT_REVISION }
    let(:conan_package_reference) { OpenSSL::Digest.hexdigest('SHA1', 'valid_package_reference') }

    describe 'PUT /api/v4/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel' \
      '/:recipe_revision/export/:file_name/authorize' do
      let(:file_name) { 'conanfile.py' }

      subject(:request) do
        put api("/packages/conan/v1/files/#{recipe_path}/0/export/#{file_name}/authorize"), headers: headers_with_token
      end

      it_behaves_like 'workhorse authorize endpoint'
    end

    describe 'PUT /api/v4/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel' \
      '/:recipe_revision/export/:conan_package_reference/:package_revision/:file_name/authorize' do
      let(:file_name) { 'conaninfo.txt' }

      subject(:request) do
        put api("/packages/conan/v1/files/#{recipe_path}/0/package/#{conan_package_reference}/0/#{file_name}" \
          "/authorize"),
          headers: headers_with_token
      end

      it_behaves_like 'workhorse authorize endpoint'
    end

    describe 'PUT /api/v4/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel' \
      '/:recipe_revision/export/:file_name' do
      let(:url) { "/packages/conan/v1/files/#{recipe_path}/0/export/#{file_name}" }

      it_behaves_like 'workhorse recipe file upload endpoint'
    end

    describe 'PUT /api/v4/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel' \
      '/:recipe_revision/export/:conan_package_reference/:package_revision/:file_name' do
      let(:url) { "/packages/conan/v1/files/#{recipe_path}/0/package/#{conan_package_reference}/0/#{file_name}" }

      it_behaves_like 'workhorse package file upload endpoint'
    end
  end
end
