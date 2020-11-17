# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GenericPackages do
  let_it_be(:personal_access_token) { create(:personal_access_token) }
  let_it_be(:project, reload: true) { create(:project) }
  let(:workhorse_token) { JWT.encode({ 'iss' => 'gitlab-workhorse' }, Gitlab::Workhorse.secret, 'HS256') }
  let(:workhorse_header) { { 'GitLab-Workhorse' => '1.0', Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER => workhorse_token } }
  let(:user) { personal_access_token.user }
  let(:ci_build) { create(:ci_build, :running, user: user) }

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
    end
  end

  def personal_access_token_header(value = nil)
    { Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER => value || personal_access_token.token }
  end

  def job_token_header(value = nil)
    { Gitlab::Auth::AuthFinders::JOB_TOKEN_HEADER => value || ci_build.token }
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
      using RSpec::Parameterized::TableSyntax

      where(:project_visibility, :user_role, :member?, :authenticate_with, :expected_status) do
        'PUBLIC'  | :developer | true  | :personal_access_token         | :success
        'PUBLIC'  | :guest     | true  | :personal_access_token         | :forbidden
        'PUBLIC'  | :developer | true  | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :guest     | true  | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :developer | false | :personal_access_token         | :forbidden
        'PUBLIC'  | :guest     | false | :personal_access_token         | :forbidden
        'PUBLIC'  | :developer | false | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :guest     | false | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :anonymous | false | :none                          | :unauthorized
        'PRIVATE' | :developer | true  | :personal_access_token         | :success
        'PRIVATE' | :guest     | true  | :personal_access_token         | :forbidden
        'PRIVATE' | :developer | true  | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :guest     | true  | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :developer | false | :personal_access_token         | :not_found
        'PRIVATE' | :guest     | false | :personal_access_token         | :not_found
        'PRIVATE' | :developer | false | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :guest     | false | :invalid_personal_access_token | :unauthorized
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
          authorize_upload_file(workhorse_header.merge(auth_header))

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
        subject { authorize_upload_file(workhorse_header.merge(personal_access_token_header), param_name => param_value) }

        it_behaves_like 'secure endpoint'
      end
    end

    context 'generic_packages feature flag is disabled' do
      it 'responds with 404 Not Found' do
        stub_feature_flags(generic_packages: false)
        project.add_developer(user)

        authorize_upload_file(workhorse_header.merge(personal_access_token_header))

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
      using RSpec::Parameterized::TableSyntax

      where(:project_visibility, :user_role, :member?, :authenticate_with, :expected_status) do
        'PUBLIC'  | :guest     | true  | :personal_access_token         | :forbidden
        'PUBLIC'  | :developer | true  | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :guest     | true  | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :developer | false | :personal_access_token         | :forbidden
        'PUBLIC'  | :guest     | false | :personal_access_token         | :forbidden
        'PUBLIC'  | :developer | false | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :guest     | false | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :anonymous | false | :none                          | :unauthorized
        'PRIVATE' | :guest     | true  | :personal_access_token         | :forbidden
        'PRIVATE' | :developer | true  | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :guest     | true  | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :developer | false | :personal_access_token         | :not_found
        'PRIVATE' | :guest     | false | :personal_access_token         | :not_found
        'PRIVATE' | :developer | false | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :guest     | false | :invalid_personal_access_token | :unauthorized
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
          headers = workhorse_header.merge(auth_header)

          upload_file(params, headers)

          expect(response).to have_gitlab_http_status(expected_status)
        end
      end
    end

    context 'when user can upload packages and has valid credentials' do
      before do
        project.add_developer(user)
      end

      it 'creates package and package file when valid personal access token is used' do
        headers = workhorse_header.merge(personal_access_token_header)

        expect { upload_file(params, headers) }
          .to change { project.packages.generic.count }.by(1)
          .and change { Packages::PackageFile.count }.by(1)

        aggregate_failures do
          expect(response).to have_gitlab_http_status(:created)

          package = project.packages.generic.last
          expect(package.name).to eq('mypackage')
          expect(package.version).to eq('0.0.1')
          expect(package.original_build_info).to be_nil

          package_file = package.package_files.last
          expect(package_file.file_name).to eq('myfile.tar.gz')
        end
      end

      it 'creates package, package file, and package build info when valid job token is used' do
        headers = workhorse_header.merge(job_token_header)

        expect { upload_file(params, headers) }
          .to change { project.packages.generic.count }.by(1)
          .and change { Packages::PackageFile.count }.by(1)

        aggregate_failures do
          expect(response).to have_gitlab_http_status(:created)

          package = project.packages.generic.last
          expect(package.name).to eq('mypackage')
          expect(package.version).to eq('0.0.1')
          expect(package.original_build_info.pipeline).to eq(ci_build.pipeline)

          package_file = package.package_files.last
          expect(package_file.file_name).to eq('myfile.tar.gz')
        end
      end

      context 'event tracking' do
        subject { upload_file(params, workhorse_header.merge(personal_access_token_header)) }

        it_behaves_like 'a gitlab tracking event', described_class.name, 'push_package'
      end

      it 'rejects request without a file from workhorse' do
        headers = workhorse_header.merge(personal_access_token_header)
        upload_file({}, headers)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'rejects request without an auth token' do
        upload_file(params, workhorse_header)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'rejects request without workhorse rewritten fields' do
        headers = workhorse_header.merge(personal_access_token_header)
        upload_file(params, headers, send_rewritten_field: false)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'rejects request if file size is too large' do
        allow_next_instance_of(UploadedFile) do |uploaded_file|
          allow(uploaded_file).to receive(:size).and_return(project.actual_limits.generic_packages_max_file_size + 1)
        end

        headers = workhorse_header.merge(personal_access_token_header)
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
      using RSpec::Parameterized::TableSyntax

      where(:param_name, :param_value) do
        :package_name | 'my-package/../'
        :package_name | 'my-package%2f%2e%2e%2f'
        :file_name    | '../.ssh%2fauthorized_keys'
        :file_name    | '%2e%2e%2f.ssh%2fauthorized_keys'
      end

      with_them do
        subject { upload_file(params, workhorse_header.merge(personal_access_token_header), param_name => param_value) }

        it_behaves_like 'secure endpoint'
      end
    end

    def upload_file(params, request_headers, send_rewritten_field: true, package_name: 'mypackage', file_name: 'myfile.tar.gz')
      url = "/projects/#{project.id}/packages/generic/#{package_name}/0.0.1/#{file_name}"

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
    using RSpec::Parameterized::TableSyntax

    let_it_be(:package) { create(:generic_package, project: project) }
    let_it_be(:package_file) { create(:package_file, :generic, package: package) }

    context 'authentication' do
      where(:project_visibility, :user_role, :member?, :authenticate_with, :expected_status) do
        'PUBLIC'  | :developer | true  | :personal_access_token         | :success
        'PUBLIC'  | :guest     | true  | :personal_access_token         | :success
        'PUBLIC'  | :developer | true  | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :guest     | true  | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :developer | false | :personal_access_token         | :success
        'PUBLIC'  | :guest     | false | :personal_access_token         | :success
        'PUBLIC'  | :developer | false | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :guest     | false | :invalid_personal_access_token | :unauthorized
        'PUBLIC'  | :anonymous | false | :none                          | :unauthorized
        'PRIVATE' | :developer | true  | :personal_access_token         | :success
        'PRIVATE' | :guest     | true  | :personal_access_token         | :forbidden
        'PRIVATE' | :developer | true  | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :guest     | true  | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :developer | false | :personal_access_token         | :not_found
        'PRIVATE' | :guest     | false | :personal_access_token         | :not_found
        'PRIVATE' | :developer | false | :invalid_personal_access_token | :unauthorized
        'PRIVATE' | :guest     | false | :invalid_personal_access_token | :unauthorized
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
      using RSpec::Parameterized::TableSyntax

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
