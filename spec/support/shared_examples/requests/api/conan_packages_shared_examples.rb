# frozen_string_literal: true

RSpec.shared_examples 'conan ping endpoint' do
  it 'responds with 200 OK when no token provided' do
    get api(url)

    expect(response).to have_gitlab_http_status(:ok)
    expect(response.headers['X-Conan-Server-Capabilities']).to eq("")
  end

  context 'packages feature disabled' do
    it 'responds with 404 Not Found' do
      stub_packages_setting(enabled: false)
      get api(url)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end

RSpec.shared_examples 'conan search endpoint' do
  before do
    project.update_column(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)

    # Do not pass the HTTP_AUTHORIZATION header,
    # in order to test that this public project's packages
    # are visible to anonymous search.
    get api(url), params: params
  end

  subject { json_response['results'] }

  context 'returns packages with a matching name' do
    let(:params) { { q: package.conan_recipe } }

    it { is_expected.to contain_exactly(package.conan_recipe) }
  end

  context 'returns packages using a * wildcard' do
    let(:params) { { q: "#{package.name[0, 3]}*" } }

    it { is_expected.to contain_exactly(package.conan_recipe) }
  end

  context 'does not return non-matching packages' do
    let(:params) { { q: "foo" } }

    it { is_expected.to be_blank }
  end
end

RSpec.shared_examples 'conan authenticate endpoint' do
  subject { get api(url), headers: headers }

  context 'when using invalid token' do
    let(:auth_token) { 'invalid_token' }

    it 'responds with 401' do
      subject

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  it 'responds with 401 Unauthorized when an invalid access token ID is provided' do
    jwt = build_jwt(double(id: 12345), user_id: personal_access_token.user_id)
    get api(url), headers: build_token_auth_header(jwt.encoded)

    expect(response).to have_gitlab_http_status(:unauthorized)
  end

  it 'responds with 401 Unauthorized when invalid user is provided' do
    jwt = build_jwt(personal_access_token, user_id: 12345)
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
        expect(payload['access_token']).to eq(personal_access_token.id)
        expect(payload['user_id']).to eq(personal_access_token.user_id)

        duration = payload['exp'] - payload['iat']
        expect(duration).to eq(::Gitlab::ConanToken::CONAN_TOKEN_EXPIRE_TIME)
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
  it 'responds with a 200 OK with PAT' do
    get api(url), headers: headers

    expect(response).to have_gitlab_http_status(:ok)
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
      'aa/bb/%{project}/ccc' % { project: ::Packages::Conan::Metadatum.package_username_from(full_path: project.full_path) }
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
      allow(presenter).to receive(:recipe_snapshot) { {} }
      allow(presenter).to receive(:package_snapshot) { {} }

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

  it 'returns the download_urls for the recipe files' do
    expected_response = {
      'conanfile.py'      => "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}/0/export/conanfile.py",
      'conanmanifest.txt' => "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}/0/export/conanmanifest.txt"
    }

    subject

    expect(json_response).to eq(expected_response)
  end

  it_behaves_like 'not selecting a package with the wrong type'
end

