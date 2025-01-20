# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Conan::V1::InstancePackages, feature_category: :package_registry do
  let(:snowplow_gitlab_standard_context) do
    { user: user, project: project, namespace: project.namespace, property: 'i_package_conan_user' }
  end

  include_context 'conan api setup'

  describe 'GET /api/v4/packages/conan/v1/ping' do
    let_it_be(:url) { '/packages/conan/v1/ping' }

    it_behaves_like 'conan ping endpoint' do
      let(:x_conan_server_capabilities_header) { 'revisions' }
    end
  end

  describe 'GET /api/v4/packages/conan/v1/conans/search' do
    let_it_be(:url) { '/packages/conan/v1/conans/search' }

    it_behaves_like 'conan search endpoint'

    it_behaves_like 'conan FIPS mode' do
      let(:params) { { q: package.conan_recipe } }

      subject { get api(url), params: params }
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
    include_context 'conan recipe endpoints'

    let(:project_id) { 9999 }
    let(:url_prefix) { "#{Settings.gitlab.base_url}/api/v4" }

    describe 'GET /api/v4/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel' do
      let(:recipe_path) { package.conan_recipe_path }
      let(:url) { "/packages/conan/v1/conans/#{recipe_path}" }

      it_behaves_like 'recipe snapshot endpoint'
    end

    describe 'GET /api/v4/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel' \
      '/packages/:conan_package_reference' do
      let(:recipe_path) { package.conan_recipe_path }
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
  end

  context 'with file download endpoints' do
    include_context 'conan file download endpoints'

    describe 'GET /api/v4/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel' \
      '/:recipe_revision/export/:file_name' do
      subject(:request) do
        get api("/packages/conan/v1/files/#{recipe_path}/#{metadata.recipe_revision_value}/export/" \
          "#{recipe_file.file_name}"),
          headers: headers
      end

      it_behaves_like 'recipe file download endpoint'
      it_behaves_like 'project not found by recipe'
    end

    describe 'GET /api/v4/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel' \
      '/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name' do
      subject(:request) do
        get api("/packages/conan/v1/files/#{recipe_path}/#{metadata.recipe_revision_value}/package" \
          "/#{metadata.conan_package_reference}/#{metadata.package_revision_value}/#{package_file.file_name}"),
          headers: headers
      end

      it_behaves_like 'package file download endpoint'
      it_behaves_like 'project not found by recipe'
    end
  end

  context 'with file upload endpoints' do
    include_context 'conan file upload endpoints'

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
        put api("/packages/conan/v1/files/#{recipe_path}/0/package/123456789/0/#{file_name}/authorize"),
          headers: headers_with_token
      end

      it_behaves_like 'workhorse authorize endpoint'
    end

    describe 'PUT /api/v4/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel' \
      '/:recipe_revision/export/:file_name' do
      let(:url) { "/api/v4/packages/conan/v1/files/#{recipe_path}/0/export/#{file_name}" }

      it_behaves_like 'workhorse recipe file upload endpoint'
    end

    describe 'PUT /api/v4/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel' \
      '/:recipe_revision/export/:conan_package_reference/:package_revision/:file_name' do
      let(:url) { "/api/v4/packages/conan/v1/files/#{recipe_path}/0/package/123456789/0/#{file_name}" }

      it_behaves_like 'workhorse package file upload endpoint'
    end
  end
end
