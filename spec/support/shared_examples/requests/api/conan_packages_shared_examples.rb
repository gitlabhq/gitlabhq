# frozen_string_literal: true

RSpec.shared_examples 'conan ping endpoint' do
  it_behaves_like 'conan FIPS mode' do
    subject { get api(url) }
  end

  it 'responds with 200 OK when no token provided' do
    get api(url)

    expect(response).to have_gitlab_http_status(:ok)
    expect(response.headers['X-Conan-Server-Capabilities']).to eq(x_conan_server_capabilities_header)
  end

  context 'packages feature disabled' do
    it 'responds with 404 Not Found' do
      stub_packages_setting(enabled: false)
      get api(url)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end

RSpec.shared_examples 'conan search endpoint' do |scope: :project|
  using RSpec::Parameterized::TableSyntax

  subject { json_response['results'] }

  context 'with a public project' do
    before do
      project.update!(visibility: 'public')

      # Do not pass the HTTP_AUTHORIZATION header,
      # in order to test that this public project's packages
      # are visible to anonymous search.
      get api(url), params: params
    end

    context 'returns packages with a matching name' do
      let(:params) { { q: package.conan_recipe } }

      it { is_expected.to contain_exactly(package.conan_recipe) }
    end

    context 'when using a * wildcard' do
      let(:params) { { q: "#{package.name[0, 3]}*" } }

      if scope == :project
        it { is_expected.to contain_exactly(package.conan_recipe) }
      else
        it { is_expected.to be_blank }
      end
    end

    context 'does not return non-matching packages' do
      let(:params) { { q: "foo" } }

      it { is_expected.to be_blank }
    end

    context 'returns error when search term is too long' do
      let(:params) { { q: 'q' * 201 } }

      before do
        get api(url), params: params
      end

      it { expect(response).to have_gitlab_http_status(:bad_request) }

      it 'returns an error message' do
        expect(json_response['message']).to eq('400 Bad request - Search term length must be less than 200 characters.')
      end
    end

    context 'returns error when search term has too many wildcards' do
      let(:params) { { q: 'al*h*/*@*nn*/*' } }

      before do
        get api(url), params: params
      end

      it { expect(response).to have_gitlab_http_status(:bad_request) }

      it 'returns an error message' do
        expect(json_response['message']).to eq('400 Bad request - Too many wildcards in search term. Maximum is 5.')
      end
    end
  end

  context 'with a private project' do
    let(:params) { { q: "#{package.name[0, 3]}*" } }

    before do
      project.update!(visibility: 'private')
    end

    context 'with anonymous access' do
      before do
        project.team.truncate
        user.project_authorizations.delete_all

        get api(url), params: params, headers: headers
      end

      it { is_expected.to be_blank }
    end

    context 'with a guest role' do
      before do
        project.add_guest(user)

        get api(url), params: params, headers: headers
      end

      if scope == :project
        it { is_expected.to contain_exactly(package.conan_recipe) }
      else
        it { is_expected.to be_blank }
      end
    end
  end
end

RSpec.shared_examples 'conan search endpoint with access to package registry for everyone' do
  before do
    project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)

    get api(url), params: params
  end

  subject { json_response['results'] }

  context 'with a matching name' do
    let(:params) { { q: package.conan_recipe } }

    it { is_expected.to contain_exactly(package.conan_recipe) }
  end

  context 'with a * wildcard' do
    let(:params) { { q: "#{package.name[0, 3]}*" } }

    it { is_expected.to contain_exactly(package.conan_recipe) }
  end
end

RSpec.shared_examples 'conan authenticate endpoint' do
  let(:auth_token) { personal_access_token.token }
  let(:headers) do
    { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('foo', auth_token) }
  end

  subject { get api(url), headers: headers }

  it_behaves_like 'conan FIPS mode'

  context 'when using invalid token' do
    let(:auth_token) { 'invalid_token' }

    it 'responds with 401' do
      subject

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  it 'responds with 401 Unauthorized when an invalid access token is provided' do
    jwt = build_jwt(double(token: 12345), user_id: user.id)
    get api(url), headers: build_token_auth_header(jwt.encoded)

    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  it 'responds with 401 Unauthorized when the provided JWT is signed with different secret' do
    jwt = build_jwt(personal_access_token, secret: SecureRandom.base64(32))
    get api(url), headers: build_token_auth_header(jwt.encoded)

    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  it 'responds with 401 UnauthorizedOK when invalid JWT is provided' do
    get api(url), headers: build_token_auth_header('invalid-jwt')

    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  context 'when valid JWT access token is provided' do
    it 'responds with 200' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'token has valid validity time' do
      freeze_time do
        subject

        payload = JSONWebToken::HMACToken.decode(
          response.body, jwt_secret).first
        expect(payload['access_token']).to eq(personal_access_token.token)
        expect(payload['user_id']).to eq(personal_access_token.user_id)
        expect(payload['exp']).to eq(personal_access_token.expires_at.at_beginning_of_day.to_i)
      end
    end
  end

  context 'with valid job token' do
    let(:auth_token) { job_token }

    it 'responds with 200' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  context 'with valid deploy token' do
    let(:auth_token) { deploy_token.token }

    it 'responds with 200' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
    end
  end