RSpec.shared_examples 'package download_urls' do
  let(:recipe_path) { package.conan_recipe_path }

  it 'returns the download_urls for the package files' do
    expected_response = {
      'conaninfo.txt'     => "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/123456789/0/conaninfo.txt",
      'conanmanifest.txt' => "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/123456789/0/conanmanifest.txt",
      'conan_package.tgz' => "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/123456789/0/conan_package.tgz"
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
  subject { get api(url), headers: headers }

  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects recipe for invalid project'
  it_behaves_like 'empty recipe for not found package'

  context 'with existing package' do
    it 'returns a hash of files with their md5 hashes' do
      conan_file_file = package.package_files.find_by(file_name: 'conanfile.py')
      conan_manifest_file = package.package_files.find_by(file_name: 'conanmanifest.txt')

      expected_response = {
        'conanfile.py'      => conan_file_file.file_md5,
        'conanmanifest.txt' => conan_manifest_file.file_md5
      }

      subject

      expect(json_response).to eq(expected_response)
    end
  end
end

RSpec.shared_examples 'package snapshot endpoint' do
  subject { get api(url), headers: headers }

  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects recipe for invalid project'
  it_behaves_like 'empty recipe for not found package'

  context 'with existing package' do
    it 'returns a hash of md5 values for the files' do
      expected_response = {
        'conaninfo.txt'     => "12345abcde",
        'conanmanifest.txt' => "12345abcde",
        'conan_package.tgz' => "12345abcde"
      }

      subject

      expect(json_response).to eq(expected_response)
    end
  end
end

RSpec.shared_examples 'recipe download_urls endpoint' do
  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects recipe for invalid project'
  it_behaves_like 'recipe download_urls'
end

RSpec.shared_examples 'package download_urls endpoint' do
  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects recipe for invalid project'
  it_behaves_like 'package download_urls'
end

RSpec.shared_examples 'recipe upload_urls endpoint' do
  let(:recipe_path) { package.conan_recipe_path }

  let(:params) do
    { 'conanfile.py': 24,
      'conanmanifest.txt': 123 }
  end

  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects invalid upload_url params'

  it 'returns a set of upload urls for the files requested' do
    subject

    expected_response = {
      'conanfile.py':      "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}/0/export/conanfile.py",
      'conanmanifest.txt': "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}/0/export/conanmanifest.txt"
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
        'conan_sources.tgz': "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}/0/export/conan_sources.tgz",
        'conan_export.tgz':  "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}/0/export/conan_export.tgz",
        'conanmanifest.txt': "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}/0/export/conanmanifest.txt"
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
        'conanmanifest.txt': "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}/0/export/conanmanifest.txt"
      }

      expect(response.body).to eq(expected_response.to_json)
    end
  end
end

RSpec.shared_examples 'package upload_urls endpoint' do
  let(:recipe_path) { package.conan_recipe_path }

  let(:params) do
    { 'conaninfo.txt': 24,
      'conanmanifest.txt': 123,
      'conan_package.tgz': 523 }
  end

  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects invalid upload_url params'

  it 'returns a set of upload urls for the files requested' do
    expected_response = {
      'conaninfo.txt':     "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/123456789/0/conaninfo.txt",
      'conanmanifest.txt': "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/123456789/0/conanmanifest.txt",
      'conan_package.tgz': "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/123456789/0/conan_package.tgz"
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
        'conaninfo.txt': "#{url_prefix}/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/123456789/0/conaninfo.txt"
      }

      subject

      expect(response.body).to eq(expected_response.to_json)
    end
  end
end

RSpec.shared_examples 'delete package endpoint' do
  let(:recipe_path) { package.conan_recipe_path }

  it_behaves_like 'rejects invalid recipe'

  it 'returns unauthorized for users without valid permission' do
    subject

    expect(response).to have_gitlab_http_status(:forbidden)
  end

  context 'with delete permissions' do
    before do
      project.add_maintainer(user)
    end

    it_behaves_like 'a gitlab tracking event', 'API::ConanPackages', 'delete_package'

    it 'deletes a package' do
      expect { subject }.to change { Packages::Package.count }.from(2).to(1)
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

  it_behaves_like 'denies download with no token'

  it 'returns the file' do
    subject

    expect(response).to have_gitlab_http_status(:ok)
    expect(response.media_type).to eq('application/octet-stream')
  end

  it 'denies download when not enough permissions' do
    project.add_guest(user)

    subject

    expect(response).to have_gitlab_http_status(:forbidden)
  end
end

RSpec.shared_examples 'not found request' do
  it 'returns not found' do
    subject

    expect(response).to have_gitlab_http_status(:not_found)
  end
end

RSpec.shared_examples 'recipe file download endpoint' do
  it_behaves_like 'a public project with packages'
  it_behaves_like 'an internal project with packages'
  it_behaves_like 'a private project with packages'
end

RSpec.shared_examples 'package file download endpoint' do
  it_behaves_like 'a public project with packages'
  it_behaves_like 'an internal project with packages'
  it_behaves_like 'a private project with packages'

  context 'tracking the conan_package.tgz download' do
    let(:package_file) { package.package_files.find_by(file_name: ::Packages::Conan::FileMetadatum::PACKAGE_BINARY) }

    it_behaves_like 'a gitlab tracking event', 'API::ConanPackages', 'pull_package'
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
  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects invalid file_name', 'conanfile.py.git%2fgit-upload-pack'
  it_behaves_like 'workhorse authorization'
end

RSpec.shared_examples 'workhorse recipe file upload endpoint' do
  let(:file_name) { 'conanfile.py' }
  let(:params) { { file: temp_file(file_name) } }

  subject do
    workhorse_finalize(
      url,
      method: :put,
      file_key: :file,
      params: params,
      headers: headers_with_token,
      send_rewritten_field: true
    )
  end

  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects invalid file_name', 'conanfile.py.git%2fgit-upload-pack'
  it_behaves_like 'uploads a package file'
  it_behaves_like 'creates build_info when there is a job'
end

RSpec.shared_examples 'workhorse package file upload endpoint' do
  let(:file_name) { 'conaninfo.txt' }
  let(:params) { { file: temp_file(file_name) } }

  subject do
    workhorse_finalize(
      url,
      method: :put,
      file_key: :file,
      params: params,
      headers: headers_with_token,
      send_rewritten_field: true
    )
  end

  it_behaves_like 'rejects invalid recipe'
  it_behaves_like 'rejects invalid file_name', 'conaninfo.txttest'
  it_behaves_like 'uploads a package file'
  it_behaves_like 'creates build_info when there is a job'

  context 'tracking the conan_package.tgz upload' do
    let(:file_name) { ::Packages::Conan::FileMetadatum::PACKAGE_BINARY }

    it_behaves_like 'a gitlab tracking event', 'API::ConanPackages', 'push_package'
  end
end

RSpec.shared_examples 'creates build_info when there is a job' do
  context 'with job token', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/294047' do
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
      end

      it "doesn't attempt to migrate file to object storage" do
        expect(ObjectStorage::BackgroundMoveWorker).not_to receive(:perform_async)

        subject
      end
    end
  end

  context 'with object storage enabled' do
    context 'and direct upload enabled' do
      let!(:fog_connection) do
        stub_package_file_object_storage(direct_upload: true)
      end

      let(:tmp_object) do
        fog_connection.directories.new(key: 'packages').files.create( # rubocop:disable Rails/SaveBang
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

    it_behaves_like 'background upload schedules a file migration'
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
