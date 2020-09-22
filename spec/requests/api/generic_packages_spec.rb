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

  describe 'PUT /api/v4/projects/:id/packages/generic/mypackage/0.0.1/myfile.tar.gz/authorize' do
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
          headers = workhorse_header.merge(auth_header)
          url = "/projects/#{project.id}/packages/generic/mypackage/0.0.1/myfile.tar.gz/authorize"

          put api(url), headers: headers

          expect(response).to have_gitlab_http_status(expected_status)
        end
      end
    end

    it 'rejects a malicious request' do
      project.add_developer(user)
      headers = workhorse_header.merge(personal_access_token_header)
      url = "/projects/#{project.id}/packages/generic/mypackage/0.0.1/%2e%2e%2f.ssh%2fauthorized_keys/authorize"

      put api(url), headers: headers

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    context 'generic_packages feature flag is disabled' do
      it 'responds with 404 Not Found' do
        stub_feature_flags(generic_packages: false)
        project.add_developer(user)
        headers = workhorse_header.merge(personal_access_token_header)
        url = "/projects/#{project.id}/packages/generic/mypackage/0.0.1/myfile.tar.gz/authorize"

        put api(url), headers: headers

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/generic/mypackage/0.0.1/myfile.tar.gz' do
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
          expect(package.build_info).to be_nil

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
          expect(package.build_info.pipeline).to eq(ci_build.pipeline)

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

      it 'rejects a malicious request' do
        headers = workhorse_header.merge(personal_access_token_header)
        upload_file(params, headers, file_name: '%2e%2e%2f.ssh%2fauthorized_keys')

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    def upload_file(params, request_headers, send_rewritten_field: true, file_name: 'myfile.tar.gz')
      url = "/projects/#{project.id}/packages/generic/mypackage/0.0.1/#{file_name}"

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
end