end

RSpec.shared_examples 'conan check_credentials endpoint' do
  it_behaves_like 'conan FIPS mode' do
    subject { get api(url), headers: headers }
  end

  it 'responds with a 200 OK with PAT', :aggregate_failures do
    get api(url), headers: headers

    expect(response).to have_gitlab_http_status(:ok)
    expect(response.header['Content-Type']).to eq('text/plain')
    expect(response.body).to eq('ok')
  end

  context 'with job token' do
    let(:auth_token) { job_token }

    it 'responds with a 200 OK with job token' do
      get api(url), headers: headers

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  context 'with deploy token' do
    let(:auth_token) { deploy_token.token }

    it 'responds with a 200 OK with job token' do
      get api(url), headers: headers

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  it 'responds with a 401 Unauthorized when an invalid token is used' do
    get api(url), headers: build_token_auth_header('invalid-token')

    expect(response).to have_gitlab_http_status(:unauthorized)
  end
end

RSpec.shared_examples 'rejects invalid recipe' do
  context 'with invalid recipe path' do
    let(:recipe_path) { '../../foo++../..' }

    it 'returns 400' do
      subject

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end
end

RSpec.shared_examples 'handling validation error for package' do
  context 'with validation error' do
    before do
      allow_next_instance_of(::Packages::Conan::Package) do |instance|
        instance.errors.add(:base, 'validation error')

        allow(instance).to receive(:valid?).and_return(false)
      end
    end

    it 'returns 400' do
      subject

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']).to include('Validation failed')
    end
  end

  context 'with ActiveRecord::RecordInvalid error' do
    before do
      allow_next_instance_of(::Packages::Conan::CreatePackageFileService) do |service|
        allow(service).to receive(:execute).and_raise(ActiveRecord::RecordInvalid)
      end
    end

    it 'returns 400' do
      subject

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']).to include('Record invalid')
    end
  end
end

RSpec.shared_examples 'handling empty values for username and channel' do |success_status: :ok|
  using RSpec::Parameterized::TableSyntax

  let(:recipe_path) { "#{package.name}/#{package.version}/#{package_username}/#{channel}" }

  where(:username, :channel, :status) do
    'username' | 'channel' | success_status
    'username' | '_'       | :bad_request
    '_'        | 'channel' | :bad_request_or_not_found
    '_'        | '_'       | :success_status_or_not_found
  end

  with_them do
    let(:package_username) do
      if username == 'username'
        package.conan_metadatum.package_username
      else
        username
      end
    end

    before do
      project.add_maintainer(user) # avoid any permission issue
    end

    it 'returns the correct status code' do |example|
      project_level = example.full_description.include?('api/v4/projects')

      expected_status = case status
                        when :success_status_or_not_found
                          project_level ? success_status : :not_found
                        when :bad_request_or_not_found
                          project_level ? :bad_request : :not_found
                        else
                          status
                        end

      if expected_status == success_status
        package.conan_metadatum.update!(package_username: package_username, package_channel: channel)
      end

      subject

      expect(response).to have_gitlab_http_status(expected_status)
    end
  end
end

RSpec.shared_examples 'rejects invalid file_name' do |invalid_file_name|
  let(:file_name) { invalid_file_name }

  context 'with invalid file_name' do
    it 'returns 400' do
      subject

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end
end

RSpec.shared_examples 'rejects recipe for invalid project' do
  context 'with invalid project' do
    let(:recipe_path) { 'aa/bb/cc/dd' }
    let(:project_id) { 9999 }

    it_behaves_like 'not found request'
  end
end

RSpec.shared_examples 'empty recipe for not found package' do
  context 'with invalid recipe url' do
    let(:recipe_path) do
      format('aa/bb/%{project}/ccc',
        project: ::Packages::Conan::Metadatum.package_username_from(full_path: project.full_path))
    end

    let(:presenter) { double('::Packages::Conan::PackagePresenter') }

    before do
      allow(::Packages::Conan::PackagePresenter).to receive(:new)
        .with(package, user, package.project, any_args)
        .and_return(presenter)
    end

    it 'returns not found' do
      allow(::Packages::Conan::PackagePresenter).to receive(:new)
        .with(
          nil,
          user,
          project,
          any_args
        ).and_return(presenter)
      allow(presenter).to receive_messages(recipe_snapshot: {}, package_snapshot: {})

      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to eq("{}")
    end
  end
