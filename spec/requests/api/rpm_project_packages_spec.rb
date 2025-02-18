# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::RpmProjectPackages, feature_category: :package_registry do
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

  include_context 'workhorse headers'

  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group, :public) }
  let_it_be_with_reload(:project) { create(:project, :public, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }
  let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }

  let(:headers) { {} }
  let(:package_name) { 'rpm-package.0-1.x86_64.rpm' }
  let(:package_file_id) { 1 }

  shared_examples 'rejects rpm packages access' do |status|
    it_behaves_like 'returning response status', status

    if status == :unauthorized
      it 'has the correct response header' do
        subject

        expect(response.headers['WWW-Authenticate']).to eq 'Basic realm="GitLab Packages Registry"'
      end
    end
  end

  shared_examples 'process rpm packages upload/download' do |status|
    it_behaves_like 'returning response status', status
  end

  shared_examples 'a deploy token for RPM requests' do |success_status = :not_found|
    context 'with deploy token headers' do
      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
      end

      let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token) }

      context 'when token is valid' do
        it_behaves_like 'returning response status', success_status
      end

      context 'when token is invalid' do
        let(:headers) { basic_auth_header(deploy_token.username, 'bar') }

        it_behaves_like 'returning response status', :unauthorized
      end
    end
  end

  shared_examples 'a job token for RPM requests' do |success_status = :not_found|
    context 'with job token headers' do
      let(:headers) { basic_auth_header(::Gitlab::Auth::CI_JOB_USER, job.token) }

      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
        project.add_developer(user)
      end

      context 'with valid token' do
        it_behaves_like 'returning response status', success_status
      end

      context 'with invalid token' do
        let(:headers) { basic_auth_header(::Gitlab::Auth::CI_JOB_USER, 'bar') }

        it_behaves_like 'returning response status', :unauthorized
      end

      context 'with invalid user' do
        let(:headers) { basic_auth_header('foo', job.token) }

        it_behaves_like 'returning response status', :unauthorized
      end
    end
  end

  shared_examples 'a user token for RPM requests' do |success_status = :not_found|
    context 'with valid project' do
      where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
        'PUBLIC'  | :developer  | true  | true  | 'process rpm packages upload/download' | success_status
        'PUBLIC'  | :guest      | true  | true  | 'process rpm packages upload/download' | success_status
        'PUBLIC'  | :developer  | true  | false | 'rejects rpm packages access'          | :unauthorized
        'PUBLIC'  | :guest      | true  | false | 'rejects rpm packages access'          | :unauthorized
        'PUBLIC'  | :developer  | false | true  | 'process rpm packages upload/download' | :not_found
        'PUBLIC'  | :guest      | false | true  | 'process rpm packages upload/download' | :not_found
        'PUBLIC'  | :developer  | false | false | 'rejects rpm packages access'          | :unauthorized
        'PUBLIC'  | :guest      | false | false | 'rejects rpm packages access'          | :unauthorized
        'PUBLIC'  | :anonymous  | false | true  | 'process rpm packages upload/download' | :unauthorized
        'PRIVATE' | :developer  | true  | true  | 'process rpm packages upload/download' | success_status
        'PRIVATE' | :guest      | true  | true  | 'process rpm packages upload/download' | success_status
        'PRIVATE' | :developer  | true  | false | 'rejects rpm packages access'          | :unauthorized
        'PRIVATE' | :guest      | true  | false | 'rejects rpm packages access'          | :unauthorized
        'PRIVATE' | :developer  | false | true  | 'rejects rpm packages access'          | :not_found
        'PRIVATE' | :guest      | false | true  | 'rejects rpm packages access'          | :not_found
        'PRIVATE' | :developer  | false | false | 'rejects rpm packages access'          | :unauthorized
        'PRIVATE' | :guest      | false | false | 'rejects rpm packages access'          | :unauthorized
        'PRIVATE' | :anonymous  | false | true  | 'rejects rpm packages access'          | :unauthorized
      end

      with_them do
        let(:token) { user_token ? personal_access_token.token : 'wrong' }
        let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }

        subject { get api(url), headers: headers }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level))
          project.send("add_#{user_role}", user) if member && user_role != :anonymous
        end

        it_behaves_like params[:shared_examples_name], params[:expected_status]
      end
    end
  end

  describe 'GET /api/v4/projects/:project_id/packages/rpm/repodata/:filename' do
    let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, user: user } }
    let(:repository_file) { create(:rpm_repository_file, project: project) }
    let(:url) { "/projects/#{project.id}/packages/rpm/repodata/#{repository_file.file_name}" }

    subject { get api(url), headers: headers }

    it_behaves_like 'a job token for RPM requests', :success
    it_behaves_like 'a deploy token for RPM requests', :success
    it_behaves_like 'a user token for RPM requests', :success
  end

  describe 'GET /api/v4/projects/:id/packages/rpm/:package_file_id/:filename' do
    let(:snowplow_gitlab_standard_context) { { project: project, namespace: group, property: 'i_package_rpm_user' } }
    let(:url) { "/projects/#{project.id}/packages/rpm/#{package_file_id}/#{package_name}" }

    subject { get api(url), headers: headers }

    it_behaves_like 'a package tracking event', described_class.name, 'pull_package'
    it_behaves_like 'a job token for RPM requests'
    it_behaves_like 'a deploy token for RPM requests'
    it_behaves_like 'a user token for RPM requests'
  end

  describe 'POST /api/v4/projects/:project_id/packages/rpm' do
    let(:snowplow_gitlab_standard_context) do
      { project: project, namespace: group, user: user, property: 'i_package_rpm_user' }
    end

    let(:url) { "/projects/#{project.id}/packages/rpm" }
    let(:file_upload) { fixture_file_upload('spec/fixtures/packages/rpm/hello-0.0.1-1.fc29.x86_64.rpm') }

    subject { post api(url), params: { file: file_upload }, headers: headers }

    context 'with user token' do
      context 'with valid project' do
        where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status, :tracked) do
          'PUBLIC'  | :developer  | true  | true  | 'process rpm packages upload/download' | :not_found    | true
          'PUBLIC'  | :guest      | true  | true  | 'rejects rpm packages access'          | :forbidden    | false
          'PUBLIC'  | :developer  | true  | false | 'rejects rpm packages access'          | :unauthorized | false
          'PUBLIC'  | :guest      | true  | false | 'rejects rpm packages access'          | :unauthorized | false
          'PUBLIC'  | :developer  | false | true  | 'rejects rpm packages access'          | :not_found    | false
          'PUBLIC'  | :guest      | false | true  | 'rejects rpm packages access'          | :not_found    | false
          'PUBLIC'  | :developer  | false | false | 'rejects rpm packages access'          | :unauthorized | false
          'PUBLIC'  | :guest      | false | false | 'rejects rpm packages access'          | :unauthorized | false
          'PUBLIC'  | :anonymous  | false | true  | 'rejects rpm packages access'          | :unauthorized | false
          'PRIVATE' | :developer  | true  | true  | 'process rpm packages upload/download' | :not_found    | true
          'PRIVATE' | :guest      | true  | true  | 'rejects rpm packages access'          | :forbidden    | false
          'PRIVATE' | :developer  | true  | false | 'rejects rpm packages access'          | :unauthorized | false
          'PRIVATE' | :guest      | true  | false | 'rejects rpm packages access'          | :unauthorized | false
          'PRIVATE' | :developer  | false | true  | 'rejects rpm packages access'          | :not_found    | false
          'PRIVATE' | :guest      | false | true  | 'rejects rpm packages access'          | :not_found    | false
          'PRIVATE' | :developer  | false | false | 'rejects rpm packages access'          | :unauthorized | false
          'PRIVATE' | :guest      | false | false | 'rejects rpm packages access'          | :unauthorized | false
          'PRIVATE' | :anonymous  | false | true  | 'rejects rpm packages access'          | :unauthorized | false
        end

        with_them do
          let(:token) { user_token ? personal_access_token.token : 'wrong' }
          let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }

          before do
            project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level))
            project.send("add_#{user_role}", user) if member && user_role != :anonymous
          end

          tracking_example = params[:tracked] ? 'a package tracking event' : 'not a package tracking event'
          it_behaves_like tracking_example, described_class.name, 'push_package'
          it_behaves_like params[:shared_examples_name], params[:expected_status]
        end
      end

      context 'when user can upload file' do
        before do
          project.add_developer(user)
        end

        let(:headers) { basic_auth_header(user.username, personal_access_token.token).merge(workhorse_headers) }

        context 'when file size too large' do
          before do
            allow_next_instance_of(UploadedFile) do |uploaded_file|
              allow(uploaded_file).to receive(:size).and_return(project.actual_limits.rpm_max_file_size + 1)
            end
          end

          it 'returns an error' do
            upload_file(params: { file: file_upload }, request_headers: headers)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(response.body).to match(/File is too large/)
          end
        end

        context 'when filelists.xml file size too large' do
          before do
            create(:rpm_repository_file, :filelists, size: 21.megabytes, project: project)
          end

          it 'returns an error' do
            upload_file(params: { file: file_upload }, request_headers: headers)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(response.body).to match(/Repository packages limit exceeded/)
          end
        end
      end

      def upload_file(params: {}, request_headers: headers)
        url = "/projects/#{project.id}/packages/rpm"
        workhorse_finalize(
          api(url),
          method: :post,
          file_key: :file,
          params: params,
          headers: request_headers,
          send_rewritten_field: true
        )
      end
    end

    it_behaves_like 'a deploy token for RPM requests'
    it_behaves_like 'a job token for RPM requests'
  end

  describe 'POST /api/v4/projects/:project_id/packages/rpm/authorize' do
    let(:url) { api("/projects/#{project.id}/packages/rpm/authorize") }

    subject { post(url, headers: headers) }

    it_behaves_like 'returning response status', :not_found

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(rpm_packages: false)
      end

      it_behaves_like 'returning response status', :not_found
    end

    context 'when package feature is disabled' do
      before do
        stub_config(packages: { enabled: false })
      end

      it_behaves_like 'returning response status', :not_found
    end
  end
end
