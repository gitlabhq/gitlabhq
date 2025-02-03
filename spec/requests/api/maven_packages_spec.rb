# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::MavenPackages, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax
  include WorkhorseHelpers
  include HttpBasicAuthHelpers

  include_context 'workhorse headers'

  let_it_be_with_refind(:package_settings) { create(:namespace_package_setting, :group) }
  let_it_be_with_refind(:group) { package_settings.namespace }
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :public, namespace: group, developers: user) }
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

  let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, user: user, property: 'i_package_maven_user' } }

  let(:package_name) { 'com/example/my-app' }
  let(:headers) { workhorse_headers }
  let(:headers_with_token) { headers.merge('Private-Token' => personal_access_token.token) }
  let(:group_deploy_token_headers) { { Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => deploy_token_for_group.token } }

  let(:sha1_checksum_header) { ::API::Helpers::Packages::Maven::SHA1_CHECKSUM_HEADER }
  let(:md5_checksum_header) { ::API::Helpers::Packages::Maven::MD5_CHECKSUM_HEADER }

  let(:headers_with_deploy_token) { headers.merge(Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => deploy_token.token) }

  let(:version) { '1.0-SNAPSHOT' }
  let(:param_path) { "#{package_name}/#{version}" }

  before do
    Gitlab::Database::LoadBalancing::SessionMap.clear_session
  end

  shared_examples 'handling groups and subgroups for' do |shared_example_name, shared_example_args = {}, visibilities: { public: :redirect }|
    context 'within a group' do
      visibilities.each do |visibility, not_found_response|
        context "that is #{visibility}" do
          before do
            group.update!(visibility_level: Gitlab::VisibilityLevel.level_value(visibility.to_s))
          end

          it_behaves_like shared_example_name, not_found_response, shared_example_args
        end
      end
    end

    context 'within a subgroup' do
      let_it_be_with_reload(:subgroup) { create(:group, parent: group) }

      before do
        move_project_to_namespace(subgroup)
      end

      visibilities.each do |visibility, not_found_response|
        context "that is #{visibility}" do
          before do
            subgroup.update!(visibility_level: Gitlab::VisibilityLevel.level_value(visibility.to_s))
            group.update!(visibility_level: Gitlab::VisibilityLevel.level_value(visibility.to_s))
          end

          it_behaves_like shared_example_name, not_found_response, shared_example_args
        end
      end
    end
  end

  shared_examples 'handling groups, subgroups and user namespaces for' do |shared_example_name, visibilities: { public: :redirect }|
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

      it_behaves_like 'a package tracking event', described_class.name, 'pull_package'
    end
  end

  shared_examples 'allowing the download' do
    it 'allows download' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.media_type).to eq('application/octet-stream')
    end
  end

  shared_examples 'not allowing the download with' do |not_found_response|
    it 'does not allow the download' do
      subject

      expect(response).to have_gitlab_http_status(not_found_response)
    end
  end

  shared_examples 'downloads with a personal access token' do |not_found_response|
    where(:valid, :sent_using) do
      true  | :custom_header
      false | :custom_header
      true  | :basic_auth
      false | :basic_auth
    end

    with_them do
      let(:token) { valid ? personal_access_token.token : 'not_valid' }
      let(:headers) do
        case sent_using
        when :custom_header
          { 'Private-Token' => token }
        when :basic_auth
          basic_auth_header(user.username, token)
        end
      end

      subject do
        download_file(
          file_name: package_file.file_name,
          request_headers: headers
        )
      end

      if params[:valid]
        it_behaves_like 'allowing the download'
      else
        expected_status_code = not_found_response
        # invalid PAT values sent through headers are validated.
        # Invalid values will trigger an :unauthorized response (and not set current_user to nil)
        expected_status_code = :unauthorized if params[:sent_using] == :custom_header && !params[:valid]
        it_behaves_like 'not allowing the download with', expected_status_code
      end
    end
  end

  shared_examples 'downloads with a deploy token' do |not_found_response|
    where(:valid, :sent_using) do
      true  | :custom_header
      false | :custom_header
      true  | :basic_auth
      false | :basic_auth
    end

    with_them do
      let(:token) { valid ? deploy_token.token : 'not_valid' }
      let(:headers) do
        case sent_using
        when :custom_header
          { Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => token }
        when :basic_auth
          basic_auth_header(deploy_token.username, token)
        end
      end

      subject do
        download_file(
          file_name: package_file.file_name,
          request_headers: headers
        )
      end

      if params[:valid]
        it_behaves_like 'allowing the download'

        context 'with only write_package_registry scope' do
          it_behaves_like 'allowing the download' do
            before do
              deploy_token.update!(read_package_registry: false)
            end
          end
        end
      else
        it_behaves_like 'not allowing the download with', not_found_response
      end
    end
  end

  shared_examples 'downloads with a job token' do
    where(:valid, :sent_using) do
      true  | :custom_params
      false | :custom_params
      true  | :basic_auth
      false | :basic_auth
    end

    with_them do
      let(:token) { valid ? job.token : 'not_valid' }
      let(:headers) { basic_auth_header(::Gitlab::Auth::CI_JOB_USER, token) }
      let(:params) { { job_token: token } }

      subject do
        case sent_using
        when :custom_params
          download_file(file_name: package_file.file_name, params: params)
        when :basic_auth
          download_file(file_name: package_file.file_name, request_headers: headers)
        end
      end

      context 'with a running job' do
        if params[:valid]
          it_behaves_like 'allowing the download'
        else
          it_behaves_like 'not allowing the download with', :unauthorized
        end
      end

      context 'with a finished job' do
        before do
          job.update!(status: :failed)
        end

        it_behaves_like 'not allowing the download with', :unauthorized
      end
    end
  end

  shared_examples 'downloads with different tokens' do |not_found_response|
    it_behaves_like 'downloads with a personal access token', not_found_response
    it_behaves_like 'downloads with a deploy token', not_found_response
    it_behaves_like 'downloads with a job token'
  end

  shared_examples 'successfully returning the file' do |include_md5_checksum: true|
    it 'returns the file', :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.media_type).to eq('application/octet-stream')
      expect(response.headers[sha1_checksum_header]).to be_an_instance_of(String)

      if include_md5_checksum
        expect(response.headers[md5_checksum_header]).to be_an_instance_of(String)
      else
        expect(response.headers[md5_checksum_header]).to be_nil
      end
    end
  end

  shared_examples 'file download in FIPS mode' do
    context 'in FIPS mode', :fips_mode do
      it_behaves_like 'successfully returning the file', include_md5_checksum: false

      it 'rejects the request for an md5 file' do
        download_file(file_name: package_file.file_name + '.md5')

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end
  end

  shared_examples 'forwarding package requests' do
    context 'request forwarding' do
      include_context 'dependency proxy helpers context'

      subject { download_file(file_name: package_name) }

      shared_examples 'redirecting the request' do
        it_behaves_like 'returning response status', :redirect
      end

      shared_examples 'package not found' do
        it_behaves_like 'returning response status', :not_found
      end

      where(:forward, :package_in_project, :shared_examples_name) do
        true  | true  | 'successfully returning the file'
        true  | false | 'redirecting the request'
        false | true  | 'successfully returning the file'
        false | false | 'package not found'
      end

      with_them do
        let(:package_name) { package_in_project ? package_file.file_name : 'foo' }

        before do
          allow_fetch_cascade_application_setting(attribute: 'maven_package_requests_forwarding', return_value: forward)
        end

        it_behaves_like params[:shared_examples_name]
      end

      context 'with maven_central_request_forwarding disabled' do
        where(:forward, :package_in_project, :shared_examples_name) do
          true  | true  | 'successfully returning the file'
          true  | false | 'package not found'
          false | true  | 'successfully returning the file'
          false | false | 'package not found'
        end

        with_them do
          let(:package_name) { package_in_project ? package_file.file_name : 'foo' }

          before do
            stub_feature_flags(maven_central_request_forwarding: false)
            allow_fetch_cascade_application_setting(attribute: 'maven_package_requests_forwarding', return_value: forward)
          end

          it_behaves_like params[:shared_examples_name]
        end
      end
    end
  end

  shared_examples 'rejecting request with invalid params' do
    context 'with invalid maven path' do
      subject { download_file(file_name: package_file.file_name, path: 'foo/bar/%0d%0ahttp:/%2fexample.com') }

      it_behaves_like 'returning response status with error', status: :bad_request, error: 'path should be a valid file path'
    end

    context 'with invalid file name' do
      subject { download_file(file_name: '%0d%0ahttp:/%2fexample.com') }

      it_behaves_like 'returning response status with error', status: :bad_request, error: 'file_name should be a valid file path'
    end
  end

  describe 'GET /api/v4/packages/maven/*path/:file_name' do
    context 'a public project' do
      let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, property: 'i_package_maven_user' } }

      subject { download_file(file_name: package_file.file_name) }

      shared_examples 'getting a file' do
        it_behaves_like 'tracking the file download event'
        it_behaves_like 'bumping the package last downloaded at field'
        it_behaves_like 'successfully returning the file'
        it_behaves_like 'file download in FIPS mode'

        it 'returns sha1 of the file' do
          download_file(file_name: package_file.file_name + '.sha1')

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq('text/plain')
          expect(response.body).to eq(package_file.file_sha1)
        end

        context 'with a non existing maven path' do
          subject { download_file(file_name: package_file.file_name, path: 'foo/bar/1.2.3') }

          it_behaves_like 'returning response status', :forbidden
        end

        it_behaves_like 'rejecting request with invalid params'

        it 'returns not found when a package is not found' do
          finder = double('finder', execute: nil)
          expect(::Packages::Maven::PackageFinder).to receive(:new).and_return(finder)

          subject

          expect(response).to have_gitlab_http_status(:not_found)
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
        it_behaves_like 'bumping the package last downloaded at field'
        it_behaves_like 'successfully returning the file'

        it 'denies download when no private token' do
          download_file(file_name: package_file.file_name)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        it_behaves_like 'downloads with different tokens', :unauthorized

        context 'with a non existing maven path' do
          subject { download_file_with_token(file_name: package_file.file_name, path: 'foo/bar/1.2.3') }

          it_behaves_like 'returning response status', :forbidden
        end
      end

      it_behaves_like 'rejecting request with invalid params'

      it_behaves_like 'handling groups, subgroups and user namespaces for', 'getting a file', visibilities: { public: :redirect, internal: :not_found }
    end

    context 'private project' do
      subject { download_file_with_token(file_name: package_file.file_name) }

      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      shared_examples 'getting a file' do
        it_behaves_like 'tracking the file download event'
        it_behaves_like 'bumping the package last downloaded at field'
        it_behaves_like 'successfully returning the file'

        context 'when allow_guest_plus_roles_to_pull_packages is disabled' do
          before do
            stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
          end

          it 'denies download when not enough permissions' do
            unless project.root_namespace == user.namespace
              project.add_guest(user)

              subject

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end
        end

        it 'denies download when no private token' do
          download_file(file_name: package_file.file_name)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        it_behaves_like 'downloads with different tokens', :unauthorized

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

          it_behaves_like 'returning response status', :forbidden
        end
      end

      it_behaves_like 'enforcing job token policies', :read_packages do
        before_all do
          project.add_maintainer(user)
        end

        let(:request) { download_file(file_name: package_file.file_name, params: { job_token: target_job.token }) }
      end

      it_behaves_like 'rejecting request with invalid params'

      it_behaves_like 'handling groups, subgroups and user namespaces for', 'getting a file', visibilities: { public: :redirect, internal: :not_found, private: :not_found }
    end

    context 'project name is different from a package name' do
      it 'rejects request' do
        download_file(file_name: package_file.file_name, path: "wrong_name/#{package.version}")

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

  describe 'GET /api/v4/groups/:id/-/packages/maven/*path/:file_name' do
    before do
      project.team.truncate
      group.add_developer(user)
    end

    it_behaves_like 'forwarding package requests'

    context 'a public project' do
      let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, property: 'i_package_maven_user' } }

      subject { download_file(file_name: package_file.file_name) }

      shared_examples 'getting a file for a group' do
        it_behaves_like 'tracking the file download event'
        it_behaves_like 'bumping the package last downloaded at field'
        it_behaves_like 'successfully returning the file'
        it_behaves_like 'file download in FIPS mode'

        it 'returns sha1 of the file' do
          download_file(file_name: package_file.file_name + '.sha1')

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq('text/plain')
          expect(response.body).to eq(package_file.file_sha1)
        end

        context 'with a non existing maven path' do
          subject { download_file(file_name: package_file.file_name, path: 'foo/bar/1.2.3') }

          it_behaves_like 'returning response status', :redirect
        end
      end

      it_behaves_like 'rejecting request with invalid params'

      it_behaves_like 'handling groups and subgroups for', 'getting a file for a group'
    end

    context 'internal project' do
      before do
        group.member(user).destroy!
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      end

      subject { download_file_with_token(file_name: package_file.file_name) }

      shared_examples 'getting a file for a group' do |not_found_response|
        it_behaves_like 'tracking the file download event'
        it_behaves_like 'bumping the package last downloaded at field'
        it_behaves_like 'successfully returning the file'

        it 'forwards download when no private token' do
          download_file(file_name: package_file.file_name)

          expect(response).to have_gitlab_http_status(not_found_response)
        end

        it_behaves_like 'downloads with different tokens', not_found_response

        context 'with a non existing maven path' do
          subject { download_file_with_token(file_name: package_file.file_name, path: 'foo/bar/1.2.3') }

          it_behaves_like 'returning response status', :redirect
        end
      end

      it_behaves_like 'rejecting request with invalid params'

      it_behaves_like 'handling groups and subgroups for', 'getting a file for a group', visibilities: { internal: :unauthorized, public: :unauthorized }

      context 'when the FF maven_remove_permissions_check_from_finder disabled' do
        before do
          stub_feature_flags(maven_remove_permissions_check_from_finder: false)
        end

        it_behaves_like 'handling groups and subgroups for', 'getting a file for a group', visibilities: { internal: :unauthorized, public: :redirect }
      end
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      subject { download_file_with_token(file_name: package_file.file_name) }

      shared_examples 'getting a file for a group' do |not_found_response, download_denied_status: :forbidden|
        it_behaves_like 'tracking the file download event'
        it_behaves_like 'bumping the package last downloaded at field'
        it_behaves_like 'successfully returning the file'

        context 'when allow_guest_plus_roles_to_pull_packages is disabled' do
          before do
            stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
          end

          it 'denies download when not enough permissions' do
            group.add_guest(user)

            subject

            expect(response).to have_gitlab_http_status(download_denied_status)
          end
        end

        it 'denies download when no private token' do
          download_file(file_name: package_file.file_name)

          expect(response).to have_gitlab_http_status(not_found_response)
        end

        it_behaves_like 'downloads with different tokens', not_found_response

        context 'with a non existing maven path' do
          subject { download_file_with_token(file_name: package_file.file_name, path: 'foo/bar/1.2.3') }

          it_behaves_like 'returning response status', :redirect
        end

        it_behaves_like 'rejecting request with invalid params'

        context 'with group deploy token' do
          subject { download_file_with_token(file_name: package_file.file_name, request_headers: group_deploy_token_headers) }

          it_behaves_like 'successfully returning the file'

          it 'returns the file with only write_package_registry scope' do
            deploy_token_for_group.update!(read_package_registry: false)

            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.media_type).to eq('application/octet-stream')
          end

          context 'with a non existing maven path' do
            subject { download_file_with_token(file_name: package_file.file_name, path: 'foo/bar/1.2.3', request_headers: group_deploy_token_headers) }

            it_behaves_like 'returning response status', :redirect
          end
        end
      end

      it_behaves_like 'enforcing job token policies', :read_packages do
        let(:request) do
          download_file(file_name: package_file.file_name, params: { job_token: target_job.token })
        end
      end

      context 'with the duplicate packages in the two projects' do
        let_it_be(:recent_project) { create(:project, :private, namespace: group) }

        let!(:package_dup) { create(:maven_package, project: recent_project, name: package.name, version: package.version) }

        before do
          group.add_guest(user)
          project.add_developer(user)
        end

        context 'when allow_guest_plus_roles_to_pull_packages is disabled' do
          before do
            stub_feature_flags(allow_guest_plus_roles_to_pull_packages: false)
          end

          context 'when user does not have enough permission for the recent project' do
            it 'tries to download the recent package' do
              subject

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end

          context 'when the FF maven_remove_permissions_check_from_finder disabled' do
            before do
              stub_feature_flags(maven_remove_permissions_check_from_finder: false)
            end

            it_behaves_like 'bumping the package last downloaded at field'
            it_behaves_like 'successfully returning the file'
          end
        end
      end

      it_behaves_like 'handling groups and subgroups for', 'getting a file for a group', visibilities: { private: :unauthorized, internal: :unauthorized, public: :unauthorized }

      context 'when the FF maven_remove_permissions_check_from_finder disabled' do
        before do
          stub_feature_flags(maven_remove_permissions_check_from_finder: false)
        end

        it_behaves_like 'handling groups and subgroups for', 'getting a file for a group', { download_denied_status: :redirect }, visibilities: { private: :unauthorized, internal: :unauthorized, public: :redirect }
      end

      context 'with a reporter from a subgroup accessing the root group' do
        let_it_be(:root_group) { create(:group, :private) }
        let_it_be(:group) { create(:group, :private, parent: root_group) }

        subject { download_file_with_token(file_name: package_file.file_name, request_headers: headers_with_token, group_id: root_group.id) }

        before do
          project.update!(namespace: group)
          group.add_reporter(user)
        end

        it_behaves_like 'successfully returning the file'

        context 'with a non existing maven path' do
          subject { download_file_with_token(file_name: package_file.file_name, path: 'foo/bar/1.2.3', request_headers: headers_with_token, group_id: root_group.id) }

          it_behaves_like 'returning response status', :redirect
        end
      end

      context 'with anonymous access to a public registry' do
        let(:headers_with_token) { {} }

        before do
          project.project_feature.update!(package_registry_access_level: ::ProjectFeature::PUBLIC)
          stub_feature_flags(maven_remove_permissions_check_from_finder: false)
        end

        it_behaves_like 'successfully returning the file'
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

  describe 'GET /api/v4/projects/:id/packages/maven/*path/:file_name' do
    context 'a public project' do
      let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, property: 'i_package_maven_user' } }

      subject { download_file(file_name: package_file.file_name) }

      it_behaves_like 'tracking the file download event'
      it_behaves_like 'successfully returning the file'
      it_behaves_like 'file download in FIPS mode'

      %w[sha1 md5].each do |format|
        it "returns #{format} of the file" do
          download_file(file_name: package_file.file_name + ".#{format}")

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type).to eq('text/plain')
          expect(response.body).to eq(package_file.send(:"file_#{format}"))
        end
      end

      context 'when the repository is disabled' do
        before do
          project.project_feature.update!(
            # Disable merge_requests and builds as well, since merge_requests and
            # builds cannot have higher visibility than repository.
            merge_requests_access_level: ProjectFeature::DISABLED,
            builds_access_level: ProjectFeature::DISABLED,
            repository_access_level: ProjectFeature::DISABLED)
        end

        it_behaves_like 'successfully returning the file'
      end

      context 'with a non existing maven path' do
        subject { download_file(file_name: package_file.file_name, path: 'foo/bar/1.2.3') }

        it_behaves_like 'returning response status', :redirect
      end

      it_behaves_like 'rejecting request with invalid params'
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      subject { download_file_with_token(file_name: package_file.file_name) }

      it_behaves_like 'enforcing job token policies', :read_packages do
        let(:request) do
          download_file(file_name: package_file.file_name, params: { job_token: target_job.token })
        end
      end

      it_behaves_like 'tracking the file download event'
      it_behaves_like 'bumping the package last downloaded at field'
      it_behaves_like 'successfully returning the file'

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

      it 'denies download when no private token' do
        download_file(file_name: package_file.file_name)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      context 'with access to package registry for everyone' do
        subject { download_file(file_name: package_file.file_name) }

        before do
          project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
        end

        it_behaves_like 'successfully returning the file'
      end

      it_behaves_like 'downloads with different tokens', :unauthorized

      context 'with a non existing maven path' do
        subject { download_file_with_token(file_name: package_file.file_name, path: 'foo/bar/1.2.3') }

        it_behaves_like 'returning response status', :redirect
      end

      it_behaves_like 'rejecting request with invalid params'
    end

    it_behaves_like 'forwarding package requests'

    def download_file(file_name:, params: {}, request_headers: headers, path: maven_metadatum.path)
      get api("/projects/#{project.id}/packages/maven/" \
              "#{path}/#{file_name}"), params: params, headers: request_headers
    end

    def download_file_with_token(file_name:, params: {}, request_headers: headers_with_token, path: maven_metadatum.path)
      download_file(file_name: file_name, params: params, request_headers: request_headers, path: path)
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/maven/*path/:file_name/authorize' do
    it_behaves_like 'enforcing job token policies', :admin_packages do
      let(:request) { authorize_upload(job_token: target_job.token) }
    end

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

    context 'with basic auth' do
      let(:user_username) { user.username }

      where(:username, :password) do
        ref(:user_username)         | lazy { personal_access_token.token }
        ref(:user_username)         | lazy { deploy_token.token }
        ::Gitlab::Auth::CI_JOB_USER | lazy { job.token }
      end

      with_them do
        it 'authorizes upload' do
          authorize_upload({}, headers.merge(headers.merge(basic_auth_header(username, password))))

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    def authorize_upload(params = {}, request_headers = headers)
      put api("/projects/#{project.id}/packages/maven/com/example/my-app/#{version}/maven-metadata.xml/authorize"), params: params, headers: request_headers
    end

    def authorize_upload_with_token(params = {}, request_headers = headers_with_token)
      authorize_upload(params, request_headers)
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/maven/*path/:file_name' do
    let(:send_rewritten_field) { true }
    let(:file_upload) { fixture_file_upload('spec/fixtures/packages/maven/my-app-1.0-20180724.124855-1.jar') }

    before do
      # by configuring this path we allow to pass temp file from any path
      allow(Packages::PackageFileUploader).to receive(:workhorse_upload_path).and_return('/')
    end

    it_behaves_like 'enforcing job token policies', :admin_packages do
      let(:request) { upload_file(params: { file: file_upload, job_token: target_job.token }) }
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

      subject { upload_file_with_token(params: params) }

      context 'FIPS mode', :fips_mode do
        it_behaves_like 'package workhorse uploads'

        it 'returns 200 for the request for md5 file' do
          upload_file_with_token(params: params, file_extension: 'jar.md5')

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

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

      it_behaves_like 'package workhorse uploads'

      context 'event tracking' do
        it_behaves_like 'a package tracking event', described_class.name, 'push_package'

        context 'when the package file fails to be created' do
          before do
            allow_next_instance_of(::Packages::CreatePackageFileService) do |create_package_file_service|
              allow(create_package_file_service).to receive(:execute).and_raise(StandardError)
            end
          end

          it_behaves_like 'not a package tracking event'
        end
      end

      it 'creates package and stores package file' do
        expect_use_primary

        expect { upload_file_with_token(params: params) }.to change { project.packages.count }.by(1)
          .and change { Packages::Maven::Metadatum.count }.by(1)
          .and change { Packages::PackageFile.count }.by(1)

        expect(response).to have_gitlab_http_status(:ok)
        expect(jar_file.file_name).to eq(file_upload.original_filename)
      end

      it 'allows upload with running job token' do
        upload_file(params: params.merge(job_token: job.token))

        expect(response).to have_gitlab_http_status(:ok)
        expect(project.reload.packages.last.last_build_info.pipeline).to eq job.pipeline
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

      context 'with basic auth' do
        where(:token_type) do
          %i[personal_access_token deploy_token job]
        end

        with_them do
          let(:token) { send(token_type).token }

          it "allows upload with #{params[:token_type]} token" do
            upload_file(params: params, request_headers: headers.merge(basic_auth_header(token_type == :job ? ::Gitlab::Auth::CI_JOB_USER : user.username, token)))

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context 'file name is too long' do
        let(:file_name) { 'a' * (Packages::Maven::FindOrCreatePackageService::MAX_FILE_NAME_LENGTH + 1) }

        it 'rejects request' do
          expect { upload_file_with_token(params: params, file_name: file_name) }.not_to change { project.packages.count }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to include('File name is too long')
        end
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

        shared_examples 'storing the package file' do |file_name: 'my-app-1.0-20180724.124855-1'|
          it 'stores the file', :aggregate_failures do
            expect { upload_file_with_token(params: params, file_name: file_name) }.to change { package.package_files.count }.by(1)

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

        context 'when uploading a similar package file name with a classifier' do
          it_behaves_like 'storing the package file', file_name: 'my-app-1.0-20180724.124855-1-javadoc'
        end
      end

      context 'for sha1 file' do
        let(:dummy_package) { double(Packages::Package) }
        let(:file_upload) { fixture_file_upload('spec/fixtures/packages/maven/my-app-1.0-20180724.124855-1.pom.sha1') }
        let(:stored_sha1) { File.read(file_upload.path) }

        subject(:upload) { upload_file_with_token(params: params, file_extension: 'pom.sha1') }

        before do
          # The sha verification done by the maven api is between:
          # - the sha256 set by workhorse helpers
          # - the sha256 of the sha1 of the uploaded package file
          # We're going to send `file_upload` for the sha1 and stub the sha1 of the package file so that
          # both sha256 being the same
          allow(::Packages::PackageFileFinder).to receive(:new).and_return(double(execute!: dummy_package))
          allow(dummy_package).to receive(:file_sha1).and_return(stored_sha1)
        end

        it 'returns no content' do
          expect_use_primary

          upload

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'for md5 file' do
        subject { upload_file_with_token(params: params, file_extension: 'jar.md5') }

        it 'returns an empty body' do
          expect_use_primary

          subject

          expect(response.body).to eq('')
          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'with FIPS mode enabled', :fips_mode do
          it 'returns an empty body' do
            expect_use_primary

            subject

            expect(response.body).to eq('')
            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context 'reading fingerprints from UploadedFile instance' do
        let(:file) { Packages::Package.last.package_files.with_format('%.jar').last }

        subject { upload_file_with_token(params: params) }

        before do
          allow_next_instance_of(UploadedFile) do |uploaded_file|
            allow(uploaded_file).to receive(:size).and_return(123)
            allow(uploaded_file).to receive(:sha1).and_return('sha1')
            allow(uploaded_file).to receive(:md5).and_return('md5')
          end
        end

        it 'reads size, sha1 and md5 fingerprints from uploaded_file instance' do
          subject

          expect(file.size).to eq(123)
          expect(file.file_sha1).to eq('sha1')
          expect(file.file_md5).to eq('md5')
        end
      end

      def expect_use_primary
        lb_session = ::Gitlab::Database::LoadBalancing::SessionMap.current(ApplicationRecord.load_balancer)

        expect(lb_session).to receive(:use_primary).and_call_original

        allow(::Gitlab::Database::LoadBalancing::SessionMap).to receive(:current).and_return(lb_session)
      end
    end

    def upload_file(params: {}, request_headers: headers, file_extension: 'jar', file_name: 'my-app-1.0-20180724.124855-1')
      url = "/projects/#{project.id}/packages/maven/#{param_path}/#{file_name}.#{file_extension}"
      workhorse_finalize(
        api(url),
        method: :put,
        file_key: :file,
        params: params,
        headers: request_headers,
        send_rewritten_field: send_rewritten_field
      )
    end

    def upload_file_with_token(params: {}, request_headers: headers_with_token, file_extension: 'jar', file_name: 'my-app-1.0-20180724.124855-1')
      upload_file(params: params, request_headers: request_headers, file_name: file_name, file_extension: file_extension)
    end
  end

  def move_project_to_namespace(namespace)
    project.update!(namespace: namespace)
    package.update!(name: project.full_path)
    maven_metadatum.update!(path: "#{package.name}/#{package.version}")
  end
end