end

RSpec.shared_examples 'not selecting a package with the wrong type' do
  context 'with a nuget package with same name and version' do
    let(:conan_username) { ::Packages::Conan::Metadatum.package_username_from(full_path: project.full_path) }
    let(:wrong_package) { create(:nuget_package, name: "wrong", version: '1.0.0', project: project) }
    let(:recipe_path) { "#{wrong_package.name}/#{wrong_package.version}/#{conan_username}/foo" }

    it 'calls the presenter with a nil package' do
      expect(::Packages::Conan::PackagePresenter).to receive(:new)
        .with(nil, user, project, any_args)

      subject
    end
  end
end

RSpec.shared_examples 'recipe download_urls' do
  let(:recipe_path) { package.conan_recipe_path }
  let(:base_url_with_recipe_path) { "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}" }

  it_behaves_like 'enforcing read_packages job token policy'

  it 'returns the download_urls for the recipe files' do
    expected_response = {
      'conanfile.py' => "#{base_url_with_recipe_path}/0/export/conanfile.py",
      'conanmanifest.txt' => "#{base_url_with_recipe_path}/0/export/conanmanifest.txt"
    }

    subject

    expect(json_response).to eq(expected_response)
  end

  it_behaves_like 'not selecting a package with the wrong type'
end

RSpec.shared_examples 'package download_urls' do
  let(:recipe_path) { package.conan_recipe_path }
  let(:base_url_with_recipe_path) { "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}" }

  it_behaves_like 'enforcing read_packages job token policy'

  it 'returns the download_urls for the package files' do
    expected_response = {
      'conaninfo.txt' => "#{base_url_with_recipe_path}/0/package/#{conan_package_reference}/0/conaninfo.txt",
      'conanmanifest.txt' => "#{base_url_with_recipe_path}/0/package/#{conan_package_reference}/0/conanmanifest.txt",
      'conan_package.tgz' => "#{base_url_with_recipe_path}/0/package/#{conan_package_reference}/0/conan_package.tgz"
    }

    subject

    expect(json_response).to eq(expected_response)
  end

  it_behaves_like 'not selecting a package with the wrong type'
end

RSpec.shared_examples 'rejects invalid upload_url params' do
  context 'with unaccepted json format' do
    let(:params) { %w[foo bar] }

    it 'returns 400' do
      subject

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end
end

RSpec.shared_examples 'recipe snapshot endpoint' do
  subject(:request) { get api(url), headers: headers }

  it_behaves_like 'enforcing read_packages job token policy'
  it_behaves_like 'conan FIPS mode'
  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects recipe for invalid project'
  it_behaves_like 'empty recipe for not found package'
  it_behaves_like 'handling empty values for username and channel'

  context 'with existing package' do
    it 'returns a hash of files with their md5 hashes' do
      conan_file_file = package.package_files.find_by(file_name: 'conanfile.py')
      conan_manifest_file = package.package_files.find_by(file_name: 'conanmanifest.txt')

      expected_response = {
        'conanfile.py' => conan_file_file.file_md5,
        'conanmanifest.txt' => conan_manifest_file.file_md5
      }

      subject

      expect(json_response).to eq(expected_response)
    end
  end
end

RSpec.shared_examples 'package snapshot endpoint' do
  subject(:request) { get api(url), headers: headers }

  it_behaves_like 'enforcing read_packages job token policy'
  it_behaves_like 'conan FIPS mode'
  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects recipe for invalid project'
  it_behaves_like 'empty recipe for not found package'
  it_behaves_like 'handling empty values for username and channel'

  context 'with existing package' do
    it 'returns a hash of md5 values for the files' do
      expected_response = {
        'conaninfo.txt' => "12345abcde",
        'conanmanifest.txt' => "12345abcde",
        'conan_package.tgz' => "12345abcde"
      }

      subject

      expect(json_response).to eq(expected_response)
    end
  end
end

RSpec.shared_examples 'recipe download_urls endpoint' do
  it_behaves_like 'conan FIPS mode' do
    let(:recipe_path) { package.conan_recipe_path }
  end

  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects recipe for invalid project'
  it_behaves_like 'recipe download_urls'
  it_behaves_like 'handling empty values for username and channel'
end

