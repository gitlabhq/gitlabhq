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

  shared_examples 'package without revisions returns not found' do |resource: 'Revision'|
    let_it_be(:package) { create(:conan_package, project: project, without_revisions: true) }

    it_behaves_like 'returning response status with message', status: :not_found,
      message: "404 #{resource} Not Found"
  end

  shared_examples 'triggers an internal event' do |event:|
    it 'triggers an internal event' do
      expect { request }
        .to trigger_internal_events(event)
          .with(user: user, project: project, property: 'user', label: 'conan', category: 'InternalEventTracking')
    end
  end

  shared_examples 'recipe revision deletion' do
    it_behaves_like 'triggers an internal event', event: 'delete_recipe_revision_from_registry'

    it 'deletes the package with specific revision' do
      request

      expect(response).to have_gitlab_http_status(:no_content)
      expect(package.conan_recipe_revisions).to match_array([aditional_recipe_revision])
      expect(package.package_files.where(id: revision_package_files_ids)).to all(be_pending_destruction)
    end

    context 'with only one revision' do
      let_it_be_with_reload(:package) { create(:conan_package, project: project) }
      let_it_be(:recipe_revision) { package.conan_recipe_revisions.first.revision }

      it_behaves_like 'triggers an internal event', event: 'delete_package_from_registry'
      it_behaves_like 'returning response status', :no_content
      it { expect { request }.to change { ::Packages::Package.pending_destruction.count }.by(1) }
    end
  end

  shared_examples 'get file list' do |expected_file_list, not_found_err:|
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
      expect(json_response).to eq(expected_file_list)
    end

    context 'when the recipe revision files are not found' do
      # This is a non-existent revision
      let(:recipe_revision) { 'da39a3ee5e6b4b0d3255bfef95601890afd80709' }

      it_behaves_like 'returning response status with message', status: :not_found,
        message: not_found_err
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
        expect(json_response['files'].size).to eq(1)
      end
    end
  end

  shared_examples 'returns 404 when resource does not exist' do
    it 'returns 404' do
      request

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Revision Not Found')
    end
  end

  shared_examples 'returns empty package revisions list when resource does not exist' do
    it 'returns empty package revisions list' do
      subject

      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['packageReference']).to eq(package_reference)
      expect(json_response['revisions']).to be_empty
    end
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/users/authenticate' do
    let(:url) { "/projects/#{project.id}/packages/conan/v2/users/authenticate" }

    it_behaves_like 'conan authenticate endpoint'
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/users/check_credentials' do
    let(:url) { "/projects/#{project.id}/packages/conan/v2/users/check_credentials" }

    it_behaves_like 'conan check_credentials endpoint'
    it_behaves_like 'conan package revisions feature flag check' do
      subject { get api(url), headers: headers }
    end
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/conans/search' do
    let(:url_suffix) { "search" }
    let(:params) { { q: package.conan_recipe } }

    subject { get api(url), params: params }

    it_behaves_like 'conan search endpoint'
    it_behaves_like 'conan FIPS mode'
    it_behaves_like 'conan search endpoint with access to package registry for everyone'
    it_behaves_like 'conan package revisions feature flag check'
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/' \
    ':package_channel/revisions/:recipe_revision/files' do
    let_it_be(:additional_recipe_revision) { create(:conan_recipe_revision, package: package) }

    let_it_be(:additional_recipe_files) do
      create(:conan_package_file, :conan_recipe_file, package: package,
        conan_recipe_revision: additional_recipe_revision, file_name: 'additional_conanfile.py')
    end

    let(:recipe_revision) { package.conan_recipe_revisions.first.revision }
    let(:recipe_path) { package.conan_recipe_path }
    let(:url_suffix) { "#{recipe_path}/revisions/#{recipe_revision}/files" }
    let(:url) { "/projects/#{project_id}/packages/conan/v2/conans/#{url_suffix}" }

    it_behaves_like 'get file list',
      { 'files' => { 'conanfile.py' => {}, 'conanmanifest.txt' => {} } },
      not_found_err: '404 Recipe files Not Found'
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

  describe 'GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/' \
    ':package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision/' \
    'files/:file_name' do
    include_context 'for conan file download endpoints'

    let(:file_name) { package_file.file_name }
    let(:recipe_revision) { package_file_metadata.recipe_revision_value }
    let(:package_revision) { package_file_metadata.package_revision_value }
    let(:conan_package_reference) { package_file_metadata.package_reference_value }
    let(:url_suffix) do
      "#{recipe_path}/revisions/#{recipe_revision}/packages/#{conan_package_reference}/revisions/#{package_revision}/" \
        "files/#{file_name}"
    end

    subject(:request) { get api(url), headers: headers }

    it_behaves_like 'conan package revisions feature flag check'
    it_behaves_like 'packages feature check'
    it_behaves_like 'package file download endpoint'
    it_behaves_like 'accept get request on private project with access to package registry for everyone'
    it_behaves_like 'project not found by project id'

    it_behaves_like 'enforcing job token policies', :read_packages,
      allow_public_access_for_enabled_project_features: :package_registry do
      let(:headers) { job_basic_auth_header(target_job) }
    end

    describe 'parameter validation for package file endpoints' do
      using RSpec::Parameterized::TableSyntax

      let(:url_suffix) do
        "#{recipe_path}/revisions/#{recipe_revision}/packages/#{url_package_reference}/revisions/" \
          "#{url_package_revision}/files/#{url_file_name}"
      end

      # rubocop:disable Layout/LineLength -- Avoid formatting to keep one-line table syntax
      where(:error, :url_package_reference, :url_package_revision, :url_file_name) do
        /conan_package_reference/ | 'invalid_package_reference$' | ref(:package_revision) | ref(:file_name)
        /package_revision/       | ref(:conan_package_reference)                     | 'invalid_package_revi$ion'                        | ref(:file_name)
        /package_revision/       | ref(:conan_package_reference)                     | Packages::Conan::FileMetadatum::DEFAULT_REVISION  | ref(:file_name)
        /file_name/              | ref(:conan_package_reference)                     | ref(:package_revision)                            | 'invalid_file.txt'
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

    it_behaves_like 'conan package revisions feature flag check'
    it_behaves_like 'enforcing read_packages job token policy'
    it_behaves_like 'accept get request on private project with access to package registry for everyone'
    it_behaves_like 'conan FIPS mode'
    it_behaves_like 'package not found'
    it_behaves_like 'project not found by project id'
    it_behaves_like 'package without revisions returns not found'
  end

  describe 'DELETE /api/v4/projects/:id/packages/conan/v2/conans/:package_name/package_version/:package_username/' \
    ':package_channel/revisions/:recipe_revision' do
    let_it_be_with_reload(:package) { create(:conan_package, project: project) }
    let_it_be(:recipe_revision) { package.conan_recipe_revisions.first.revision }
    let_it_be(:revision_package_files_ids) { package.conan_recipe_revisions.first.package_files.ids }
    let_it_be(:additional_recipe_revision) { create(:conan_recipe_revision, package: package) }
    let(:recipe_path) { package.conan_recipe_path }

    let(:url_suffix) { "#{recipe_path}/revisions/#{recipe_revision}" }

    subject(:request) { delete api(url), headers: headers }

    it_behaves_like 'conan package revisions feature flag check'
    it_behaves_like 'packages feature check'
    it_behaves_like 'conan FIPS mode'
    it_behaves_like 'rejects invalid recipe'
    it_behaves_like 'project not found by project id'
    it_behaves_like 'returning response status with message', status: :forbidden,
      message: '403 Forbidden'

    context 'with delete permissions' do
      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'triggers an internal event', event: 'delete_recipe_revision_from_registry'
      it_behaves_like 'package not found'
      it_behaves_like 'package without revisions returns not found'
      it_behaves_like 'handling empty values for username and channel', success_status: :ok
      it 'deletes the package with specific revision' do
        expect { request }.to change { package.conan_recipe_revisions.count }.by(-1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(package.conan_recipe_revisions).to match_array([additional_recipe_revision])
        expect(package.package_files.where(id: revision_package_files_ids)).to all(be_pending_destruction)
      end

      context 'with only one revision' do
        let_it_be_with_reload(:package) { create(:conan_package, project: project) }
        let_it_be(:recipe_revision) { package.conan_recipe_revisions.first.revision }

        it_behaves_like 'triggers an internal event', event: 'delete_package_from_registry'
        it_behaves_like 'returning response status', :ok
        it { expect { request }.to change { ::Packages::Package.pending_destruction.count }.by(1) }
      end

      context 'when the number of files to delete is greater than the maximum allowed' do
        before do
          stub_const("#{described_class}::MAX_FILES_COUNT", 1)
        end

        it_behaves_like 'returning response status with message', status: :unprocessable_entity,
          message: "Cannot delete more than 1 files"
      end
    end
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username' \
    '/:package_channel/revisions' do
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

  describe 'GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username' \
    '/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions' do
    let_it_be(:conan_package_reference) { package.conan_package_references.first.reference }
    let_it_be(:revision1) { package.conan_package_revisions.first }
    let_it_be(:revision2) { create(:conan_package_revision, package: package) }

    let(:recipe_path) { package.conan_recipe_path }
    let(:recipe_revision) { package.conan_recipe_revisions.first.revision }
    let(:package_reference) { "#{package.conan_recipe}##{recipe_revision}:#{conan_package_reference}" }
    let(:url_suffix) { "#{recipe_path}/revisions/#{recipe_revision}/packages/#{conan_package_reference}/revisions" }

    subject(:api_request) { get api(url), headers: headers }

    it 'returns the reference and a list of revisions in descending order' do
      api_request

      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['packageReference']).to eq(package_reference)
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

    it { is_expected.to have_request_urgency(:low) }

    context 'when recipe revision does not exist' do
      let(:recipe_revision) { OpenSSL::Digest.hexdigest('MD5', 'nonexistent-revision') }

      it_behaves_like 'returns empty package revisions list when resource does not exist'
    end

    context 'when package reference does not exist' do
      let(:conan_package_reference) { OpenSSL::Digest.hexdigest('SHA1', 'nonexistent-reference') }

      it_behaves_like 'returns empty package revisions list when resource does not exist'
    end

    context 'when the max revisions count is reached' do
      before do
        stub_const("#{described_class}::MAX_PACKAGE_REVISIONS_COUNT", 1)
      end

      it 'limits the number of files to MAX_PACKAGE_REVISIONS_COUNT' do
        api_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['revisions'].size).to eq(1)
      end
    end

    it_behaves_like 'enforcing read_packages job token policy' do
      subject(:request) { api_request }
    end

    it_behaves_like 'conan package revisions feature flag check'
    it_behaves_like 'packages feature check'
    it_behaves_like 'accept get request on private project with access to package registry for everyone'
    it_behaves_like 'conan FIPS mode'
    it_behaves_like 'package not found'
    it_behaves_like 'project not found by project id'
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username' \
    '/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/latest' do
    let(:recipe_path) { package.conan_recipe_path }
    let(:recipe_revision) { package.conan_recipe_revisions.first.revision }
    let(:conan_package_reference) { package.conan_package_references.first.reference }
    let(:url_suffix) { "#{recipe_path}/revisions/#{recipe_revision}/packages/#{conan_package_reference}/latest" }

    subject(:request) { get api(url), headers: headers }

    it 'returns the latest revision' do
      request

      expect(response).to have_gitlab_http_status(:ok)

      package_revision = package.conan_package_revisions.first

      expect(json_response['revision']).to eq(package_revision.revision)
      expect(json_response['time']).to eq(package_revision.created_at.iso8601(3))
    end

    context 'when recipe revision does not exist' do
      let(:recipe_revision) { OpenSSL::Digest.hexdigest('MD5', 'nonexistent-revision') }

      it_behaves_like 'returns 404 when resource does not exist'
    end

    context 'when package reference does not exist' do
      let(:conan_package_reference) { OpenSSL::Digest.hexdigest('SHA1', 'nonexistent-reference') }

      it_behaves_like 'returns 404 when resource does not exist'
    end

    it_behaves_like 'enforcing read_packages job token policy'
    it_behaves_like 'accept get request on private project with access to package registry for everyone'
    it_behaves_like 'conan FIPS mode'
    it_behaves_like 'package not found'
    it_behaves_like 'project not found by project id'
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/' \
    ':package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision/' \
    'files' do
    let_it_be(:additional_package_reference) { create(:conan_package_reference, package: package) }
    let_it_be(:additional_package_revision) { create(:conan_package_revision, package: package) }

    let_it_be(:additional_package_file_1) do
      create(:conan_package_file,  :conan_package, package: package,
        conan_package_revision: additional_package_revision, file_name: 'additional_conan_package_1.tgz')
    end

    let_it_be(:additional_package_file_2) do
      create(:conan_package_file,  :conan_package, package: package,
        conan_package_reference: additional_package_reference, file_name: 'additional_conan_package_2.tgz')
    end

    let(:recipe_revision) { package.conan_recipe_revisions.first.revision }
    let(:recipe_path) { package.conan_recipe_path }
    let(:package_revision) { package.conan_package_revisions.first.revision }
    let(:url) { "/projects/#{project_id}/packages/conan/v2/conans/#{url_suffix}" }

    let(:url_suffix) do
      "#{recipe_path}/revisions/#{recipe_revision}/packages/#{conan_package_reference}/revisions/" \
        "#{package_revision}/files"
    end

    it_behaves_like 'get file list',
      { 'files' => { 'conan_package.tgz' => {}, 'conaninfo.txt' => {}, 'conanmanifest.txt' => {} } },
      not_found_err: '404 Package files Not Found'
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username' \
    '/:package_channel/search' do
    let(:recipe_path) { package.conan_recipe_path }
    let(:url_suffix) { "#{recipe_path}/search" }

    subject(:request) { get api(url), headers: headers }

    it_behaves_like 'GET package references metadata endpoint'
    it_behaves_like 'accept get request on private project with access to package registry for everyone'
    it_behaves_like 'project not found by project id'
    it_behaves_like 'conan package revisions feature flag check'
  end

  describe 'GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username' \
    '/:package_channel/revisions/:recipe_revision/search' do
    let(:recipe_path) { package.conan_recipe_path }
    let(:recipe_revision) { package.conan_recipe_revisions.first.revision }
    let(:url_suffix) { "#{recipe_path}/revisions/#{recipe_revision}/search" }

    subject(:request) { get api(url), headers: headers }

    it_behaves_like 'GET package references metadata endpoint', with_recipe_revision: true
    it_behaves_like 'accept get request on private project with access to package registry for everyone'
    it_behaves_like 'project not found by project id'
    it_behaves_like 'conan package revisions feature flag check'
  end

  describe 'DELETE /api/v4/projects/:id/packages/conan/v2/conans/:package_name/package_version/:package_username/' \
    ':package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision' do
    let_it_be_with_reload(:package) { create(:conan_package, project: project) }
    let_it_be(:recipe_revision) { package.conan_recipe_revisions.first.revision }
    let_it_be(:package_revision) { package.conan_package_revisions.first.revision }
    let_it_be(:package_reference) { package.conan_package_references.first.reference }
    let_it_be(:package_revision_files_ids) { package.conan_package_revisions.first.package_files.ids }
    let(:recipe_path) { package.conan_recipe_path }

    let(:url_suffix) do
      "#{recipe_path}/revisions/#{recipe_revision}/packages/#{conan_package_reference}/revisions/" \
        "#{package_revision}"
    end

    subject(:request) { delete api(url), headers: headers }

    it_behaves_like 'conan package revisions feature flag check'
    it_behaves_like 'packages feature check'
    it_behaves_like 'conan FIPS mode'
    it_behaves_like 'rejects invalid recipe'
    it_behaves_like 'project not found by project id'
    it_behaves_like 'returning response status with message', status: :forbidden,
      message: '403 Forbidden'

    context 'with delete permissions' do
      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'package not found'
      it_behaves_like 'package without revisions returns not found', resource: 'Package Revision'
      it_behaves_like 'handling empty values for username and channel', success_status: :ok

      context 'with multiple package revisions' do
        let_it_be(:additional_package_revision) { create(:conan_package_revision, package: package) }

        it_behaves_like 'triggers an internal event', event: 'delete_package_revision_from_registry'

        it 'deletes the package_revision and not the package reference' do
          expect { request }.to change { package.conan_package_revisions.count }.by(-1)
          .and not_change { package.conan_package_references.count }

          expect(response).to have_gitlab_http_status(:ok)
          expect(package.conan_package_revisions).to match_array([additional_package_revision])
          expect(package.package_files.where(id: package_revision_files_ids)).to all(be_pending_destruction)
        end
      end

      context 'with only one package_revision' do
        it_behaves_like 'triggers an internal event', event: 'delete_package_reference_from_registry'

        it_behaves_like 'returning response status', :ok
        it 'deletes the package_reference' do
          expect { request }.to change { package.conan_package_revisions.count }.by(-1)
          .and change { package.conan_package_references.count }.by(-1)

          expect(response).to have_gitlab_http_status(:ok)
          expect(package.package_files.where(id: package_revision_files_ids)).to all(be_pending_destruction)
        end
      end

      context 'when the number of files to delete is greater than the maximum allowed' do
        before do
          stub_const("#{described_class}::MAX_FILES_COUNT", 1)
        end

        it_behaves_like 'returning response status with message', status: :unprocessable_entity,
          message: 'Cannot delete more than 1 files'
      end
    end
  end
end
