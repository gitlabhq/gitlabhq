# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GenericPackages do
  include HttpBasicAuthHelpers
  using RSpec::Parameterized::TableSyntax

  include_context 'workhorse headers'

  let_it_be(:personal_access_token) { create(:personal_access_token) }
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:deploy_token_rw) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token_rw) { create(:project_deploy_token, deploy_token: deploy_token_rw, project: project) }
  let_it_be(:deploy_token_ro) { create(:deploy_token, read_package_registry: true, write_package_registry: false) }
  let_it_be(:project_deploy_token_ro) { create(:project_deploy_token, deploy_token: deploy_token_ro, project: project) }
  let_it_be(:deploy_token_wo) { create(:deploy_token, read_package_registry: false, write_package_registry: true) }
  let_it_be(:project_deploy_token_wo) { create(:project_deploy_token, deploy_token: deploy_token_wo, project: project) }

  let(:user) { personal_access_token.user }
  let(:ci_build) { create(:ci_build, :running, user: user, project: project) }
  let(:snowplow_standard_context_params) { { user: user, project: project, namespace: project.namespace } }

  def auth_header
    return {} if user_role == :anonymous

    case authenticate_with
    when :personal_access_token
      personal_access_token_header
    when :job_token
      job_token_header
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

  describe 'PUT /api/v4/projects/:id/packages/generic/:package_name/:package_version/:file_name/authorize' do
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
        subject { authorize_upload_file(workhorse_headers.merge(personal_access_token_header), param_name => param_value) }

        it_behaves_like 'secure endpoint'
      end
    end

    context 'generic_packages feature flag is disabled' do
      it 'responds with 404 Not Found' do
        stub_feature_flags(generic_packages: false)
        project.add_developer(user)

        authorize_upload_file(workhorse_headers.merge(personal_access_token_header))

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def authorize_upload_file(request_headers, package_name: 'mypackage', file_name: 'myfile.tar.gz')
      url = "/projects/#{project.id}/packages/generic/#{package_name}/0.0.1/#{file_name}/authorize"

      put api(url), headers: request_headers
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/generic/:package_name/:package_version/:file_name' do
    include WorkhorseHelpers

    let(:file_upload) { fixture_file_upload('spec/fixtures/packages/generic/myfile.tar.gz') }
    let(:params) { { file: file_upload } }

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
            .to change { project.packages.generic.count }.by(1)
            .and change { Packages::PackageFile.count }.by(1)

          aggregate_failures do
            expect(response).to have_gitlab_http_status(:created)

            package = project.packages.generic.last
            expect(package.name).to eq('mypackage')
            expect(package.status).to eq('default')
            expect(package.version).to eq('0.0.1')

            if should_set_build_info
              expect(package.original_build_info.pipeline).to eq(ci_build.pipeline)
            else
              expect(package.original_build_info).to be_nil
            end

            package_file = package.package_files.last
            expect(package_file.file_name).to eq('myfile.tar.gz')
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

                package = project.packages.find_by(name: 'mypackage')
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
                expect { subject }.to change { project.packages.generic.count }.by(expected_package_diff_count)

                expect(response).to have_gitlab_http_status(expected_status)
              end
            end
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

        it_behaves_like 'a gitlab tracking event', described_class.name, 'push_package'
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
        subject { upload_file(params, workhorse_headers.merge(personal_access_token_header), param_name => param_value) }

        it_behaves_like 'secure endpoint'
      end
    end

    def upload_file(params, request_headers, send_rewritten_field: true, package_name: 'mypackage', package_version: '0.0.1', file_name: 'myfile.tar.gz')
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

  describe 'GET /api/v4/projects/:id/packages/generic/:package_name/:package_version/:file_name' do
    let_it_be(:package) { create(:generic_package, project: project) }
    let_it_be(:package_file) { create(:package_file, :generic, package: package) }

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
        'PRIVATE' | :guest     | true  | :personal_access_token         | :forbidden
        'PRIVATE' | :developer | true  | :user_basic_auth               | :success
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
        'PUBLIC'  | :developer | true  | :job_token                     | :success
        'PUBLIC'  | :developer | true  | :invalid_job_token             | :unauthorized
        'PUBLIC'  | :developer | false | :job_token                     | :success
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
          download_file(auth_header)

          expect(response).to have_gitlab_http_status(expected_status)
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
      end
    end

    context 'event tracking' do
      before do
        project.add_developer(user)
      end

      subject { download_file(personal_access_token_header) }

      it_behaves_like 'a gitlab tracking event', described_class.name, 'pull_package'
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

    def download_file(request_headers, package_name: nil, file_name: nil)
      package_name ||= package.name
      file_name ||= package_file.file_name
      url = "/projects/#{project.id}/packages/generic/#{package_name}/#{package.version}/#{file_name}"

      get api(url), headers: request_headers
    end
  end
end