RSpec.shared_examples 'package download_urls endpoint' do
  it_behaves_like 'conan FIPS mode' do
    let(:recipe_path) { package.conan_recipe_path }
  end

  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects recipe for invalid project'
  it_behaves_like 'package download_urls'
  it_behaves_like 'handling empty values for username and channel'
end

RSpec.shared_examples 'recipe upload_urls endpoint' do
  let(:recipe_path) { package.conan_recipe_path }
  let(:base_url_with_recipe_path) { "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}" }

  let(:params) do
    { 'conanfile.py': 24,
      'conanmanifest.txt': 123 }
  end

  it_behaves_like 'enforcing read_packages job token policy'
  it_behaves_like 'conan FIPS mode'
  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects invalid upload_url params'
  it_behaves_like 'handling empty values for username and channel'

  it 'returns a set of upload urls for the files requested' do
    subject

    expected_response = {
      'conanfile.py': "#{base_url_with_recipe_path}/0/export/conanfile.py",
      'conanmanifest.txt': "#{base_url_with_recipe_path}/0/export/conanmanifest.txt"
    }

    expect(response.body).to eq(expected_response.to_json)
  end

  context 'with conan_sources and conan_export files' do
    let(:params) do
      { 'conan_sources.tgz': 345,
        'conan_export.tgz': 234,
        'conanmanifest.txt': 123 }
    end

    it 'returns upload urls for the additional files' do
      subject

      expected_response = {
        'conan_sources.tgz': "#{base_url_with_recipe_path}/0/export/conan_sources.tgz",
        'conan_export.tgz': "#{base_url_with_recipe_path}/0/export/conan_export.tgz",
        'conanmanifest.txt': "#{base_url_with_recipe_path}/0/export/conanmanifest.txt"
      }

      expect(response.body).to eq(expected_response.to_json)
    end
  end

  context 'with an invalid file' do
    let(:params) do
      { 'invalid_file.txt': 10,
        'conanmanifest.txt': 123 }
    end

    it 'does not return the invalid file as an upload_url' do
      subject

      expected_response = {
        'conanmanifest.txt': "#{base_url_with_recipe_path}/0/export/conanmanifest.txt"
      }

      expect(response.body).to eq(expected_response.to_json)
    end
  end
end

RSpec.shared_examples 'package upload_urls endpoint' do
  let(:recipe_path) { package.conan_recipe_path }
  let(:base_url_with_recipe_path) { "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}" }

  let(:params) do
    { 'conaninfo.txt': 24,
      'conanmanifest.txt': 123,
      'conan_package.tgz': 523 }
  end

  it_behaves_like 'enforcing read_packages job token policy'
  it_behaves_like 'conan FIPS mode'
  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects invalid upload_url params'
  it_behaves_like 'handling empty values for username and channel'

  it 'returns a set of upload urls for the files requested' do
    expected_response = {
      'conaninfo.txt': "#{base_url_with_recipe_path}/0/package/123456789/0/conaninfo.txt",
      'conanmanifest.txt': "#{base_url_with_recipe_path}/0/package/123456789/0/conanmanifest.txt",
      'conan_package.tgz': "#{base_url_with_recipe_path}/0/package/123456789/0/conan_package.tgz"
    }

    subject

    expect(response.body).to eq(expected_response.to_json)
  end

  context 'with invalid files' do
    let(:params) do
      { 'conaninfo.txt': 24,
        'invalid_file.txt': 10 }
    end

    it 'returns upload urls only for the valid requested files' do
      expected_response = {
        'conaninfo.txt': "#{base_url_with_recipe_path}/0/package/123456789/0/conaninfo.txt"
      }

      subject

      expect(response.body).to eq(expected_response.to_json)
    end
  end
end

RSpec.shared_examples 'delete package endpoint' do
  let(:recipe_path) { package.conan_recipe_path }

  it_behaves_like 'conan FIPS mode'
  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'handling empty values for username and channel'

  it 'returns unauthorized for users without valid permission' do
    subject

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  context 'with delete permissions' do
    before do
      project.add_maintainer(user)
    end

    it_behaves_like 'enforcing job token policies', :admin_packages do
      let(:headers) { job_basic_auth_header(target_job) }
    end

    it 'triggers an internal event' do
      expect { subject }
        .to trigger_internal_events('delete_package_from_registry')
          .with(user: user, project: project, property: 'user', label: 'conan', category: 'InternalEventTracking')
    end

    it 'deletes a package' do
      expect { subject }.to change { Packages::Package.count }.by(-1)
    end
  end
end

RSpec.shared_examples 'allows download with no token' do
  context 'with no private token' do
    let(:headers) { {} }

    it 'returns 200' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
    end
  end
