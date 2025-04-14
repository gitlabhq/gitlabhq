# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Conan::V2::ProjectPackages, feature_category: :package_registry do
  include_context 'with conan api setup'

  let_it_be_with_reload(:package) { create(:conan_package, project: project) }
  let(:project_id) { project.id }
  let(:url) { "/projects/#{project_id}/packages/conan/v2/conans/#{url_suffix}" }

  shared_examples 'conan package revisions feature flag check' do
    before do
      stub_feature_flags(conan_package_revisions_support: false)
    end

    it_behaves_like 'returning response status with message', status: :not_found,
      message: "404 'conan_package_revisions_support' feature flag is disabled Not Found"
  end

  shared_examples 'packages feature check' do
    before do
      stub_packages_setting(enabled: false)
    end

    it_behaves_like 'returning response status', :not_found
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/users/check_credentials' do
    let(:url) { "/projects/#{project.id}/packages/conan/v2/users/check_credentials" }

    it_behaves_like 'conan check_credentials endpoint'
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/conans/search' do
    let(:url_suffix) { "search" }

    it_behaves_like 'conan search endpoint'

    it_behaves_like 'conan FIPS mode' do
      let(:params) { { q: package.conan_recipe } }

      subject { get api(url), params: params }
    end

    it_behaves_like 'conan search endpoint with access to package registry for everyone'
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/' \
    ':package_channel/revisions/:recipe_revision/files' do
    include_context 'for conan file download endpoints'

    let(:recipe_revision) { recipe_file_metadata.recipe_revision_value }
    let(:url_suffix) { "#{recipe_path}/revisions/#{recipe_revision}/files" }
    let(:url) { "/projects/#{project_id}/packages/conan/v2/conans/#{url_suffix}" }

    subject(:api_request) { get api(url), headers: headers }

    it_behaves_like 'enforcing read_packages job token policy' do
      subject(:request) { api_request }
    end

    it_behaves_like 'conan FIPS mode'
    it_behaves_like 'accept get request on private project with access to package registry for everyone'

    it { is_expected.to have_request_urgency(:low) }

    it 'returns the file list' do
      api_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq({ 'files' => { 'conanfile.py' => {}, 'conanmanifest.txt' => {} } })
    end

    context 'when the recipe revision files are not found' do
      # This is a non-existent revision
      let(:recipe_revision) { 'da39a3ee5e6b4b0d3255bfef95601890afd80709' }

      it_behaves_like 'returning response status with message', status: :not_found,
        message: '404 Recipe files Not Found'
    end

    context 'when the package is not found' do
      # This is a non-existent revision
      let(:recipe_path) { 'test/9.0.0/namespace1+project-1/stable' }

      it_behaves_like 'returning response status with message', status: :not_found, message: '404 Package Not Found'
    end

    context 'when the limit is reached' do
      before do
        stub_const("#{described_class}::MAX_FILES_COUNT", 1)
      end

      it 'limits the number of files to MAX_FILES_COUNT' do
        api_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq("files" => { "conanfile.py" => {} })
      end
    end
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/' \
    ':package_channel/revisions/:recipe_revision/files/:file_name' do
    include_context 'for conan file download endpoints'

    let(:file_name) { recipe_file.file_name }
    let(:recipe_revision) { recipe_file_metadata.recipe_revision_value }
    let(:url_suffix) { "#{recipe_path}/revisions/#{recipe_revision}/files/#{file_name}" }

    subject(:request) { get api(url), headers: headers }

    it_behaves_like 'conan package revisions feature flag check'
    it_behaves_like 'packages feature check'
    it_behaves_like 'recipe file download endpoint'
    it_behaves_like 'accept get request on private project with access to package registry for everyone'
    it_behaves_like 'project not found by project id'

    it_behaves_like 'enforcing job token policies', :read_packages,
      allow_public_access_for_enabled_project_features: :package_registry do
      let(:headers) { job_basic_auth_header(target_job) }
    end

    describe 'parameter validation for recipe file endpoints' do
      using RSpec::Parameterized::TableSyntax

      let(:url_suffix) { "#{url_recipe_path}/revisions/#{url_recipe_revision}/files/#{url_file_name}" }

      # rubocop:disable Layout/LineLength -- Avoid formatting to keep one-line table syntax
      where(:error, :url_recipe_path, :url_recipe_revision, :url_file_name) do
        /package_name/     | 'pac$kage-1/1.0.0/namespace1+project-1/stable' | ref(:recipe_revision)                            | ref(:file_name)
        /package_version/  | 'package-1/1.0.$/namespace1+project-1/stable'  | ref(:recipe_revision)                            | ref(:file_name)
        /package_username/ | 'package-1/1.0.0/name$pace1+project-1/stable'  | ref(:recipe_revision)                            | ref(:file_name)
        /package_channel/  | 'package-1/1.0.0/namespace1+project-1/$table'  | ref(:recipe_revision)                            | ref(:file_name)
        /recipe_revision/  | ref(:recipe_path)                              | 'invalid_revi$ion'                               | ref(:file_name)
        /recipe_revision/  | ref(:recipe_path)                              | Packages::Conan::FileMetadatum::DEFAULT_REVISION | ref(:file_name)
        /file_name/        | ref(:recipe_path)                              | ref(:recipe_revision)                            | 'invalid_file.txt'
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it_behaves_like 'returning response status with error', status: :bad_request, error: params[:error]
      end
    end
  end

  context 'with file upload endpoints' do
    include_context 'for conan file upload endpoints'
    let(:file_name) { 'conanfile.py' }
    let(:recipe_revision) { OpenSSL::Digest.hexdigest('MD5', 'valid_recipe_revision') }
    let(:conan_package_reference) { OpenSSL::Digest.hexdigest('SHA1', 'valid_package_reference') }
    let(:package_revision) { OpenSSL::Digest.hexdigest('MD5', 'valid_package_revision') }

    describe 'PUT /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/' \
      ':package_channel/revisions/:recipe_revision/files/:file_name' do
      let(:url_suffix) { "#{recipe_path}/revisions/#{recipe_revision}/files/#{file_name}" }

      subject(:request) { put api(url), headers: headers_with_token }

      it_behaves_like 'conan package revisions feature flag check'
      it_behaves_like 'packages feature check'
      it_behaves_like 'workhorse recipe file upload endpoint', revision: true
    end

    describe 'PUT /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/' \
      ':package_channel/revisions/:recipe_revision/files/:file_name/authorize' do
      let(:url_suffix) { "#{recipe_path}/revisions/#{recipe_revision}/files/#{file_name}/authorize" }

      subject(:request) do
        put api(url),
          headers: headers_with_token
      end

      it_behaves_like 'conan package revisions feature flag check'
      it_behaves_like 'packages feature check'
      it_behaves_like 'workhorse authorize endpoint'
    end

    describe 'PUT /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/' \
      ':package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision/' \
      'files/:file_name' do
      let(:file_name) { 'conaninfo.txt' }
      let(:url_suffix) do
        "#{recipe_path}/revisions/#{recipe_revision}/packages/#{conan_package_reference}/revisions/" \
          "#{package_revision}/files/#{file_name}"
      end

      subject(:request) { put api(url), headers: headers_with_token }

      it_behaves_like 'conan package revisions feature flag check'
      it_behaves_like 'packages feature check'
      it_behaves_like 'workhorse package file upload endpoint', revision: true
    end

    describe 'PUT /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/' \
      ':package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision/' \
      'files/:file_name/authorize' do
      let(:file_name) { 'conaninfo.txt' }
      let(:url_suffix) do
        "#{recipe_path}/revisions/#{recipe_revision}/packages/#{conan_package_reference}/revisions/" \
          "#{package_revision}/files/#{file_name}/authorize"
      end

      subject(:request) { put api(url), headers: headers_with_token }

      it_behaves_like 'conan package revisions feature flag check'
      it_behaves_like 'packages feature check'
      it_behaves_like 'workhorse authorize endpoint'
    end
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username' \
    '/:package_channel/latest' do
    include_context 'for conan recipe endpoints'

    let(:recipe_path) { package.conan_recipe_path }
    let(:url_suffix) { "#{recipe_path}/latest" }

    subject(:request) { get api(url), headers: headers }

    it 'returns the latest revision' do
      request

      expect(response).to have_gitlab_http_status(:ok)

      recipe_revision = package.conan_recipe_revisions.first

      expect(json_response['revision']).to eq(recipe_revision.revision)
      expect(json_response['time']).to eq(recipe_revision.created_at.iso8601(3))
    end

    context 'when package has no revisions' do
      let_it_be(:package) { create(:conan_package, project: project, without_revisions: true) }

      it 'returns 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Revision Not Found')
      end
    end

    it_behaves_like 'enforcing read_packages job token policy'
    it_behaves_like 'accept get request on private project with access to package registry for everyone'
    it_behaves_like 'conan FIPS mode'
    it_behaves_like 'package not found'
    it_behaves_like 'project not found by project id'
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username' \
    '/:package_channel/revisions' do
    include_context 'for conan recipe endpoints'

    let(:recipe_path) { package.conan_recipe_path }
    let(:url_suffix) { "#{recipe_path}/revisions" }
    let_it_be(:revision1) { package.conan_recipe_revisions.first }
    let_it_be(:revision2) { create(:conan_recipe_revision, package: package) }

    subject(:request) { get api(url), headers: headers }

    it 'returns the reference and a list of revisions in descending order' do
      request

      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['reference']).to eq(package.conan_recipe)
      expect(json_response['revisions']).to eq([
        {
          'revision' => revision2.revision,
          'time' => revision2.created_at.iso8601(3)
        },
        {
          'revision' => revision1.revision,
          'time' => revision1.created_at.iso8601(3)
        }
      ])
    end

    it_behaves_like 'conan package revisions feature flag check'
    it_behaves_like 'packages feature check'
    it_behaves_like 'enforcing read_packages job token policy'
    it_behaves_like 'accept get request on private project with access to package registry for everyone'
    it_behaves_like 'conan FIPS mode'
    it_behaves_like 'package not found'
    it_behaves_like 'project not found by project id'
  end
end
