# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GenericPackages, feature_category: :package_registry do
  include HttpBasicAuthHelpers
  using RSpec::Parameterized::TableSyntax

  include_context 'workhorse headers'

  let_it_be(:personal_access_token) { create(:personal_access_token) }
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:deploy_token_rw) do
    create(:deploy_token, read_package_registry: true, write_package_registry: true, projects: [project])
  end

  let_it_be(:deploy_token_ro) do
    create(:deploy_token, read_package_registry: true, write_package_registry: false, projects: [project])
  end

  let_it_be(:deploy_token_wo) do
    create(:deploy_token, read_package_registry: false, write_package_registry: true, projects: [project])
  end

  let(:user) { personal_access_token.user }
  let(:ci_build) { create(:ci_build, :running, user: user, project: project) }
  let(:snowplow_gitlab_standard_context) do
    { user: user, project: project, namespace: project.namespace, property: 'i_package_generic_user' }
  end

  def auth_header
    return {} if user_role == :anonymous

    case authenticate_with
    when :personal_access_token
      personal_access_token_header
    when :job_token
      job_token_header
    when :job_basic_auth
      job_basic_auth_header
    when :invalid_personal_access_token
      personal_access_token_header('wrong token')
    when :invalid_job_token
      job_token_header('wrong token')
    when :user_basic_auth
      user_basic_auth_header(user)
    when :invalid_user_basic_auth
      basic_auth_header('invalid user', 'invalid password')
    end
  end

  def deploy_token_auth_header
    case authenticate_with
    when :deploy_token_rw
      deploy_token_header(deploy_token_rw.token)
    when :deploy_token_ro
      deploy_token_header(deploy_token_ro.token)
    when :deploy_token_wo
      deploy_token_header(deploy_token_wo.token)
    when :invalid_deploy_token
      deploy_token_header('wrong token')
    end
  end

  def personal_access_token_header(value = nil)
    { Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER => value || personal_access_token.token }
  end

  def job_token_header(value = nil)
    { Gitlab::Auth::AuthFinders::JOB_TOKEN_HEADER => value || ci_build.token }
  end

  def job_basic_auth_header(value = nil)
    basic_auth_header(Gitlab::Auth::CI_JOB_USER, value || ci_build.token)
  end

  def deploy_token_header(value)
    { Gitlab::Auth::AuthFinders::DEPLOY_TOKEN_HEADER => value }
  end

  shared_examples 'secure endpoint' do
    before do
      project.add_developer(user)
    end

    it 'rejects malicious request' do
      subject

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/generic/:package_name/:package_version/(*path)/:file_name/authorize' do
    it_behaves_like 'enforcing job token policies', :admin_packages do
      before do
        source_project.add_developer(user)
      end

      let(:request) { authorize_upload_file(workhorse_headers.merge(job_token_header(target_job.token))) }
    end

    context 'with valid project' do
      where(:project_visibility, :user_role, :member?, :authenticate_with, :expected_status) do
        'PUBLIC'  | :developer | true  | :personal_access_token         | :success
        'PUBLIC'  | :guest     | true  | :personal_access_token         | :forbidden
        'PUBLIC'  | :developer | true  | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :guest     | true  | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :developer | true  | :user_basic_auth               | :success
        'PUBLIC'  | :guest     | true  | :user_basic_auth               | :forbidden
        'PUBLIC'  | :developer | true  | :invalid_user_basic_auth       | :unauthorized
        'PUBLIC'  | :guest     | true  | :invalid_user_basic_auth       | :unauthorized
        'PUBLIC'  | :developer | false | :personal_access_token         | :forbidden
        'PUBLIC'  | :guest     | false | :personal_access_token         | :forbidden
        'PUBLIC'  | :developer | false | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :guest     | false | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :developer | false | :user_basic_auth               | :forbidden
        'PUBLIC'  | :guest     | false | :user_basic_auth               | :forbidden
        'PUBLIC'  | :developer | false | :invalid_user_basic_auth       | :unauthorized
        'PUBLIC'  | :guest     | false | :invalid_user_basic_auth       | :unauthorized
        'PUBLIC'  | :anonymous | false | :none                          | :unauthorized
        'PRIVATE' | :developer | true  | :personal_access_token         | :success
        'PRIVATE' | :guest     | true  | :personal_access_token         | :forbidden
        'PRIVATE' | :developer | true  | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :guest     | true  | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :developer | true  | :user_basic_auth               | :success
        'PRIVATE' | :guest     | true  | :user_basic_auth               | :forbidden
        'PRIVATE' | :developer | true  | :invalid_user_basic_auth       | :unauthorized
        'PRIVATE' | :guest     | true  | :invalid_user_basic_auth       | :unauthorized
        'PRIVATE' | :developer | false | :personal_access_token         | :not_found
        'PRIVATE' | :guest     | false | :personal_access_token         | :not_found
        'PRIVATE' | :developer | false | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :guest     | false | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :developer | false | :user_basic_auth               | :not_found
        'PRIVATE' | :guest     | false | :user_basic_auth               | :not_found
        'PRIVATE' | :developer | false | :invalid_user_basic_auth       | :unauthorized
        'PRIVATE' | :guest     | false | :invalid_user_basic_auth       | :unauthorized
        'PRIVATE' | :anonymous | false | :none                          | :unauthorized
        'PUBLIC'  | :developer | true  | :job_token                     | :success
        'PUBLIC'  | :developer | true  | :invalid_job_token             | :unauthorized
        'PUBLIC'  | :developer | false | :job_token                     | :forbidden
        'PUBLIC'  | :developer | false | :invalid_job_token             | :unauthorized
        'PRIVATE' | :developer | true  | :job_token                     | :success
        'PRIVATE' | :developer | true  | :invalid_job_token             | :unauthorized
        'PRIVATE' | :developer | false | :job_token                     | :not_found
        'PRIVATE' | :developer | false | :invalid_job_token             | :unauthorized
      end

      with_them do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility, false))
          project.send("add_#{user_role}", user) if member? && user_role != :anonymous
        end

        it "responds with #{params[:expected_status]}" do
          authorize_upload_file(workhorse_headers.merge(auth_header))

          expect(response).to have_gitlab_http_status(expected_status)
        end
      end

      where(:authenticate_with, :expected_status) do
        :deploy_token_rw      | :success
        :deploy_token_wo      | :success
        :deploy_token_ro      | :forbidden
        :invalid_deploy_token | :unauthorized
      end

      with_them do
        it "responds with #{params[:expected_status]}" do
          authorize_upload_file(workhorse_headers.merge(deploy_token_auth_header))

          expect(response).to have_gitlab_http_status(expected_status)
        end
      end

      it_behaves_like 'updating personal access token last used' do
        subject { authorize_upload_file(workhorse_headers.merge(personal_access_token_header)) }
      end
    end

    context 'application security' do
      using RSpec::Parameterized::TableSyntax

      where(:param_name, :param_value) do
        :package_name | 'my-package/../'
        :package_name | 'my-package%2f%2e%2e%2f'
        :file_name    | '../.ssh%2fauthorized_keys'
        :file_name    | '%2e%2e%2f.ssh%2fauthorized_keys'
      end

      with_them do
        subject do
          authorize_upload_file(workhorse_headers.merge(personal_access_token_header), param_name => param_value)
        end

        it_behaves_like 'secure endpoint'
      end
    end

    context 'for use_final_store_path' do
      before do
        project.add_developer(user)
      end

      it 'sends use_final_store_path with true' do
        expect(::Packages::PackageFileUploader).to receive(:workhorse_authorize).with(
          hash_including(use_final_store_path: true, final_store_path_config: { root_hash: project.id })
        ).and_call_original

        authorize_upload_file(workhorse_headers.merge(personal_access_token_header))
      end
    end

    context 'with package protection rule for different roles and package_name_patterns' do
      let_it_be(:pat_developer) { create(:personal_access_token, user: create(:user, developer_of: project)) }
      let_it_be(:pat_developer_auth_header) { personal_access_token_header(pat_developer.token) }
      let_it_be(:pat_maintainer) { create(:personal_access_token, user: create(:user, maintainer_of: project)) }
      let_it_be(:pat_maintainer_auth_header) { personal_access_token_header(pat_maintainer.token) }
      let_it_be(:pat_owner) { create(:personal_access_token, user: create(:user, owner_of: project)) }
      let_it_be(:pat_owner_auth_header) { personal_access_token_header(pat_owner.token) }
      let_it_be(:pat_admin_mode) { create(:personal_access_token, :admin_mode, user: create(:admin)) }
      let_it_be(:pat_admin_mode_auth_header) { personal_access_token_header(pat_admin_mode.token) }
      let_it_be(:deploy_token_rw_auth_header) { deploy_token_header(deploy_token_rw.token) }

      let_it_be_with_reload(:package_protection_rule) do
        create(:package_protection_rule, package_type: :generic, project: project)
      end

      let(:protected_package_name) { 'mypackage' }
      let(:unprotected_package_name) { "other-#{protected_package_name}" }

      let(:request_headers) { workhorse_headers.merge(auth_header) }

      subject do
        authorize_upload_file(request_headers, package_name: protected_package_name)
        response
      end

      before do
        package_protection_rule.update!(
          package_name_pattern: package_name_pattern,
          minimum_access_level_for_push: minimum_access_level_for_push
        )
      end

      shared_examples 'authorized package' do
        it { is_expected.to have_gitlab_http_status(:ok) }
      end

      shared_examples 'protected package' do
        it 'responds with forbidden' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response).to include 'message' => '403 Forbidden - Package protected.'
        end
      end

      where(:package_name_pattern, :minimum_access_level_for_push, :auth_header, :shared_examples_name) do
        ref(:protected_package_name)   | :maintainer | ref(:deploy_token_rw_auth_header) | 'protected package'
        ref(:protected_package_name)   | :maintainer | ref(:pat_developer_auth_header)   | 'protected package'
        ref(:protected_package_name)   | :maintainer | ref(:pat_maintainer_auth_header)  | 'authorized package'
        ref(:protected_package_name)   | :owner      | ref(:deploy_token_rw_auth_header) | 'protected package'
        ref(:protected_package_name)   | :owner      | ref(:pat_developer_auth_header)   | 'protected package'
        ref(:protected_package_name)   | :owner      | ref(:pat_owner_auth_header)       | 'authorized package'
        ref(:protected_package_name)   | :admin      | ref(:deploy_token_rw_auth_header) | 'protected package'
        ref(:protected_package_name)   | :admin      | ref(:pat_admin_mode_auth_header)  | 'authorized package'
        ref(:protected_package_name)   | :admin      | ref(:pat_owner_auth_header)       | 'protected package'

        ref(:unprotected_package_name) | :admin      | ref(:deploy_token_rw_auth_header) | 'authorized package'
        ref(:unprotected_package_name) | :admin      | ref(:pat_owner_auth_header)       | 'authorized package'
        ref(:unprotected_package_name) | :maintainer | ref(:deploy_token_rw_auth_header) | 'authorized package'
        ref(:unprotected_package_name) | :maintainer | ref(:pat_developer_auth_header)   | 'authorized package'
        ref(:unprotected_package_name) | :maintainer | ref(:pat_maintainer_auth_header)  | 'authorized package'
      end

      with_them do
        it_behaves_like params[:shared_examples_name]
      end
    end

    def authorize_upload_file(request_headers, package_name: 'mypackage', file_name: 'myfile.tar.gz')
      url = "/projects/#{project.id}/packages/generic/#{package_name}/0.0.1/#{file_name}/authorize"

      put api(url), headers: request_headers
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/generic/:package_name/:package_version/(*path)/:file_name' do
    include WorkhorseHelpers

    let(:file_upload) { fixture_file_upload('spec/fixtures/packages/generic/myfile.tar.gz') }
    let(:params) { { file: file_upload } }

    it_behaves_like 'enforcing job token policies', :admin_packages do
      before do
        source_project.add_developer(user)
      end

      let(:request) { upload_file(params, workhorse_headers.merge(job_token_header(target_job.token))) }
    end

    context 'authentication' do
      where(:project_visibility, :user_role, :member?, :authenticate_with, :expected_status) do
        'PUBLIC'  | :guest     | true  | :personal_access_token         | :forbidden
        'PUBLIC'  | :guest     | true  | :user_basic_auth               | :forbidden
        'PUBLIC'  | :developer | true  | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :guest     | true  | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :developer | true  | :invalid_user_basic_auth       | :unauthorized
        'PUBLIC'  | :guest     | true  | :invalid_user_basic_auth       | :unauthorized
        'PUBLIC'  | :developer | false | :personal_access_token         | :forbidden
        'PUBLIC'  | :guest     | false | :personal_access_token         | :forbidden
        'PUBLIC'  | :developer | false | :user_basic_auth               | :forbidden
        'PUBLIC'  | :guest     | false | :user_basic_auth               | :forbidden
        'PUBLIC'  | :developer | false | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :guest     | false | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :developer | false | :invalid_user_basic_auth       | :unauthorized
        'PUBLIC'  | :guest     | false | :invalid_user_basic_auth       | :unauthorized
        'PUBLIC'  | :anonymous | false | :none                          | :unauthorized
        'PRIVATE' | :guest     | true  | :personal_access_token         | :forbidden
        'PRIVATE' | :guest     | true  | :user_basic_auth               | :forbidden
        'PRIVATE' | :developer | true  | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :guest     | true  | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :developer | true  | :invalid_user_basic_auth       | :unauthorized
        'PRIVATE' | :guest     | true  | :invalid_user_basic_auth       | :unauthorized
        'PRIVATE' | :developer | false | :personal_access_token         | :not_found
        'PRIVATE' | :guest     | false | :personal_access_token         | :not_found
        'PRIVATE' | :developer | false | :user_basic_auth               | :not_found
        'PRIVATE' | :guest     | false | :user_basic_auth               | :not_found
        'PRIVATE' | :developer | false | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :guest     | false | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :developer | false | :invalid_user_basic_auth       | :unauthorized
        'PRIVATE' | :guest     | false | :invalid_user_basic_auth       | :unauthorized
        'PRIVATE' | :anonymous | false | :none                          | :unauthorized
        'PUBLIC'  | :developer | true  | :invalid_job_token             | :unauthorized
        'PUBLIC'  | :developer | false | :job_token                     | :forbidden
        'PUBLIC'  | :developer | false | :invalid_job_token             | :unauthorized
        'PRIVATE' | :developer | true  | :invalid_job_token             | :unauthorized
        'PRIVATE' | :developer | false | :job_token                     | :not_found
        'PRIVATE' | :developer | false | :invalid_job_token             | :unauthorized
      end

      with_them do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility, false))
          project.send("add_#{user_role}", user) if member? && user_role != :anonymous
        end

        it "responds with #{params[:expected_status]}" do
          headers = workhorse_headers.merge(auth_header)

          upload_file(params, headers)

          expect(response).to have_gitlab_http_status(expected_status)
        end
      end

      where(:authenticate_with, :expected_status) do
        :deploy_token_ro      | :forbidden
        :invalid_deploy_token | :unauthorized
      end

      with_them do
        it "responds with #{params[:expected_status]}" do
          headers = workhorse_headers.merge(deploy_token_auth_header)

          upload_file(params, headers)

          expect(response).to have_gitlab_http_status(expected_status)
        end
      end
    end

    context 'when user can upload packages and has valid credentials' do
      before do
        project.add_developer(user)
      end

      shared_examples 'creates a package and package file' do
        it 'creates a package and package file' do
          headers = workhorse_headers.merge(auth_header)

          expect { upload_file(params, headers) }
            .to change { ::Packages::Generic::Package.for_projects(project).count }.by(1)
            .and change { Packages::PackageFile.count }.by(1)

          aggregate_failures do
            expect(response).to have_gitlab_http_status(:created)

            package = ::Packages::Generic::Package.for_projects(project).last
            expect(package.name).to eq('mypackage')
            expect(package.status).to eq('default')
            expect(package.version).to eq('0.0.1')

            if should_set_build_info
              expect(package.last_build_info.pipeline).to eq(ci_build.pipeline)
            else
              expect(package.last_build_info).to be_nil
            end

            package_file = package.package_files.last
            expect(package_file.file_name).to eq('myfile.tar.gz')
          end
        end

        context 'with select' do
          context 'with a valid value' do
            context 'package_file' do
              let(:params) { super().merge(select: 'package_file') }

              it 'returns a package file' do
                headers = workhorse_headers.merge(auth_header)

                upload_file(params, headers)

                aggregate_failures do
                  expect(response).to have_gitlab_http_status(:ok)
                  expect(json_response).to have_key('id')
                end
              end
            end
          end

          context 'with an invalid value' do
            let(:params) { super().merge(select: 'invalid_value') }

            it 'returns a package file' do
              headers = workhorse_headers.merge(auth_header)

              upload_file(params, headers)

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end

        context 'with a status' do
          context 'valid status' do
            let(:params) { super().merge(status: 'hidden') }

            it 'assigns the status to the package' do
              headers = workhorse_headers.merge(auth_header)

              upload_file(params, headers)

              aggregate_failures do
                expect(response).to have_gitlab_http_status(:created)

                package = ::Packages::Generic::Package.for_projects(project).find_by(name: 'mypackage')
                expect(package).to be_hidden
              end
            end
          end

          context 'invalid status' do
            let(:params) { super().merge(status: 'processing') }

            it 'rejects the package' do
              headers = workhorse_headers.merge(auth_header)

              upload_file(params, headers)

              aggregate_failures do
                expect(response).to have_gitlab_http_status(:bad_request)
              end
            end
          end

          context 'different versions' do
            where(:version, :expected_status) do
              '1.3.350-20201230123456'                   | :created
              '1.2.3'                                    | :created
              '1.2.3g'                                   | :created
              '1.2'                                      | :created
              '1.2.bananas'                              | :created
              'v1.2.4-build'                             | :created
              'd50d836eb3de6177ce6c7a5482f27f9c2c84b672' | :created
              '..1.2.3'                                  | :bad_request
              '1.2.3-4/../../'                           | :bad_request
              '%2e%2e%2f1.2.3'                           | :bad_request
            end

            with_them do
              let(:expected_package_diff_count) { expected_status == :created ? 1 : 0 }
              let(:headers) { workhorse_headers.merge(auth_header) }

              subject { upload_file(params, headers, package_version: version) }

              it "returns the #{params[:expected_status]}", :aggregate_failures do
                expect { subject }
                  .to change { ::Packages::Generic::Package.for_projects(project).count }
                  .by(expected_package_diff_count)

                expect(response).to have_gitlab_http_status(expected_status)
              end
            end
          end
        end

        context 'when file has path' do
          let(:params) { super().merge(path: 'path/to') }

          it 'creates a package and package file with path' do
            headers = workhorse_headers.merge(auth_header)

            upload_file(params, headers)

            aggregate_failures do
              package = ::Packages::Generic::Package.for_projects(project).last
              expect(response).to have_gitlab_http_status(:created)
              expect(package.package_files.last.file_name).to eq('path%2Fto%2Fmyfile.tar.gz')
            end
          end
        end

        context 'with special characters in filename' do
          where(:symbol, :file_name) do
            [
              ['+', 'my+file.tar.gz'],
              ['~', 'my~file.tar.gz'],
              ['@', 'myfile@1.1.tar.gz']
            ]
          end

          with_them do
            it "creates package with #{params[:symbol]} in the filename", :aggregate_failures do
              headers = workhorse_headers.merge(auth_header)

              expect do
                upload_file(params, headers, file_name:)
              end.to change { ::Packages::Generic::Package.for_projects(project).count }.by(1)

              expect(response).to have_gitlab_http_status(:created)
              expect(::Packages::PackageFile.for_projects(project).find_by(file_name:)).not_to be_nil
            end
          end
        end
      end

      context 'when filename contains @ or ~ symbol at beginning or end' do
        where(:symbol, :file_name, :description) do
          [
            ['@', 'myfile1.1.tar.gz@', 'at the end'],
            ['@', '@myfile1.1.tar.gz', 'at the beginning'],
            ['~', 'myfile.tar.gz~', 'at the end'],
            ['~', '~myfile.tar.gz', 'at the beginning']
          ]
        end

        with_them do
          it "returns a bad request when #{params[:symbol]} is #{params[:description]} of filename",
            :aggregate_failures do
            headers = workhorse_headers.merge(personal_access_token_header)

            upload_file(params, headers, file_name: file_name)

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'when valid personal access token is used' do
        it_behaves_like 'creates a package and package file' do
          let(:auth_header) { personal_access_token_header }
          let(:should_set_build_info) { false }
        end
      end

      context 'when valid basic auth is used' do
        it_behaves_like 'creates a package and package file' do
          let(:auth_header) { user_basic_auth_header(user) }
          let(:should_set_build_info) { false }
        end
      end

      context 'when valid deploy token is used' do
        it_behaves_like 'creates a package and package file' do
          let(:auth_header) { deploy_token_header(deploy_token_wo.token) }
          let(:should_set_build_info) { false }
        end
      end

      context 'when valid job token is used' do
        it_behaves_like 'creates a package and package file' do
          let(:auth_header) { job_token_header }
          let(:should_set_build_info) { true }
        end
      end

      context 'event tracking' do
        subject { upload_file(params, workhorse_headers.merge(personal_access_token_header)) }

        it_behaves_like 'a package tracking event', described_class.name, 'push_package'
      end

      context 'with existing package' do
        let_it_be(:package_name) { 'mypackage' }
        let_it_be(:package_version) { '1.2.3' }
        let_it_be(:existing_package) do
          create(:generic_package, name: package_name, version: package_version, project: project)
        end

        let_it_be(:duplicate_file) do
          create(:package_file, package: existing_package, file_name: 'myfile.tar.gz')
        end

        let_it_be_with_reload(:package_settings) { create(:namespace_package_setting, namespace: project.namespace) }

        let(:headers) { workhorse_headers.merge(personal_access_token_header) }

        subject(:upload_api_call) do
          upload_file(params, headers, package_name: package_name, package_version: package_version)
        end

        shared_examples 'creates a new package' do
          it 'creates a new package' do
            upload_api_call

            expect(response).to have_gitlab_http_status(:created)
          end
        end

        shared_examples 'returns a bad request' do
          it 'returns a bad request' do
            upload_api_call

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        it 'does not create a new package' do
          expect { upload_file(params, headers, package_name: package_name, package_version: package_version) }
            .to not_change { ::Packages::Generic::Package.for_projects(project).count }
            .and change { Packages::PackageFile.count }.by(1)

          expect(response).to have_gitlab_http_status(:created)
        end

        context 'when package duplicates are not allowed' do
          before do
            package_settings.update!(generic_duplicates_allowed: false, generic_duplicate_exception_regex: '')
          end

          it_behaves_like 'returns a bad request'

          context 'when regex matches package name' do
            before do
              package_settings.update_column(
                :generic_duplicate_exception_regex,
                ".*#{existing_package.name.last(3)}.*"
              )
            end

            it_behaves_like 'creates a new package'
          end

          context 'when regex matches package version' do
            before do
              package_settings.update_column(
                :generic_duplicate_exception_regex,
                ".*#{existing_package.version.last(3)}.*"
              )
            end

            it_behaves_like 'creates a new package'
          end

          context 'when regex does not match package name or version' do
            before do
              package_settings.update_column(:generic_duplicate_exception_regex, ".*zzz.*")
            end

            it_behaves_like 'returns a bad request'
          end
        end

        context 'when package duplicates are allowed' do
          before do
            package_settings.update!(generic_duplicates_allowed: true, generic_duplicate_exception_regex: '')
          end

          it_behaves_like 'creates a new package'

          context 'when regex matches package name' do
            before do
              package_settings.update_column(
                :generic_duplicate_exception_regex,
                ".*#{existing_package.name.last(3)}.*"
              )
            end

            it_behaves_like 'returns a bad request'
          end

          context 'when regex matches package version' do
            before do
              package_settings.update_column(
                :generic_duplicate_exception_regex,
                ".*#{existing_package.version.last(3)}.*"
              )
            end

            it_behaves_like 'returns a bad request'
          end

          context 'when regex does not match package name or version' do
            before do
              package_settings.update_column(:generic_duplicate_exception_regex, ".*zzz.*")
            end

            it_behaves_like 'creates a new package'
          end
        end

        context 'marked as pending_destruction' do
          it 'does create a new package' do
            existing_package.pending_destruction!
            expect { upload_file(params, headers, package_name: package_name, package_version: package_version) }
              .to change { ::Packages::Generic::Package.for_projects(project).count }.by(1)
              .and change { Packages::PackageFile.count }.by(1)

            expect(response).to have_gitlab_http_status(:created)
          end
        end
      end

      it 'rejects request without a file from workhorse' do
        headers = workhorse_headers.merge(personal_access_token_header)
        upload_file({}, headers)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'rejects request without an auth token' do
        upload_file(params, workhorse_headers)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'rejects request without workhorse rewritten fields' do
        headers = workhorse_headers.merge(personal_access_token_header)
        upload_file(params, headers, send_rewritten_field: false)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'rejects request if file size is too large' do
        allow_next_instance_of(UploadedFile) do |uploaded_file|
          allow(uploaded_file).to receive(:size).and_return(project.actual_limits.generic_packages_max_file_size + 1)
        end

        headers = workhorse_headers.merge(personal_access_token_header)
        upload_file(params, headers)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'rejects request without workhorse header' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).once

        upload_file(params, personal_access_token_header)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'application security' do
      where(:param_name, :param_value) do
        :package_name | 'my-package/../'
        :package_name | 'my-package%2f%2e%2e%2f'
        :file_name    | '../.ssh%2fauthorized_keys'
        :file_name    | '%2e%2e%2f.ssh%2fauthorized_keys'
      end

      with_them do
        subject do
          upload_file(params, workhorse_headers.merge(personal_access_token_header), param_name => param_value)
        end

        it_behaves_like 'secure endpoint'
      end
    end

    context 'with package protection rule for different roles and package_name_patterns' do
      let_it_be(:pat_developer) { create(:personal_access_token, user: create(:user, developer_of: project)) }
      let_it_be(:pat_developer_auth_header) { personal_access_token_header(pat_developer.token) }
      let_it_be(:pat_maintainer) { create(:personal_access_token, user: create(:user, maintainer_of: project)) }
      let_it_be(:pat_maintainer_auth_header) { personal_access_token_header(pat_maintainer.token) }
      let_it_be(:pat_owner) { create(:personal_access_token, user: create(:user, owner_of: project)) }
      let_it_be(:pat_owner_auth_header) { personal_access_token_header(pat_owner.token) }
      let_it_be(:pat_admin_mode) { create(:personal_access_token, :admin_mode, user: create(:admin)) }
      let_it_be(:pat_admin_mode_auth_header) { personal_access_token_header(pat_admin_mode.token) }
      let_it_be(:deploy_token_rw_auth_header) { deploy_token_header(deploy_token_rw.token) }

      let_it_be_with_reload(:package_protection_rule) do
        create(:package_protection_rule, package_type: :generic, project: project)
      end

      let(:package_name) { 'mypackage' }
      let(:package_name_no_match) { "other-#{package_name}" }

      let(:request_headers) { workhorse_headers.merge(auth_header) }

      subject(:send_upload_file) do
        upload_file(params, request_headers, package_name: package_name)
        response
      end

      before do
        package_protection_rule.update!(
          package_name_pattern: package_name_pattern,
          minimum_access_level_for_push: minimum_access_level_for_push
        )
      end

      shared_examples 'uploaded package' do
        it { is_expected.to have_gitlab_http_status(:created) }

        it 'creates a package and package file' do
          expect { send_upload_file }
            .to change { ::Packages::Generic::Package.for_projects(project).count }.by(1)
            .and change { Packages::PackageFile.count }.by(1)
        end
      end

      shared_examples 'protected package' do
        it 'responds with forbidden' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response).to include 'message' => '403 Forbidden - Package protected.'
        end
      end

      where(:package_name_pattern, :minimum_access_level_for_push, :auth_header, :shared_examples_name) do
        ref(:package_name)          | :maintainer | ref(:deploy_token_rw_auth_header) | 'protected package'
        ref(:package_name)          | :maintainer | ref(:pat_developer_auth_header)   | 'protected package'
        ref(:package_name)          | :maintainer | ref(:pat_maintainer_auth_header)  | 'uploaded package'
        ref(:package_name)          | :maintainer | ref(:pat_admin_mode_auth_header)  | 'uploaded package'
        ref(:package_name)          | :owner      | ref(:deploy_token_rw_auth_header) | 'protected package'
        ref(:package_name)          | :owner      | ref(:pat_developer_auth_header)   | 'protected package'
        ref(:package_name)          | :owner      | ref(:pat_owner_auth_header)       | 'uploaded package'
        ref(:package_name)          | :owner      | ref(:pat_admin_mode_auth_header)  | 'uploaded package'
        ref(:package_name)          | :admin      | ref(:deploy_token_rw_auth_header) | 'protected package'
        ref(:package_name)          | :admin      | ref(:pat_owner_auth_header)       | 'protected package'
        ref(:package_name)          | :admin      | ref(:pat_admin_mode_auth_header)  | 'uploaded package'

        ref(:package_name_no_match) | :maintainer | ref(:deploy_token_rw_auth_header) | 'uploaded package'
        ref(:package_name_no_match) | :maintainer | ref(:pat_developer_auth_header)   | 'uploaded package'
        ref(:package_name_no_match) | :maintainer | ref(:pat_maintainer_auth_header)  | 'uploaded package'
        ref(:package_name_no_match) | :admin      | ref(:deploy_token_rw_auth_header) | 'uploaded package'
        ref(:package_name_no_match) | :admin      | ref(:pat_owner_auth_header)       | 'uploaded package'
        ref(:package_name_no_match) | :admin      | ref(:pat_admin_mode_auth_header)  | 'uploaded package'
      end

      with_them do
        it_behaves_like params[:shared_examples_name]
      end
    end

    it_behaves_like 'updating personal access token last used' do
      subject { upload_file(params, workhorse_headers.merge(personal_access_token_header)) }
    end

    def upload_file(
      params, request_headers, send_rewritten_field: true, package_name: 'mypackage',
      package_version: '0.0.1', file_name: 'myfile.tar.gz')
      url = "/projects/#{project.id}/packages/generic/#{package_name}/#{package_version}/#{file_name}"

      workhorse_finalize(
        api(url),
        method: :put,
        file_key: :file,
        params: params,
        headers: request_headers,
        send_rewritten_field: send_rewritten_field
      )
    end
  end

  describe 'GET /api/v4/projects/:id/packages/generic/:package_name/:package_version/(*path)/:file_name' do
    let_it_be(:package) { create(:generic_package, project: project) }
    let_it_be(:package_file) { create(:package_file, :generic, package: package) }

    it_behaves_like 'enforcing job token policies', :read_packages,
      allow_public_access_for_enabled_project_features: :package_registry do
      before do
        source_project.add_developer(user)
      end

      let(:request) do
        download_file(job_token_header(target_job.token))
      end
    end

    context 'authentication' do
      where(:project_visibility, :user_role, :member?, :authenticate_with, :expected_status) do
        'PUBLIC'  | :developer | true  | :personal_access_token         | :success
        'PUBLIC'  | :guest     | true  | :personal_access_token         | :success
        'PUBLIC'  | :developer | true  | :user_basic_auth               | :success
        'PUBLIC'  | :guest     | true  | :user_basic_auth               | :success
        'PUBLIC'  | :developer | true  | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :guest     | true  | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :developer | true  | :invalid_user_basic_auth       | :success
        'PUBLIC'  | :guest     | true  | :invalid_user_basic_auth       | :success
        'PUBLIC'  | :developer | false | :personal_access_token         | :success
        'PUBLIC'  | :guest     | false | :personal_access_token         | :success
        'PUBLIC'  | :developer | false | :user_basic_auth               | :success
        'PUBLIC'  | :guest     | false | :user_basic_auth               | :success
        'PUBLIC'  | :developer | false | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :guest     | false | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :developer | false | :invalid_user_basic_auth       | :success
        'PUBLIC'  | :guest     | false | :invalid_user_basic_auth       | :success
        'PUBLIC'  | :anonymous | false | :none                          | :success
        'PRIVATE' | :developer | true  | :personal_access_token         | :success
        'PRIVATE' | :guest     | true  | :personal_access_token         | :success
        'PRIVATE' | :developer | true  | :user_basic_auth               | :success
        'PRIVATE' | :guest     | true  | :user_basic_auth               | :success
        'PRIVATE' | :developer | true  | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :guest     | true  | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :developer | true  | :invalid_user_basic_auth       | :unauthorized
        'PRIVATE' | :guest     | true  | :invalid_user_basic_auth       | :unauthorized
        'PRIVATE' | :developer | false | :personal_access_token         | :not_found
        'PRIVATE' | :guest     | false | :personal_access_token         | :not_found
        'PRIVATE' | :developer | false | :user_basic_auth               | :not_found
        'PRIVATE' | :guest     | false | :user_basic_auth               | :not_found
        'PRIVATE' | :developer | false | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :guest     | false | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :developer | false | :invalid_user_basic_auth       | :unauthorized
        'PRIVATE' | :guest     | false | :invalid_user_basic_auth       | :unauthorized
        'PRIVATE' | :anonymous | false | :none                          | :unauthorized
        'PUBLIC'  | :developer | true  | :job_token                     | :success
        'PUBLIC'  | :developer | true  | :job_basic_auth                | :success
        'PUBLIC'  | :developer | true  | :invalid_job_token             | :unauthorized
        'PUBLIC'  | :developer | false | :job_token                     | :success
        'PUBLIC'  | :developer | false | :job_basic_auth                | :success
        'PUBLIC'  | :developer | false | :invalid_job_token             | :unauthorized
        'PRIVATE' | :developer | true  | :job_token                     | :success
        'PRIVATE' | :developer | true  | :job_basic_auth                | :success
        'PRIVATE' | :developer | true  | :invalid_job_token             | :unauthorized
        'PRIVATE' | :developer | false | :job_token                     | :not_found
        'PRIVATE' | :developer | false | :job_basic_auth                | :not_found
        'PRIVATE' | :developer | false | :invalid_job_token             | :unauthorized
      end

      with_them do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility, false))
          project.send("add_#{user_role}", user) if member? && user_role != :anonymous
        end

        it "responds with #{params[:expected_status]}" do
          download_file(auth_header)

          expect(response).to have_gitlab_http_status(expected_status)
        end

        if params[:expected_status] == :success
          it_behaves_like 'bumping the package last downloaded at field' do
            subject { download_file(auth_header) }
          end
        end
      end

      where(:authenticate_with, :expected_status) do
        :deploy_token_rw      | :success
        :deploy_token_wo      | :success
        :deploy_token_ro      | :success
        :invalid_deploy_token | :unauthorized
      end

      with_them do
        it "responds with #{params[:expected_status]}" do
          download_file(deploy_token_auth_header)

          expect(response).to have_gitlab_http_status(expected_status)
        end

        if params[:expected_status] == :success
          it_behaves_like 'bumping the package last downloaded at field' do
            subject { download_file(deploy_token_auth_header) }
          end
        end
      end
    end

    context 'with access to package registry for everyone' do
      let_it_be(:user_role) { :anonymous }

      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
      end

      it 'responds with success' do
        download_file(auth_header)

        expect(response).to have_gitlab_http_status(:success)
      end
    end

    context 'with package status' do
      where(:package_status, :expected_status) do
        :default      | :success
        :hidden       | :success
        :error        | :not_found
      end

      with_them do
        before do
          project.add_developer(user)
          package.update!(status: package_status)
        end

        it "responds with #{params[:expected_status]}" do
          download_file(personal_access_token_header)

          expect(response).to have_gitlab_http_status(expected_status)
        end

        if params[:expected_status] == :success
          it_behaves_like 'bumping the package last downloaded at field' do
            subject { download_file(personal_access_token_header) }
          end
        end
      end
    end

    context 'event tracking' do
      before do
        project.add_developer(user)
      end

      subject { download_file(personal_access_token_header) }

      it_behaves_like 'a package tracking event', described_class.name, 'pull_package'
    end

    it 'rejects a malicious file name request' do
      project.add_developer(user)

      download_file(personal_access_token_header, file_name: '../.ssh%2fauthorized_keys')

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'rejects a malicious file name request' do
      project.add_developer(user)

      download_file(personal_access_token_header, file_name: '%2e%2e%2f.ssh%2fauthorized_keys')

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'rejects a malicious package name request' do
      project.add_developer(user)

      download_file(personal_access_token_header, package_name: 'my-package/../')

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'rejects a malicious package name request' do
      project.add_developer(user)

      download_file(personal_access_token_header, package_name: 'my-package%2f%2e%2e%2f')

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    context 'application security' do
      where(:param_name, :param_value) do
        :package_name | 'my-package/../'
        :package_name | 'my-package%2f%2e%2e%2f'
        :file_name    | '../.ssh%2fauthorized_keys'
        :file_name    | '%2e%2e%2f.ssh%2fauthorized_keys'
      end

      with_them do
        subject { download_file(personal_access_token_header, param_name => param_value) }

        it_behaves_like 'secure endpoint'
      end
    end

    it 'responds with 404 Not Found for non existing package' do
      project.add_developer(user)

      download_file(personal_access_token_header, package_name: 'no-such-package')

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'responds with 404 Not Found for non existing package file' do
      project.add_developer(user)

      download_file(personal_access_token_header, file_name: 'no-such-file')

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context 'when file has path' do
      let_it_be(:file_path) { "path/to/#{package_file.file_name}" }

      before do
        project.add_developer(user)
        package_file.update_column(:file_name, URI.encode_uri_component(file_path))
      end

      it 'responds with 200 OK' do
        download_file(personal_access_token_header, file_name: file_path)

        expect(response).to have_gitlab_http_status(:success)
      end
    end

    context 'when there is + sign is in filename' do
      let(:file_name) { 'my+file.tar.gz' }

      before do
        project.add_developer(user)
        package_file.update_column(:file_name, file_name)
      end

      it 'responds with 200 OK' do
        download_file(personal_access_token_header, file_name: file_name)

        expect(response).to have_gitlab_http_status(:success)
      end
    end

    context 'when object storage is enabled' do
      let(:package_file) { create(:package_file, :generic, :object_storage, package: package) }

      subject(:download) { download_file(personal_access_token_header) }

      before do
        project.add_developer(user)
      end

      context 'when direct download is enabled' do
        let(:disposition_param) do
          "response-content-disposition=attachment%3B%20filename%3D%22#{package_file.file_name}"
        end

        before do
          stub_package_file_object_storage
        end

        it 'includes response-content-disposition and filename in the redirect file URL' do
          download

          expect(response.parsed_body).to include(disposition_param)
          expect(response).to have_gitlab_http_status(:redirect)
        end
      end

      context 'when direct download is disabled' do
        let(:disposition_header) do
          "attachment; filename=\"#{package_file.file_name}\"; filename*=UTF-8\'\'#{package_file.file_name}"
        end

        let(:expected_headers) do
          {
            allow_localhost: true,
            allowed_endpoints: [],
            response_headers: {
              'Content-Disposition' => disposition_header
            },
            ssrf_filter: true
          }
        end

        before do
          stub_package_file_object_storage(proxy_download: true)
        end

        it 'sends a file with response-content-disposition and filename' do
          expect(::Gitlab::Workhorse).to receive(:send_url)
            .with(instance_of(String), expected_headers)
            .and_call_original

          download

          expect(response).to have_gitlab_http_status(:ok)
        end

        it_behaves_like 'package registry SSRF protection'
      end
    end

    it_behaves_like 'updating personal access token last used' do
      subject { download_file(personal_access_token_header) }
    end

    def download_file(request_headers, package_name: nil, file_name: nil)
      package_name ||= package.name
      file_name ||= package_file.file_name
      url = "/projects/#{project.id}/packages/generic/#{package_name}/#{package.version}/#{file_name}"

      get api(url), headers: request_headers
    end
  end
end