end

RSpec.shared_examples 'denies download with no token' do
  context 'with no private token' do
    let(:headers) { {} }

    it 'returns 404' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end

RSpec.shared_examples 'a public project with packages' do
  before do
    project.update_column(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
  end

  it_behaves_like 'allows download with no token'
  it_behaves_like 'bumping the package last downloaded at field'

  it 'returns the file' do
    subject

    expect(response).to have_gitlab_http_status(:ok)
    expect(response.media_type).to eq('application/octet-stream')
  end
end

RSpec.shared_examples 'an internal project with packages' do
  before do
    project.team.truncate
    project.update_column(:visibility_level, Gitlab::VisibilityLevel::INTERNAL)
  end

  it_behaves_like 'denies download with no token'
  it_behaves_like 'bumping the package last downloaded at field'

  it 'returns the file' do
    subject

    expect(response).to have_gitlab_http_status(:ok)
    expect(response.media_type).to eq('application/octet-stream')
  end
end

RSpec.shared_examples 'a private project with packages' do
  before do
    project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
  end

  it_behaves_like 'enforcing read_packages job token policy'
  it_behaves_like 'denies download with no token'
  it_behaves_like 'bumping the package last downloaded at field'

  it 'returns the file' do
    subject

    expect(response).to have_gitlab_http_status(:ok)
    expect(response.media_type).to eq('application/octet-stream')
  end

  context 'when allow_guest_plus_roles_to_pull_packages is disabled' do
    before do
      stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
    end

    it 'denies download when not enough permissions' do
      project.add_guest(user)

      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end
end

RSpec.shared_examples 'not found request' do
  it 'returns not found' do
    subject

    expect(response).to have_gitlab_http_status(:not_found)
  end
end

RSpec.shared_examples 'recipe file download endpoint' do
  it_behaves_like 'conan FIPS mode'
  it_behaves_like 'a public project with packages'
  it_behaves_like 'an internal project with packages'
  it_behaves_like 'a private project with packages'
  it_behaves_like 'handling empty values for username and channel'
  it_behaves_like 'package not found'
end

RSpec.shared_examples 'package file download endpoint' do
  it_behaves_like 'conan FIPS mode'
  it_behaves_like 'a public project with packages'
  it_behaves_like 'an internal project with packages'
  it_behaves_like 'a private project with packages'
  it_behaves_like 'handling empty values for username and channel'
  it_behaves_like 'package not found'

  context 'tracking the conan_package.tgz download' do
    let(:package_file) { package.package_files.find_by(file_name: ::Packages::Conan::FileMetadatum::PACKAGE_BINARY) }

    it_behaves_like 'a package tracking event', 'API::ConanPackages', 'pull_package'
  end
end

RSpec.shared_examples 'project not found by recipe' do
  let(:recipe_path) { 'not/package/for/project' }

  it_behaves_like 'not found request'
end

RSpec.shared_examples 'project not found by project id' do
  let(:project_id) { 99999 }

  it_behaves_like 'not found request'
end

RSpec.shared_examples 'workhorse authorize endpoint' do
  it_behaves_like 'enforcing admin_packages job token policy'
  it_behaves_like 'conan FIPS mode'
  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects invalid file_name', 'conanfile.py.git%2fgit-upload-pack'
  it_behaves_like 'workhorse authorization'
  it_behaves_like 'handling empty values for username and channel'
end

RSpec.shared_examples 'protected package main example' do
  context 'with package protection rule for different roles and package_name_patterns', :enable_admin_mode do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:pat_project_developer) { personal_access_token }
    let_it_be(:pat_project_maintainer) { create(:personal_access_token, user: create(:user, maintainer_of: [project])) }
    let_it_be(:pat_project_owner) { create(:personal_access_token, user: create(:user, owner_of: [project])) }
    let_it_be(:pat_instance_admin) { create(:personal_access_token, :admin_mode, user: create(:admin)) }

    let(:package_protection_rule) do
      create(:package_protection_rule, package_type: :conan, project: project)
    end

    let(:conan_package_name) { recipe_path_name }
    let(:conan_package_name_no_match) { "#{conan_package_name}_no_match" }

    before do
      package_protection_rule.update!(
        package_name_pattern: package_name_pattern,
        minimum_access_level_for_push: minimum_access_level_for_push
      )
    end

    shared_examples 'protected package' do
      it_behaves_like 'returning response status', 403

      it 'does not create any conan-related package records' do
        expect { subject }
          .to not_change { Packages::Package.count }
          .and not_change { Packages::Package.conan.count }
          .and not_change { Packages::PackageFile.count }
      end
    end

    where(:package_name_pattern, :minimum_access_level_for_push, :personal_access_token, :shared_examples_name) do
      ref(:conan_package_name)          | :maintainer | ref(:pat_project_developer)  | 'protected package'
      ref(:conan_package_name)          | :maintainer | ref(:pat_project_owner)      | 'uploads a package file'
      ref(:conan_package_name)          | :maintainer | ref(:pat_instance_admin)     | 'uploads a package file'
      ref(:conan_package_name)          | :owner      | ref(:pat_project_maintainer) | 'protected package'
      ref(:conan_package_name)          | :owner      | ref(:pat_project_owner)      | 'uploads a package file'
      ref(:conan_package_name)          | :owner      | ref(:pat_instance_admin)     | 'uploads a package file'
      ref(:conan_package_name)          | :admin      | ref(:pat_project_owner)      | 'protected package'
      ref(:conan_package_name)          | :admin      | ref(:pat_instance_admin)     | 'uploads a package file'
      ref(:conan_package_name_no_match) | :maintainer | ref(:pat_project_owner)      | 'uploads a package file'
      ref(:conan_package_name_no_match) | :admin      | ref(:pat_project_owner)      | 'uploads a package file'
    end

    with_them do
      it_behaves_like params[:shared_examples_name]
    end
  end
