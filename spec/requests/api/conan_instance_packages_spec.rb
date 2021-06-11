# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ConanInstancePackages do
  let(:snowplow_standard_context_params) { { user: user, project: project, namespace: project.namespace } }

  include_context 'conan api setup'

  describe 'GET /api/v4/packages/conan/v1/ping' do
    let_it_be(:url) { '/packages/conan/v1/ping' }

    it_behaves_like 'conan ping endpoint'
  end

  describe 'GET /api/v4/packages/conan/v1/conans/search' do
    let_it_be(:url) { '/packages/conan/v1/conans/search' }

    it_behaves_like 'conan search endpoint'
  end

  describe 'GET /api/v4/packages/conan/v1/users/authenticate' do
    let_it_be(:url) { '/packages/conan/v1/users/authenticate' }

    it_behaves_like 'conan authenticate endpoint'
  end

  describe 'GET /api/v4/packages/conan/v1/users/check_credentials' do
    let_it_be(:url) { "/packages/conan/v1/users/check_credentials" }

    it_behaves_like 'conan check_credentials endpoint'
  end

  context 'recipe endpoints' do
    include_context 'conan recipe endpoints'

    let(:project_id) { 9999 }
    let(:url_prefix) { "#{Settings.gitlab.base_url}/api/v4" }

    describe 'GET /api/v4/packages/conan/v1/conans/:package_name/package_version/:package_username/:package_channel' do
      let(:recipe_path) { package.conan_recipe_path }
      let(:url) { "/packages/conan/v1/conans/#{recipe_path}" }

      it_behaves_like 'recipe snapshot endpoint'
    end

    describe 'GET /api/v4/packages/conan/v1/conans/:package_name/package_version/:package_username/:package_channel/packages/:conan_package_reference' do
      let(:recipe_path) { package.conan_recipe_path }
      let(:url) { "/packages/conan/v1/conans/#{recipe_path}/packages/#{conan_package_reference}" }

      it_behaves_like 'package snapshot endpoint'
    end

    describe 'GET /api/v4/packages/conan/v1/conans/:package_name/package_version/:package_username/:package_channel/digest' do
      subject { get api("/packages/conan/v1/conans/#{recipe_path}/digest"), headers: headers }

      it_behaves_like 'recipe download_urls endpoint'
    end

    describe 'GET /api/v4/packages/conan/v1/conans/:package_name/package_version/:package_username/:package_channel/packages/:conan_package_reference/download_urls' do
      subject { get api("/packages/conan/v1/conans/#{recipe_path}/packages/#{conan_package_reference}/download_urls"), headers: headers }

      it_behaves_like 'package download_urls endpoint'
    end

    describe 'GET /api/v4/packages/conan/v1/conans/:package_name/package_version/:package_username/:package_channel/download_urls' do
      subject { get api("/packages/conan/v1/conans/#{recipe_path}/download_urls"), headers: headers }

      it_behaves_like 'recipe download_urls endpoint'
    end

    describe 'GET /api/v4/packages/conan/v1/conans/:package_name/package_version/:package_username/:package_channel/packages/:conan_package_reference/digest' do
      subject { get api("/packages/conan/v1/conans/#{recipe_path}/packages/#{conan_package_reference}/digest"), headers: headers }

      it_behaves_like 'package download_urls endpoint'
    end

    describe 'POST /api/v4/packages/conan/v1/conans/:package_name/package_version/:package_username/:package_channel/upload_urls' do
      subject { post api("/packages/conan/v1/conans/#{recipe_path}/upload_urls"), params: params.to_json, headers: headers }

      it_behaves_like 'recipe upload_urls endpoint'
    end

    describe 'POST /api/v4/packages/conan/v1/conans/:package_name/package_version/:package_username/:package_channel/packages/:conan_package_reference/upload_urls' do
      subject { post api("/packages/conan/v1/conans/#{recipe_path}/packages/123456789/upload_urls"), params: params.to_json, headers: headers }

      it_behaves_like 'package upload_urls endpoint'
    end

    describe 'DELETE /api/v4/packages/conan/v1/conans/:package_name/package_version/:package_username/:package_channel' do
      subject { delete api("/packages/conan/v1/conans/#{recipe_path}"), headers: headers}

      it_behaves_like 'delete package endpoint'
    end
  end

  context 'file download endpoints' do
    include_context 'conan file download endpoints'

    describe 'GET /api/v4/packages/conan/v1/files/:package_name/package_version/:package_username/:package_channel/
:recipe_revision/export/:file_name' do
      subject do
        get api("/packages/conan/v1/files/#{recipe_path}/#{metadata.recipe_revision}/export/#{recipe_file.file_name}"),
            headers: headers
      end

      it_behaves_like 'recipe file download endpoint'
      it_behaves_like 'project not found by recipe'
    end

    describe 'GET /api/v4/packages/conan/v1/files/:package_name/package_version/:package_username/:package_channel/
:recipe_revision/package/:conan_package_reference/:package_revision/:file_name' do
      subject do
        get api("/packages/conan/v1/files/#{recipe_path}/#{metadata.recipe_revision}/package/#{metadata.conan_package_reference}/#{metadata.package_revision}/#{package_file.file_name}"),
            headers: headers
      end

      it_behaves_like 'package file download endpoint'
      it_behaves_like 'project not found by recipe'
    end
  end

  context 'file upload endpoints' do
    include_context 'conan file upload endpoints'

    describe 'PUT /api/v4/packages/conan/v1/files/:package_name/package_version/:package_username/:package_channel/:recipe_revision/export/:file_name/authorize' do
      let(:file_name) { 'conanfile.py' }

      subject { put api("/packages/conan/v1/files/#{recipe_path}/0/export/#{file_name}/authorize"), headers: headers_with_token }

      it_behaves_like 'workhorse authorize endpoint'
    end

    describe 'PUT /api/v4/packages/conan/v1/files/:package_name/package_version/:package_username/:package_channel/:recipe_revision/export/:conan_package_reference/:package_revision/:file_name/authorize' do
      let(:file_name) { 'conaninfo.txt' }

      subject { put api("/packages/conan/v1/files/#{recipe_path}/0/package/123456789/0/#{file_name}/authorize"), headers: headers_with_token }

      it_behaves_like 'workhorse authorize endpoint'
    end

    describe 'PUT /api/v4/packages/conan/v1/files/:package_name/package_version/:package_username/:package_channel/:recipe_revision/export/:file_name' do
      let(:url) { "/api/v4/packages/conan/v1/files/#{recipe_path}/0/export/#{file_name}" }

      it_behaves_like 'workhorse recipe file upload endpoint'
    end

    describe 'PUT /api/v4/packages/conan/v1/files/:package_name/package_version/:package_username/:package_channel/:recipe_revision/export/:conan_package_reference/:package_revision/:file_name' do
      let(:url) { "/api/v4/packages/conan/v1/files/#{recipe_path}/0/package/123456789/0/#{file_name}" }

      it_behaves_like 'workhorse package file upload endpoint'
    end
  end
end
