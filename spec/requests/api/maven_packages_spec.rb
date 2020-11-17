# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::MavenPackages do
  include WorkhorseHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :public, namespace: group) }
  let_it_be(:package, reload: true) { create(:maven_package, project: project, name: project.full_path) }
  let_it_be(:maven_metadatum, reload: true) { package.maven_metadatum }
  let_it_be(:package_file) { package.package_files.with_file_name_like('%.xml').first }
  let_it_be(:jar_file) { package.package_files.with_file_name_like('%.jar').first }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:job, reload: true) { create(:ci_build, user: user, status: :running) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }
  let_it_be(:deploy_token_for_group) { create(:deploy_token, :group, read_package_registry: true, write_package_registry: true) }
  let_it_be(:group_deploy_token) { create(:group_deploy_token, deploy_token: deploy_token_for_group, group: group) }

  let(:workhorse_token) { JWT.encode({ 'iss' => 'gitlab-workhorse' }, Gitlab::Workhorse.secret, 'HS256') }
  let(:headers) { { 'GitLab-Workhorse' => '1.0', Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER => workhorse_token } }
  let(:headers_with_token) { headers.merge('Private-Token' => personal_access_token.token) }
  let(:group_deploy_token_headers) { { Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => deploy_token_for_group.token } }

  let(:headers_with_deploy_token) do
    headers.merge(
      Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => deploy_token.token
    )
  end

  let(:version) { '1.0-SNAPSHOT' }

  before do
    project.add_developer(user)
  end

  shared_examples 'tracking the file download event' do
    context 'with jar file' do
      let_it_be(:package_file) { jar_file }

      it_behaves_like 'a package tracking event', described_class.name, 'pull_package'
    end
  end

  shared_examples 'processing HEAD requests' do
    subject { head api(url) }

    before do
      allow_any_instance_of(::Packages::PackageFileUploader).to receive(:fog_credentials).and_return(object_storage_credentials)
      stub_package_file_object_storage(enabled: object_storage_enabled)
    end

    context 'with object storage enabled' do
      let(:object_storage_enabled) { true }

      before do
        allow_any_instance_of(::Packages::PackageFileUploader).to receive(:file_storage?).and_return(false)
      end

      context 'non AWS provider' do
        let(:object_storage_credentials) { { provider: 'Google' } }

        it 'does not generated a signed url for head' do
          expect_any_instance_of(Fog::AWS::Storage::Files).not_to receive(:head_url)

          subject
        end
      end

      context 'with AWS provider' do
        let(:object_storage_credentials) { { provider: 'AWS', aws_access_key_id: 'test', aws_secret_access_key: 'test' } }

        it 'generates a signed url for head' do
          expect_any_instance_of(Fog::AWS::Storage::Files).to receive(:head_url).and_call_original

          subject
        end
      end
    end

    context 'with object storage disabled' do
      let(:object_storage_enabled) { false }
      let(:object_storage_credentials) { {} }

      it 'does not generate a signed url for head' do
        expect_any_instance_of(Fog::AWS::Storage::Files).not_to receive(:head_url)

        subject
      end
    end
  end

  shared_examples 'downloads with a deploy token' do
    context 'successful download' do
      subject do
        download_file(
          package_file.file_name,
          {},
          Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => deploy_token.token
        )
      end

      it 'allows download with deploy token' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end

      it 'allows download with deploy token with only write_package_registry scope' do
        deploy_token.update!(read_package_registry: false)

        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end
    end
  end

  shared_examples 'downloads with a job token' do
    context 'with a running job' do
      it 'allows download with job token' do
        download_file(package_file.file_name, job_token: job.token)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end
    end

    context 'with a finished job' do
      before do
        job.update!(status: :failed)
      end

      it 'returns unauthorized error' do
        download_file(package_file.file_name, job_token: job.token)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v4/packages/maven/*path/:file_name' do
    context 'a public project' do
      subject { download_file(package_file.file_name) }

      it_behaves_like 'tracking the file download event'

      it 'returns the file' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end

      it 'returns sha1 of the file' do
        download_file(package_file.file_name + '.sha1')

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('text/plain')
        expect(response.body).to eq(package_file.file_sha1)
      end
    end

    context 'internal project' do
      before do
        project.team.truncate
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      end

      subject { download_file_with_token(package_file.file_name) }

      it_behaves_like 'tracking the file download event'

      it 'returns the file' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end

      it 'denies download when no private token' do
        download_file(package_file.file_name)

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it_behaves_like 'downloads with a job token'

      it_behaves_like 'downloads with a deploy token'
    end

    context 'private project' do
      subject { download_file_with_token(package_file.file_name) }

      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it_behaves_like 'tracking the file download event'

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

      it 'denies download when no private token' do
        download_file(package_file.file_name)

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it_behaves_like 'downloads with a job token'

      it_behaves_like 'downloads with a deploy token'

      it 'does not allow download by a unauthorized deploy token with same id as a user with access' do
        unauthorized_deploy_token = create(:deploy_token, read_package_registry: true, write_package_registry: true)

        another_user = create(:user)
        project.add_developer(another_user)

        # We force the id of the deploy token and the user to be the same
        unauthorized_deploy_token.update!(id: another_user.id)

        download_file(
          package_file.file_name,
          {},
          Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => unauthorized_deploy_token.token
        )

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'project name is different from a package name' do
      before do
        maven_metadatum.update!(path: "wrong_name/#{package.version}")
      end

      it 'rejects request' do
        download_file(package_file.file_name)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    def download_file(file_name, params = {}, request_headers = headers)
      get api("/packages/maven/#{maven_metadatum.path}/#{file_name}"), params: params, headers: request_headers
    end

    def download_file_with_token(file_name, params = {}, request_headers = headers_with_token)
      download_file(file_name, params, request_headers)
    end
  end

  describe 'HEAD /api/v4/packages/maven/*path/:file_name' do
    let(:url) { "/packages/maven/#{package.maven_metadatum.path}/#{package_file.file_name}" }

    it_behaves_like 'processing HEAD requests'
  end

  describe 'GET /api/v4/groups/:id/-/packages/maven/*path/:file_name' do
    before do
      project.team.truncate
      group.add_developer(user)
    end

    context 'a public project' do
      subject { download_file(package_file.file_name) }

      it_behaves_like 'tracking the file download event'

      it 'returns the file' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end

      it 'returns sha1 of the file' do
        download_file(package_file.file_name + '.sha1')

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('text/plain')
        expect(response.body).to eq(package_file.file_sha1)
      end
    end

    context 'internal project' do
      before do
        group.group_member(user).destroy!
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      end

      subject { download_file_with_token(package_file.file_name) }

      it_behaves_like 'tracking the file download event'

      it 'returns the file' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end

      it 'denies download when no private token' do
        download_file(package_file.file_name)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it_behaves_like 'downloads with a job token'

      it_behaves_like 'downloads with a deploy token'
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      subject { download_file_with_token(package_file.file_name) }

      it_behaves_like 'tracking the file download event'

      it 'returns the file' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end

      it 'denies download when not enough permissions' do
        group.add_guest(user)

        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'denies download when no private token' do
        download_file(package_file.file_name)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it_behaves_like 'downloads with a job token'

      it_behaves_like 'downloads with a deploy token'

      context 'with group deploy token' do
        subject { download_file_with_token(package_file.file_name, {}, group_deploy_token_headers) }

        it 'returns the file' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq('application/octet-stream')
        end

        it 'returns the file with only write_package_registry scope' do
          deploy_token_for_group.update!(read_package_registry: false)

          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq('application/octet-stream')
        end
      end
    end

    def download_file(file_name, params = {}, request_headers = headers)
      get api("/groups/#{group.id}/-/packages/maven/#{maven_metadatum.path}/#{file_name}"), params: params, headers: request_headers
    end

    def download_file_with_token(file_name, params = {}, request_headers = headers_with_token)
      download_file(file_name, params, request_headers)
    end
  end

  describe 'HEAD /api/v4/groups/:id/-/packages/maven/*path/:file_name' do
    let(:url) { "/groups/#{group.id}/-/packages/maven/#{package.maven_metadatum.path}/#{package_file.file_name}" }

    it_behaves_like 'processing HEAD requests'
  end

  describe 'GET /api/v4/projects/:id/packages/maven/*path/:file_name' do
    context 'a public project' do
      subject { download_file(package_file.file_name) }

      it_behaves_like 'tracking the file download event'

      it 'returns the file' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end

      it 'returns sha1 of the file' do
        download_file(package_file.file_name + '.sha1')

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('text/plain')
        expect(response.body).to eq(package_file.file_sha1)
      end
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      subject { download_file_with_token(package_file.file_name) }

      it_behaves_like 'tracking the file download event'

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

      it 'denies download when no private token' do
        download_file(package_file.file_name)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it_behaves_like 'downloads with a job token'

      it_behaves_like 'downloads with a deploy token'
    end

    def download_file(file_name, params = {}, request_headers = headers)
      get api("/projects/#{project.id}/packages/maven/" \
              "#{maven_metadatum.path}/#{file_name}"), params: params, headers: request_headers
    end

    def download_file_with_token(file_name, params = {}, request_headers = headers_with_token)
      download_file(file_name, params, request_headers)
    end
  end

  describe 'HEAD /api/v4/projects/:id/packages/maven/*path/:file_name' do
    let(:url) { "/projects/#{project.id}/packages/maven/#{package.maven_metadatum.path}/#{package_file.file_name}" }

    it_behaves_like 'processing HEAD requests'
  end

  describe 'PUT /api/v4/projects/:id/packages/maven/*path/:file_name/authorize' do
    it 'rejects a malicious request' do
      put api("/projects/#{project.id}/packages/maven/com/example/my-app/#{version}/%2e%2e%2F.ssh%2Fauthorized_keys/authorize"), params: {}, headers: headers_with_token

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'authorizes posting package with a valid token' do
      authorize_upload_with_token

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      expect(json_response['TempPath']).not_to be_nil
    end

    it 'rejects request without a valid token' do
      headers_with_token['Private-Token'] = 'foo'

      authorize_upload_with_token

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'rejects request without a valid permission' do
      project.add_guest(user)

      authorize_upload_with_token

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'rejects requests that did not go through gitlab-workhorse' do
      headers.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER)

      authorize_upload_with_token

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'authorizes upload with job token' do
      authorize_upload(job_token: job.token)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'authorizes upload with deploy token' do
      authorize_upload({}, headers_with_deploy_token)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'rejects requests by a unauthorized deploy token with same id as a user with access' do
      unauthorized_deploy_token = create(:deploy_token, read_package_registry: true, write_package_registry: true)

      another_user = create(:user)
      project.add_developer(another_user)

      # We force the id of the deploy token and the user to be the same
      unauthorized_deploy_token.update!(id: another_user.id)

      authorize_upload({}, headers.merge(Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => unauthorized_deploy_token.token))

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    def authorize_upload(params = {}, request_headers = headers)
      put api("/projects/#{project.id}/packages/maven/com/example/my-app/#{version}/maven-metadata.xml/authorize"), params: params, headers: request_headers
    end

    def authorize_upload_with_token(params = {}, request_headers = headers_with_token)
      authorize_upload(params, request_headers)
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/maven/*path/:file_name' do
    let(:workhorse_token) { JWT.encode({ 'iss' => 'gitlab-workhorse' }, Gitlab::Workhorse.secret, 'HS256') }
    let(:workhorse_header) { { 'GitLab-Workhorse' => '1.0', Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER => workhorse_token } }
    let(:send_rewritten_field) { true }
    let(:file_upload) { fixture_file_upload('spec/fixtures/packages/maven/my-app-1.0-20180724.124855-1.jar') }

    before do
      # by configuring this path we allow to pass temp file from any path
      allow(Packages::PackageFileUploader).to receive(:workhorse_upload_path).and_return('/')
    end

    it 'rejects requests without a file from workhorse' do
      upload_file_with_token

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'rejects request without a token' do
      upload_file

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'without workhorse rewritten field' do
      let(:send_rewritten_field) { false }

      it 'rejects the request' do
        upload_file_with_token

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when params from workhorse are correct' do
      let(:params) { { file: file_upload } }

      context 'file size is too large' do
        it 'rejects the request' do
          allow_next_instance_of(UploadedFile) do |uploaded_file|
            allow(uploaded_file).to receive(:size).and_return(project.actual_limits.maven_max_file_size + 1)
          end

          upload_file_with_token(params: params)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      it 'rejects a malicious request' do
        put api("/projects/#{project.id}/packages/maven/com/example/my-app/#{version}/%2e%2e%2f.ssh%2fauthorized_keys"), params: params, headers: headers_with_token

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      context 'without workhorse header' do
        let(:workhorse_header) { {} }

        subject { upload_file_with_token(params: params) }

        it_behaves_like 'package workhorse uploads'
      end

      context 'event tracking' do
        subject { upload_file_with_token(params: params) }

        it_behaves_like 'a package tracking event', described_class.name, 'push_package'
      end

      it 'creates package and stores package file' do
        expect { upload_file_with_token(params: params) }.to change { project.packages.count }.by(1)
          .and change { Packages::Maven::Metadatum.count }.by(1)
          .and change { Packages::PackageFile.count }.by(1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(jar_file.file_name).to eq(file_upload.original_filename)
      end

      it 'allows upload with running job token' do
        upload_file(params: params.merge(job_token: job.token))

        expect(response).to have_gitlab_http_status(:ok)
        expect(project.reload.packages.last.original_build_info.pipeline).to eq job.pipeline
      end

      it 'rejects upload without running job token' do
        job.update!(status: :failed)
        upload_file(params: params.merge(job_token: job.token))

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'allows upload with deploy token' do
        upload_file(params: params, request_headers: headers_with_deploy_token)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'rejects uploads by a unauthorized deploy token with same id as a user with access' do
        unauthorized_deploy_token = create(:deploy_token, read_package_registry: true, write_package_registry: true)

        another_user = create(:user)
        project.add_developer(another_user)

        # We force the id of the deploy token and the user to be the same
        unauthorized_deploy_token.update!(id: another_user.id)

        upload_file(
          params: params,
          request_headers: headers.merge(Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => unauthorized_deploy_token.token)
        )

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      context 'version is not correct' do
        let(:version) { '$%123' }

        it 'rejects request' do
          expect { upload_file_with_token(params: params) }.not_to change { project.packages.count }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to include('Validation failed')
        end
      end

      context 'for sha1 file' do
        let(:dummy_package) { double(Packages::Package) }

        it 'checks the sha1' do
          # The sha verification done by the maven api is between:
          # - the sha256 set by workhorse helpers
          # - the sha256 of the sha1 of the uploaded package file
          # We're going to send `file_upload` for the sha1 and stub the sha1 of the package file so that
          # both sha256 being the same
          expect(::Packages::PackageFileFinder).to receive(:new).and_return(double(execute!: dummy_package))
          expect(dummy_package).to receive(:file_sha1).and_return(File.read(file_upload.path))

          upload_file_with_token(params: params, file_extension: 'jar.sha1')

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'for md5 file' do
        it 'returns an empty body' do
          upload_file_with_token(params: params, file_extension: 'jar.md5')

          expect(response.body).to eq('')
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    def upload_file(params: {}, request_headers: headers, file_extension: 'jar')
      url = "/projects/#{project.id}/packages/maven/com/example/my-app/#{version}/my-app-1.0-20180724.124855-1.#{file_extension}"
      workhorse_finalize(
        api(url),
        method: :put,
        file_key: :file,
        params: params,
        headers: request_headers,
        send_rewritten_field: send_rewritten_field
      )
    end

    def upload_file_with_token(params: {}, request_headers: headers_with_token, file_extension: 'jar')
      upload_file(params: params, request_headers: request_headers, file_extension: file_extension)
    end
  end
end