end

RSpec.shared_examples 'workhorse recipe file upload endpoint' do |revision: false|
  let(:file_name) { 'conanfile.py' }
  let(:params) { { file: temp_file(file_name) } }

  subject(:request) do
    workhorse_finalize(
      api(url),
      method: :put,
      file_key: :file,
      params: params,
      headers: headers_with_token,
      send_rewritten_field: true
    )
  end

  it_behaves_like 'enforcing admin_packages job token policy'
  it_behaves_like 'conan FIPS mode'
  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects invalid file_name', 'conanfile.py.git%2fgit-upload-pack'
  it_behaves_like 'uploads a package file'
  it_behaves_like 'creates build_info when there is a job'
  it_behaves_like 'handling empty values for username and channel'
  it_behaves_like 'handling validation error for package'
  it_behaves_like 'protected package main example'

  if revision
    it { expect { request }.to change { Packages::Conan::RecipeRevision.count }.by(1) }

    context 'when the file already exists' do
      let(:recipe_revision) { package.conan_recipe_revisions.first.revision }
      let(:recipe_path_name) { package.name }

      it 'does not upload the file again' do
        expect { request }.not_to change { Packages::PackageFile.count }
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({
          'message' => '400 Bad request - Validation failed: ' \
            'File name already exists for the given recipe revision, package reference, and package revision'
        })
      end
    end
  end
end

RSpec.shared_examples 'workhorse package file upload endpoint' do |revision: false|
  let(:file_name) { 'conaninfo.txt' }
  let(:params) { { file: temp_file(file_name) } }

  subject(:request) do
    workhorse_finalize(
      api(url),
      method: :put,
      file_key: :file,
      params: params,
      headers: headers_with_token,
      send_rewritten_field: true
    )
  end

  it_behaves_like 'enforcing admin_packages job token policy'
  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects invalid file_name', 'conaninfo.txttest'
  it_behaves_like 'uploads a package file'
  it_behaves_like 'creates build_info when there is a job'
  it_behaves_like 'handling empty values for username and channel'
  it_behaves_like 'handling validation error for package'
  it_behaves_like 'protected package main example'

  if revision
    it 'creates a recipe and package revision' do
      expect { request }
        .to change { Packages::Conan::RecipeRevision.count }.by(1)
        .and change { Packages::Conan::PackageRevision.count }.by(1)
    end

    context 'when the file already exists' do
      let(:recipe_revision) { package.conan_recipe_revisions.first.revision }
      let(:package_revision) { package.conan_package_revisions.first.revision }
      let(:conan_package_reference) { package.conan_package_references.first.reference }
      let(:recipe_path_name) { package.name }

      it 'does not upload the file again' do
        expect { request }.not_to change { Packages::PackageFile.count }
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({
          'message' => '400 Bad request - Validation failed: ' \
            'File name already exists for the given recipe revision, package reference, and package revision'
        })
      end
    end
  end

  it { expect { request }.to change { Packages::Conan::PackageReference.count }.by(1) }

  context 'tracking the conan_package.tgz upload' do
    let(:file_name) { ::Packages::Conan::FileMetadatum::PACKAGE_BINARY }

    it_behaves_like 'a package tracking event', 'API::ConanPackages', 'push_package'
  end
end

