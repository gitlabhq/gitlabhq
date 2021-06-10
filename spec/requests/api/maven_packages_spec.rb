# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::MavenPackages do
  include WorkhorseHelpers

  include_context 'workhorse headers'

  let_it_be_with_refind(:package_settings) { create(:namespace_package_setting, :group) }
  let_it_be_with_refind(:group) { package_settings.namespace }
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :public, namespace: group) }
  let_it_be(:package, reload: true) { create(:maven_package, project: project, name: project.full_path) }
  let_it_be(:maven_metadatum, reload: true) { package.maven_metadatum }
  let_it_be(:package_file) { package.package_files.with_file_name_like('%.xml').first }
  let_it_be(:jar_file) { package.package_files.with_file_name_like('%.jar').first }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:job, reload: true) { create(:ci_build, user: user, status: :running, project: project) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }
  let_it_be(:deploy_token_for_group) { create(:deploy_token, :group, read_package_registry: true, write_package_registry: true) }
  let_it_be(:group_deploy_token) { create(:group_deploy_token, deploy_token: deploy_token_for_group, group: group) }

  let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, user: user } }
  let(:package_name) { 'com/example/my-app' }
  let(:headers) { workhorse_headers }
  let(:headers_with_token) { headers.merge('Private-Token' => personal_access_token.token) }
  let(:group_deploy_token_headers) { { Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => deploy_token_for_group.token } }

  let(:headers_with_deploy_token) do
    headers.merge(
      Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => deploy_token.token
    )
  end

  let(:version) { '1.0-SNAPSHOT' }
  let(:param_path) { "#{package_name}/#{version}"}

  before do
    project.add_developer(user)
  end

  shared_examples 'handling groups and subgroups for' do |shared_example_name, visibilities: %i[public]|
    context 'within a group' do
      visibilities.each do |visibility|
        context "that is #{visibility}" do
          before do
            group.update!(visibility_level: Gitlab::VisibilityLevel.level_value(visibility.to_s))
          end

          it_behaves_like shared_example_name
        end
      end
    end

    context 'within a subgroup' do
      let_it_be_with_reload(:subgroup) { create(:group, parent: group) }

      before do
        move_project_to_namespace(subgroup)
      end

      visibilities.each do |visibility|
        context "that is #{visibility}" do
          before do
            subgroup.update!(visibility_level: Gitlab::VisibilityLevel.level_value(visibility.to_s))
            group.update!(visibility_level: Gitlab::VisibilityLevel.level_value(visibility.to_s))
          end

          it_behaves_like shared_example_name
        end
      end
    end
  end

  shared_examples 'handling groups, subgroups and user namespaces for' do |shared_example_name, visibilities: %i[public]|
    it_behaves_like 'handling groups and subgroups for', shared_example_name, visibilities: visibilities

    context 'within a user namespace' do
      before do
        move_project_to_namespace(user.namespace)
      end

      visibilities.each do |visibility|
        context "that is #{visibility}" do
          before do
            user.namespace.update!(visibility_level: Gitlab::VisibilityLevel.level_value(visibility.to_s))
          end

          it_behaves_like shared_example_name
        end
      end
    end
  end

  shared_examples 'tracking the file download event' do
    context 'with jar file' do
      let_it_be(:package_file) { jar_file }

      let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace } }

      it_behaves_like 'a package tracking event', described_class.name, 'pull_package'
    end
  end

  shared_examples 'rejecting the request for non existing maven path' do |expected_status: :not_found|
    it 'rejects the request' do
      expect(::Packages::Maven::PackageFinder).not_to receive(:new)

      subject

      expect(response).to have_gitlab_http_status(expected_status)
    end
  end

  shared_examples 'processing HEAD requests' do |instance_level: false|
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

      context 'with a non existing maven path' do
        let(:path) { 'foo/bar/1.2.3' }

        it_behaves_like 'rejecting the request for non existing maven path', expected_status: instance_level ? :forbidden : :not_found
      end
    end
  end

  shared_examples 'downloads with a deploy token' do
    context 'successful download' do
      subject do
        download_file(
          file_name: package_file.file_name,
          request_headers: { Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => deploy_token.token }
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
        download_file(file_name: package_file.file_name, params: { job_token: job.token })

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end
    end

    context 'with a finished job' do
      before do
        job.update!(status: :failed)
      end

      it 'returns unauthorized error' do
        download_file(file_name: package_file.file_name, params: { job_token: job.token })

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v4/packages/maven/*path/:file_name' do
    context 'a public project' do
      subject { download_file(file_name: package_file.file_name) }

      shared_examples 'getting a file' do
        it_behaves_like 'tracking the file download event'

        it 'returns the file' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq('application/octet-stream')
        end

        it 'returns sha1 of the file' do
          download_file(file_name: package_file.file_name + '.sha1')

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq('text/plain')
          expect(response.body).to eq(package_file.file_sha1)
        end

        context 'with a non existing maven path' do
          subject { download_file(file_name: package_file.file_name, path: 'foo/bar/1.2.3') }

          it_behaves_like 'rejecting the request for non existing maven path', expected_status: :forbidden
        end
      end

      it_behaves_like 'handling groups, subgroups and user namespaces for', 'getting a file'
    end

    context 'internal project' do
      before do
        project.team.truncate
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      end

      subject { download_file_with_token(file_name: package_file.file_name) }

      shared_examples 'getting a file' do
        it_behaves_like 'tracking the file download event'

        it 'returns the file' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq('application/octet-stream')
        end

        it 'denies download when no private token' do
          download_file(file_name: package_file.file_name)

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it_behaves_like 'downloads with a job token'

        it_behaves_like 'downloads with a deploy token'

        context 'with a non existing maven path' do
          subject { download_file_with_token(file_name: package_file.file_name, path: 'foo/bar/1.2.3') }

          it_behaves_like 'rejecting the request for non existing maven path', expected_status: :forbidden
        end
      end

      it_behaves_like 'handling groups, subgroups and user namespaces for', 'getting a file', visibilities: %i[public internal]
    end

    context 'private project' do
      subject { download_file_with_token(file_name: package_file.file_name) }

      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      shared_examples 'getting a file' do
        it_behaves_like 'tracking the file download event'

        it 'returns the file' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq('application/octet-stream')
        end

        it 'denies download when not enough permissions' do
          unless project.root_namespace == user.namespace
            project.add_guest(user)

            subject

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        it 'denies download when no private token' do
          download_file(file_name: package_file.file_name)

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
            file_name: package_file.file_name,
            request_headers: { Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => unauthorized_deploy_token.token }
          )

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        context 'with a non existing maven path' do
          subject { download_file_with_token(file_name: package_file.file_name, path: 'foo/bar/1.2.3') }

          it_behaves_like 'rejecting the request for non existing maven path', expected_status: :forbidden
        end
      end

      it_behaves_like 'handling groups, subgroups and user namespaces for', 'getting a file', visibilities: %i[public internal private]
    end

    context 'project name is different from a package name' do
      before do
        maven_metadatum.update!(path: "wrong_name/#{package.version}")
      end

      it 'rejects request' do
        download_file(file_name: package_file.file_name)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    def download_file(file_name:, params: {}, request_headers: headers, path: maven_metadatum.path)
      get api("/packages/maven/#{path}/#{file_name}"), params: params, headers: request_headers
    end

    def download_file_with_token(file_name:, params: {}, request_headers: headers_with_token, path: maven_metadatum.path)
      download_file(file_name: file_name, params: params, request_headers: request_headers, path: path)
    end
  end

  describe 'HEAD /api/v4/packages/maven/*path/:file_name' do
    let(:path) { package.maven_metadatum.path }
    let(:url) { "/packages/maven/#{path}/#{package_file.file_name}" }

    shared_examples 'heading a file' do
      it_behaves_like 'processing HEAD requests', instance_level: true
    end

    context 'with check_maven_path_first enabled' do
      before do
        stub_feature_flags(check_maven_path_first: true)
      end

      it_behaves_like 'handling groups, subgroups and user namespaces for', 'heading a file'
    end

    context 'with check_maven_path_first disabled' do
      before do
        stub_feature_flags(check_maven_path_first: false)
      end

      it_behaves_like 'handling groups, subgroups and user namespaces for', 'heading a file'
    end
  end

  describe 'GET /api/v4/groups/:id/-/packages/maven/*path/:file_name' do
    before do
      project.team.truncate
      group.add_developer(user)
    end

    context 'a public project' do
      subject { download_file(file_name: package_file.file_name) }

      shared_examples 'getting a file for a group' do
        it_behaves_like 'tracking the file download event'

        it 'returns the file' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq('application/octet-stream')
        end

        it 'returns sha1 of the file' do
          download_file(file_name: package_file.file_name + '.sha1')

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq('text/plain')
          expect(response.body).to eq(package_file.file_sha1)
        end

        context 'with a non existing maven path' do
          subject { download_file(file_name: package_file.file_name, path: 'foo/bar/1.2.3') }

          it_behaves_like 'rejecting the request for non existing maven path'
        end
      end

      it_behaves_like 'handling groups and subgroups for', 'getting a file for a group'
    end

    context 'internal project' do
      before do
        group.group_member(user).destroy!
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      end

      subject { download_file_with_token(file_name: package_file.file_name) }

      shared_examples 'getting a file for a group' do
        it_behaves_like 'tracking the file download event'

        it 'returns the file' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq('application/octet-stream')
        end

        it 'denies download when no private token' do
          download_file(file_name: package_file.file_name)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it_behaves_like 'downloads with a job token'

        it_behaves_like 'downloads with a deploy token'

        context 'with a non existing maven path' do
          subject { download_file_with_token(file_name: package_file.file_name, path: 'foo/bar/1.2.3') }

          it_behaves_like 'rejecting the request for non existing maven path'
        end
      end

      it_behaves_like 'handling groups and subgroups for', 'getting a file for a group', visibilities: %i[internal public]
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      subject { download_file_with_token(file_name: package_file.file_name) }

      shared_examples 'getting a file for a group' do
        it_behaves_like 'tracking the file download event'

        it 'returns the file' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq('application/octet-stream')
        end

        it 'denies download when not enough permissions' do
          group.add_guest(user)

          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'denies download when no private token' do
          download_file(file_name: package_file.file_name)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it_behaves_like 'downloads with a job token'

        it_behaves_like 'downloads with a deploy token'

        context 'with a non existing maven path' do
          subject { download_file_with_token(file_name: package_file.file_name, path: 'foo/bar/1.2.3') }

          it_behaves_like 'rejecting the request for non existing maven path'
        end

        context 'with group deploy token' do
          subject { download_file_with_token(file_name: package_file.file_name, request_headers: group_deploy_token_headers) }

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

          context 'with a non existing maven path' do
            subject { download_file_with_token(file_name: package_file.file_name, path: 'foo/bar/1.2.3', request_headers: group_deploy_token_headers) }

            it_behaves_like 'rejecting the request for non existing maven path'
          end
        end
      end

      it_behaves_like 'handling groups and subgroups for', 'getting a file for a group', visibilities: %i[private internal public]

      context 'with a reporter from a subgroup accessing the root group' do
        let_it_be(:root_group) { create(:group, :private) }
        let_it_be(:group) { create(:group, :private, parent: root_group) }

        subject { download_file_with_token(file_name: package_file.file_name, request_headers: headers_with_token, group_id: root_group.id) }

        before do
          project.update!(namespace: group)
          group.add_reporter(user)
        end

        it 'returns the file' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq('application/octet-stream')
        end

        context 'with a non existing maven path' do
          subject { download_file_with_token(file_name: package_file.file_name, path: 'foo/bar/1.2.3', request_headers: headers_with_token, group_id: root_group.id) }

          it_behaves_like 'rejecting the request for non existing maven path'
        end
      end
    end

    context 'maven metadata file' do
      let_it_be(:sub_group1) { create(:group, parent: group) }
      let_it_be(:sub_group2)   { create(:group, parent: group) }
      let_it_be(:project1) { create(:project, :private, group: sub_group1) }
      let_it_be(:project2) { create(:project, :private, group: sub_group2) }
      let_it_be(:project3) { create(:project, :private, group: sub_group1) }
      let_it_be(:package_name) { 'foo' }
      let_it_be(:package1) { create(:maven_package, project: project1, name: package_name, version: nil) }
      let_it_be(:package_file1) { create(:package_file, :xml, package: package1, file_name: 'maven-metadata.xml') }
      let_it_be(:package2) { create(:maven_package, project: project2, name: package_name, version: nil) }
      let_it_be(:package_file2) { create(:package_file, :xml, package: package2, file_name: 'maven-metadata.xml') }
      let_it_be(:package3) { create(:maven_package, project: project3, name: package_name, version: nil) }
      let_it_be(:package_file3) { create(:package_file, :xml, package: package3, file_name: 'maven-metadata.xml') }

      let(:maven_metadatum) { package3.maven_metadatum }

      subject { download_file_with_token(file_name: package_file3.file_name) }

      before do
        sub_group1.add_developer(user)
        sub_group2.add_developer(user)
        # the package with the most recently published file should be returned
        create(:package_file, :xml, package: package2)
      end

      context 'in multiple versionless packages' do
        it 'downloads the file' do
          expect(::Packages::PackageFileFinder)
            .to receive(:new).with(package2, 'maven-metadata.xml').and_call_original

          subject
        end
      end

      context 'in multiple snapshot packages' do
        before do
          version = '1.0.0-SNAPSHOT'
          [package1, package2, package3].each do |pkg|
            pkg.update!(version: version)

            pkg.maven_metadatum.update!(path: "#{pkg.name}/#{pkg.version}")
          end
        end

        it 'downloads the file' do
          expect(::Packages::PackageFileFinder)
            .to receive(:new).with(package3, 'maven-metadata.xml').and_call_original

          subject
        end
      end
    end

    def download_file(file_name:, params: {}, request_headers: headers, path: maven_metadatum.path, group_id: group.id)
      get api("/groups/#{group_id}/-/packages/maven/#{path}/#{file_name}"), params: params, headers: request_headers
    end

    def download_file_with_token(file_name:, params: {}, request_headers: headers_with_token, path: maven_metadatum.path, group_id: group.id)
      download_file(file_name: file_name, params: params, request_headers: request_headers, path: path, group_id: group_id)
    end
  end

  describe 'HEAD /api/v4/groups/:id/-/packages/maven/*path/:file_name' do
    let(:path) { package.maven_metadatum.path }
    let(:url) { "/groups/#{group.id}/-/packages/maven/#{path}/#{package_file.file_name}" }

    context 'with check_maven_path_first enabled' do
      before do
        stub_feature_flags(check_maven_path_first: true)
      end

      it_behaves_like 'handling groups and subgroups for', 'processing HEAD requests'
    end

    context 'with check_maven_path_first disabled' do
      before do
        stub_feature_flags(check_maven_path_first: false)
      end

      it_behaves_like 'handling groups and subgroups for', 'processing HEAD requests'
    end
  end

  describe 'GET /api/v4/projects/:id/packages/maven/*path/:file_name' do
    context 'a public project' do
      subject { download_file(file_name: package_file.file_name) }

      it_behaves_like 'tracking the file download event'

      it 'returns the file' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end

      it 'returns sha1 of the file' do
        download_file(file_name: package_file.file_name + '.sha1')

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('text/plain')
        expect(response.body).to eq(package_file.file_sha1)
      end

      context 'with a non existing maven path' do
        subject { download_file(file_name: package_file.file_name, path: 'foo/bar/1.2.3') }

        it_behaves_like 'rejecting the request for non existing maven path'
      end
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      subject { download_file_with_token(file_name: package_file.file_name) }

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
        download_file(file_name: package_file.file_name)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it_behaves_like 'downloads with a job token'

      it_behaves_like 'downloads with a deploy token'

      context 'with a non existing maven path' do
        subject { download_file_with_token(file_name: package_file.file_name, path: 'foo/bar/1.2.3') }

        it_behaves_like 'rejecting the request for non existing maven path'
      end
    end

    def download_file(file_name:, params: {}, request_headers: headers, path: maven_metadatum.path)
      get api("/projects/#{project.id}/packages/maven/" \
              "#{path}/#{file_name}"), params: params, headers: request_headers
    end

    def download_file_with_token(file_name:, params: {}, request_headers: headers_with_token, path: maven_metadatum.path)
      download_file(file_name: file_name, params: params, request_headers: request_headers, path: path)
    end
  end

  describe 'HEAD /api/v4/projects/:id/packages/maven/*path/:file_name' do
    let(:path) { package.maven_metadatum.path }
    let(:url) { "/projects/#{project.id}/packages/maven/#{path}/#{package_file.file_name}" }

    context 'with check_maven_path_first enabled' do
      before do
        stub_feature_flags(check_maven_path_first: true)
      end

      it_behaves_like 'processing HEAD requests'
    end

    context 'with check_maven_path_first disabled' do
      before do
        stub_feature_flags(check_maven_path_first: false)
      end

      it_behaves_like 'processing HEAD requests'
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/maven/*path/:file_name/authorize' do
    it 'rejects a malicious request' do
      put api("/projects/#{project.id}/packages/maven/com/example/my-app/#{version}/%2e%2e%2F.ssh%2Fauthorized_keys/authorize"), headers: headers_with_token

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
    include_context 'workhorse headers'

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
        let(:workhorse_headers) { {} }

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

      context 'when package duplicates are not allowed' do
        let(:package_name) { package.name }
        let(:version) { package.version }

        before do
          package_settings.update!(maven_duplicates_allowed: false)
        end

        shared_examples 'storing the package file' do
          it 'stores the file', :aggregate_failures do
            expect { upload_file_with_token(params: params) }.to change { package.package_files.count }.by(1)

            expect(response).to have_gitlab_http_status(:ok)
            expect(jar_file.file_name).to eq(file_upload.original_filename)
          end
        end

        it 'rejects the request', :aggregate_failures do
          expect { upload_file_with_token(params: params) }.not_to change { package.package_files.count }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to include('Duplicate package is not allowed')
        end

        context 'when uploading to the versionless package which contains metadata about all versions' do
          let(:version) { nil }
          let(:param_path) { package_name }
          let!(:package) { create(:maven_package, project: project, version: version, name: project.full_path) }

          it_behaves_like 'storing the package file'
        end

        context 'when uploading different non-duplicate files to the same package' do
          let!(:package) { create(:maven_package, project: project, name: project.full_path) }

          before do
            package_file = package.package_files.find_by(file_name: 'my-app-1.0-20180724.124855-1.jar')
            package_file.destroy!
          end

          it_behaves_like 'storing the package file'
        end

        context 'when the package name matches the exception regex' do
          before do
            package_settings.update!(maven_duplicate_exception_regex: '.*')
          end

          it_behaves_like 'storing the package file'
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
      url = "/projects/#{project.id}/packages/maven/#{param_path}/my-app-1.0-20180724.124855-1.#{file_extension}"
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

  def move_project_to_namespace(namespace)
    project.update!(namespace: namespace)
    package.update!(name: project.full_path)
    maven_metadatum.update!(path: "#{package.name}/#{package.version}")
  end
end