RSpec.shared_examples 'creates build_info when there is a job' do
  context 'with job token' do
    let(:jwt) { build_jwt_from_job(job) }

    it 'creates a build_info record' do
      expect { subject }.to change { Packages::BuildInfo.count }.by(1)
    end

    it 'creates a package_file_build_info record' do
      expect { subject }.to change { Packages::PackageFileBuildInfo.count }.by(1)
    end
  end
end

RSpec.shared_examples 'uploads a package file' do
  context 'file size above maximum limit' do
    before do
      params['file.size'] = project.actual_limits.conan_max_file_size + 1
    end

    it 'handles as a local file' do
      subject

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  context 'with object storage disabled' do
    context 'without a file from workhorse' do
      let(:params) { { file: nil } }

      it 'rejects the request' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with a file' do
      it_behaves_like 'package workhorse uploads'
    end

    context 'without a token' do
      it 'rejects request without a token' do
        headers_with_token.delete('HTTP_AUTHORIZATION')

        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when params from workhorse are correct' do
      it 'creates package and stores package file' do
        expect { subject }
          .to change { project.packages.count }.by(1)
          .and change { Packages::PackageFile.count }.by(1)

        expect(response).to have_gitlab_http_status(:ok)

        package_file = project.packages.last.package_files.reload.last
        expect(package_file.file_name).to eq(params[:file].original_filename)
        expect(package_file.conan_file_metadatum.recipe_revision_value).to eq(recipe_revision)
        expect(package_file.conan_file_metadatum.package_reference_value).to eq(
          package_file.conan_file_metadatum.package_file? ? conan_package_reference : nil
        )
        expect(package_file.conan_file_metadatum.package_revision_value).to eq(
          package_file.conan_file_metadatum.package_file? ? package_revision : nil
        )
      end

      context 'with X-Checksum-Deploy header' do
        context 'when X-Checksum-Deploy header is "true"' do
          before do
            headers_with_token['X-Checksum-Deploy'] = 'true'
          end

          it 'returns not found without creating package or package file' do
            expect { subject }
              .to not_change { project.packages.count }
              .and not_change { Packages::PackageFile.count }

            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response['message']).to eq('404 Non checksum storage Not Found')
          end
        end

        context 'when X-Checksum-Deploy header has other value' do
          before do
            headers_with_token['X-Checksum-Deploy'] = 'false'
          end

          it 'creates package and stores package file' do
            expect { subject }
              .to change { project.packages.count }.by(1)
              .and change { Packages::PackageFile.count }.by(1)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context 'with existing package' do
        let!(:existing_package) do
          create(:conan_package, name: recipe_path_name, version: recipe_path_version, project: project)
        end

        before do
          existing_package.conan_metadatum.update!(package_username: recipe_path_username,
            package_channel: recipe_path_channel)
        end

        it 'does not create a new package' do
          expect { subject }
            .to not_change { project.packages.count }
            .and not_change { Packages::Conan::Metadatum.count }
            .and change { Packages::PackageFile.count }.by(1)
        end

        context 'marked as pending_destruction' do
          it 'does not create a new package' do
            existing_package.pending_destruction!

            expect { subject }
              .to change { project.packages.count }.by(1)
              .and change { Packages::Conan::Metadatum.count }.by(1)
              .and change { Packages::PackageFile.count }.by(1)
          end
        end
      end
    end
  end

  context 'with object storage enabled' do
    context 'and direct upload enabled' do
      let!(:fog_connection) do
        stub_package_file_object_storage(direct_upload: true)
      end

      let(:tmp_object) do
        fog_connection.directories.new(key: 'packages').files.create( # rubocop:disable Rails/SaveBang -- Method #create! is undefined for class Fog::AWS::Storage::Files
          key: "tmp/uploads/#{file_name}",
          body: 'content'
        )
      end

      let(:fog_file) { fog_to_uploaded_file(tmp_object) }

      ['123123', '../../123123'].each do |remote_id|
        context "with invalid remote_id: #{remote_id}" do
          let(:params) do
            {
              file: fog_file,
              'file.remote_id' => remote_id
            }
          end

          it 'responds with status 403' do
            subject

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end

      context 'with valid remote_id' do
        let(:params) do
          {
            file: fog_file,
            'file.remote_id' => file_name
          }
        end

        it 'creates package and stores package file' do
          expect { subject }
            .to change { project.packages.count }.by(1)
            .and change { Packages::PackageFile.count }.by(1)

          expect(response).to have_gitlab_http_status(:ok)

          package_file = project.packages.last.package_files.reload.last
          expect(package_file.file_name).to eq(params[:file].original_filename)
          expect(package_file.file.read).to eq('content')
        end
      end
    end
  end
end

RSpec.shared_examples 'workhorse authorization' do
  it 'authorizes posting package with a valid token' do
    subject

    expect(response).to have_gitlab_http_status(:ok)
    expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
  end

  it 'rejects request without a valid token' do
    headers_with_token['HTTP_AUTHORIZATION'] = 'foo'

    subject

    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  it 'rejects request without a valid permission' do
    project.add_guest(user)

    subject

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  it 'rejects requests that bypassed gitlab-workhorse' do
    headers_with_token.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER)

    subject

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  context 'when using remote storage' do
    context 'when direct upload is enabled' do
      before do
        stub_package_file_object_storage(enabled: true, direct_upload: true)
      end

      it 'responds with status 200, location of package remote store and object details' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
        expect(json_response).not_to have_key('TempPath')
        expect(json_response['RemoteObject']).to have_key('ID')
        expect(json_response['RemoteObject']).to have_key('GetURL')
        expect(json_response['RemoteObject']).to have_key('StoreURL')
        expect(json_response['RemoteObject']).to have_key('DeleteURL')
        expect(json_response['RemoteObject']).not_to have_key('MultipartUpload')
      end
    end

    context 'when direct upload is disabled' do
      before do
        stub_package_file_object_storage(enabled: true, direct_upload: false)
      end

      it 'handles as a local file' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
        expect(json_response['TempPath']).to eq(::Packages::PackageFileUploader.workhorse_local_upload_path)
        expect(json_response['RemoteObject']).to be_nil
      end
    end
  end
end

RSpec.shared_examples 'conan FIPS mode' do
  context 'when FIPS mode is enabled', :fips_mode do
    it_behaves_like 'returning response status', :not_found
  end
end

RSpec.shared_examples 'enforcing admin_packages job token policy' do
  it_behaves_like 'enforcing job token policies', :admin_packages do
    let(:headers_with_token) { job_basic_auth_header(target_job).merge(workhorse_headers) }
  end
end

RSpec.shared_examples 'accept get request on private project with access to package registry for everyone' do
  subject { get api(url) }

  before do
    project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
  end

  it_behaves_like 'returning response status', :ok
end

RSpec.shared_examples 'package not found' do
  context 'when package does not exist' do
    let(:recipe_path) { "missing/0.1.0/#{project.full_path.tr('/', '+')}/stable" }

    it 'returns 404 not found' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Package Not Found')
    end
  end
end

RSpec.shared_examples 'packages feature check' do
  before do
    stub_packages_setting(enabled: false)
  end

  it_behaves_like 'returning response status', :not_found
end

RSpec.shared_examples 'GET package references metadata endpoint' do |with_recipe_revision: false|
  subject(:request) { get api(url), headers: headers }

  let_it_be(:reference1) { package.conan_package_references.first }

  let_it_be(:reference2) do
    create(:conan_package_reference, package: package, info: { 'settings' => { 'os' => 'Linux' } })
  end

  it_behaves_like 'conan FIPS mode'
  it_behaves_like 'packages feature check'
  it_behaves_like 'handling empty values for username and channel'
  it_behaves_like 'package not found'
  it_behaves_like 'enforcing read_packages job token policy'

  context 'When the project is public' do
    before do
      project.update_column(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
    end

    it_behaves_like 'allows download with no token'
  end

  context 'When the project is internal' do
    before do
      project.team.truncate
      project.update_column(:visibility_level, Gitlab::VisibilityLevel::INTERNAL)
    end

    it_behaves_like 'denies download with no token'
  end

  context 'When the project is private' do
    before do
      project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'returns success with package references metadata', :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include(
        reference1.reference => reference1.info,
        reference2.reference => reference2.info
      )
    end

    it_behaves_like 'denies download with no token'

    context 'when allow_guest_plus_roles_to_pull_packages is disabled' do
      before do
        stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
      end

      it 'denies download when not enough permissions' do
        project.add_guest(user)

        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  if with_recipe_revision
    context 'when recipe revision does not exist' do
      let(:recipe_revision) { OpenSSL::Digest.hexdigest('MD5', 'nonexistent-revision') }

      it_behaves_like 'returning response status with message', status: :not_found,
        message: '404 Revision Not Found'
    end

    context 'with different recipe revisions' do
      let_it_be(:recipe_revision2) { create(:conan_recipe_revision, package: package) }
      let_it_be(:reference2) do
        create(:conan_package_reference, package: package, info: { 'settings' => { 'os' => 'Linux' } },
          recipe_revision: recipe_revision2)
      end

      it 'returns only the package references for the requested recipe revision' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include(
          reference1.reference => reference1.info
        )
      end
    end
  end
end
