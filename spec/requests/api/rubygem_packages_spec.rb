# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::RubygemPackages do
  include PackagesManagerApiSpecHelpers
  include WorkhorseHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:personal_access_token) { create(:personal_access_token) }
  let_it_be(:user) { personal_access_token.user }
  let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }
  let_it_be(:headers) { {} }

  let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, user: user } }

  let(:tokens) do
    {
      personal_access_token: personal_access_token.token,
      deploy_token: deploy_token.token,
      job_token: job.token
    }
  end

  shared_examples 'when feature flag is disabled' do
    let(:headers) do
      { 'HTTP_AUTHORIZATION' => personal_access_token.token }
    end

    before do
      stub_feature_flags(rubygem_packages: false)
    end

    it_behaves_like 'returning response status', :not_found
  end

  shared_examples 'when package feature is disabled' do
    before do
      stub_config(packages: { enabled: false })
    end

    it_behaves_like 'returning response status', :not_found
  end

  shared_examples 'without authentication' do
    it_behaves_like 'returning response status', :not_found
  end

  shared_examples 'with authentication' do
    let(:headers) do
      { 'HTTP_AUTHORIZATION' => token }
    end

    where(:user_role, :token_type, :valid_token, :status) do
      :guest     | :personal_access_token   | true  | :not_found
      :guest     | :personal_access_token   | false | :unauthorized
      :guest     | :deploy_token            | true  | :not_found
      :guest     | :deploy_token            | false | :unauthorized
      :guest     | :job_token               | true  | :not_found
      :guest     | :job_token               | false | :unauthorized
      :reporter  | :personal_access_token   | true  | :not_found
      :reporter  | :personal_access_token   | false | :unauthorized
      :reporter  | :deploy_token            | true  | :not_found
      :reporter  | :deploy_token            | false | :unauthorized
      :reporter  | :job_token               | true  | :not_found
      :reporter  | :job_token               | false | :unauthorized
      :developer | :personal_access_token   | true  | :not_found
      :developer | :personal_access_token   | false | :unauthorized
      :developer | :deploy_token            | true  | :not_found
      :developer | :deploy_token            | false | :unauthorized
      :developer | :job_token               | true  | :not_found
      :developer | :job_token               | false | :unauthorized
    end

    with_them do
      before do
        project.send("add_#{user_role}", user) unless user_role == :anonymous
      end

      let(:token) { valid_token ? tokens[token_type] : 'invalid-token123' }

      it_behaves_like 'returning response status', params[:status]
    end
  end

  shared_examples 'an unimplemented route' do
    it_behaves_like 'without authentication'
    it_behaves_like 'with authentication'
    it_behaves_like 'when feature flag is disabled'
    it_behaves_like 'when package feature is disabled'
  end

  describe 'GET /api/v4/projects/:project_id/packages/rubygems/:filename' do
    let(:url) { api("/projects/#{project.id}/packages/rubygems/specs.4.8.gz") }

    subject { get(url, headers: headers) }

    it_behaves_like 'an unimplemented route'
  end

  describe 'GET /api/v4/projects/:project_id/packages/rubygems/quick/Marshal.4.8/:file_name' do
    let(:url) { api("/projects/#{project.id}/packages/rubygems/quick/Marshal.4.8/my_gem-1.0.0.gemspec.rz") }

    subject { get(url, headers: headers) }

    it_behaves_like 'an unimplemented route'
  end

  describe 'GET /api/v4/projects/:project_id/packages/rubygems/gems/:file_name' do
    let_it_be(:package_name) { 'package' }
    let_it_be(:version) { '0.0.1' }
    let_it_be(:package) { create(:rubygems_package, project: project, name: package_name, version: version) }
    let_it_be(:file_name) { "#{package_name}-#{version}.gem" }

    let(:url) { api("/projects/#{project.id}/packages/rubygems/gems/#{file_name}") }

    subject { get(url, headers: headers) }

    context 'with valid project' do
      where(:visibility, :user_role, :member, :token_type, :valid_token, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | :personal_access_token | true  | 'Rubygems gem download'            | :success
        :public  | :guest      | true  | :personal_access_token | true  | 'Rubygems gem download'            | :success
        :public  | :developer  | true  | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :guest      | true  | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :developer  | false | :personal_access_token | true  | 'Rubygems gem download'            | :success
        :public  | :guest      | false | :personal_access_token | true  | 'Rubygems gem download'            | :success
        :public  | :developer  | false | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :guest      | false | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :anonymous  | false | :personal_access_token | true  | 'Rubygems gem download'            | :success
        :private | :developer  | true  | :personal_access_token | true  | 'Rubygems gem download'            | :success
        :private | :guest      | true  | :personal_access_token | true  | 'rejects rubygems packages access' | :forbidden
        :private | :developer  | true  | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :private | :guest      | true  | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :private | :developer  | false | :personal_access_token | true  | 'rejects rubygems packages access' | :not_found
        :private | :guest      | false | :personal_access_token | true  | 'rejects rubygems packages access' | :not_found
        :private | :developer  | false | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :private | :guest      | false | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :private | :anonymous  | false | :personal_access_token | true  | 'rejects rubygems packages access' | :not_found
        :public  | :developer  | true  | :job_token             | true  | 'Rubygems gem download'            | :success
        :public  | :guest      | true  | :job_token             | true  | 'Rubygems gem download'            | :success
        :public  | :developer  | true  | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :guest      | true  | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :developer  | false | :job_token             | true  | 'Rubygems gem download'            | :success
        :public  | :guest      | false | :job_token             | true  | 'Rubygems gem download'            | :success
        :public  | :developer  | false | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :guest      | false | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :private | :developer  | true  | :job_token             | true  | 'Rubygems gem download'            | :success
        :private | :guest      | true  | :job_token             | true  | 'rejects rubygems packages access' | :forbidden
        :private | :developer  | true  | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :private | :guest      | true  | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :private | :developer  | false | :job_token             | true  | 'rejects rubygems packages access' | :not_found
        :private | :guest      | false | :job_token             | true  | 'rejects rubygems packages access' | :not_found
        :private | :developer  | false | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :private | :guest      | false | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :developer  | true  | :deploy_token          | true  | 'Rubygems gem download'            | :success
        :public  | :developer  | true  | :deploy_token          | false | 'rejects rubygems packages access' | :unauthorized
        :private | :developer  | true  | :deploy_token          | true  | 'Rubygems gem download'            | :success
        :private | :developer  | true  | :deploy_token          | false | 'rejects rubygems packages access' | :unauthorized
      end

      with_them do
        let(:token) { valid_token ? tokens[token_type] : 'invalid-token123' }
        let(:headers) { user_role == :anonymous ? {} : { 'HTTP_AUTHORIZATION' => token } }
        let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace } }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility.to_s))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end
  end

  describe 'POST /api/v4/projects/:project_id/packages/rubygems/api/v1/gems/authorize' do
    include_context 'workhorse headers'

    let(:url) { api("/projects/#{project.id}/packages/rubygems/api/v1/gems/authorize") }
    let(:headers) { {} }

    subject { post(url, headers: headers) }

    context 'with valid project' do
      where(:visibility, :user_role, :member, :token_type, :valid_token, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | :personal_access_token | true  | 'process rubygems workhorse authorization' | :success
        :public  | :guest      | true  | :personal_access_token | true  | 'rejects rubygems packages access'         | :forbidden
        :public  | :developer  | true  | :personal_access_token | false | 'rejects rubygems packages access'         | :unauthorized
        :public  | :guest      | true  | :personal_access_token | false | 'rejects rubygems packages access'         | :unauthorized
        :public  | :developer  | false | :personal_access_token | true  | 'rejects rubygems packages access'         | :forbidden
        :public  | :guest      | false | :personal_access_token | true  | 'rejects rubygems packages access'         | :forbidden
        :public  | :developer  | false | :personal_access_token | false | 'rejects rubygems packages access'         | :unauthorized
        :public  | :guest      | false | :personal_access_token | false | 'rejects rubygems packages access'         | :unauthorized
        :public  | :anonymous  | false | :personal_access_token | true  | 'rejects rubygems packages access'         | :unauthorized
        :private | :developer  | true  | :personal_access_token | true  | 'process rubygems workhorse authorization' | :success
        :private | :guest      | true  | :personal_access_token | true  | 'rejects rubygems packages access'         | :forbidden
        :private | :developer  | true  | :personal_access_token | false | 'rejects rubygems packages access'         | :unauthorized
        :private | :guest      | true  | :personal_access_token | false | 'rejects rubygems packages access'         | :unauthorized
        :private | :developer  | false | :personal_access_token | true  | 'rejects rubygems packages access'         | :not_found
        :private | :guest      | false | :personal_access_token | true  | 'rejects rubygems packages access'         | :not_found
        :private | :developer  | false | :personal_access_token | false | 'rejects rubygems packages access'         | :unauthorized
        :private | :guest      | false | :personal_access_token | false | 'rejects rubygems packages access'         | :unauthorized
        :private | :anonymous  | false | :personal_access_token | true  | 'rejects rubygems packages access'         | :unauthorized
        :public  | :developer  | true  | :job_token             | true  | 'process rubygems workhorse authorization' | :success
        :public  | :guest      | true  | :job_token             | true  | 'rejects rubygems packages access'         | :forbidden
        :public  | :developer  | true  | :job_token             | false | 'rejects rubygems packages access'         | :unauthorized
        :public  | :guest      | true  | :job_token             | false | 'rejects rubygems packages access'         | :unauthorized
        :public  | :developer  | false | :job_token             | true  | 'rejects rubygems packages access'         | :forbidden
        :public  | :guest      | false | :job_token             | true  | 'rejects rubygems packages access'         | :forbidden
        :public  | :developer  | false | :job_token             | false | 'rejects rubygems packages access'         | :unauthorized
        :public  | :guest      | false | :job_token             | false | 'rejects rubygems packages access'         | :unauthorized
        :private | :developer  | true  | :job_token             | true  | 'process rubygems workhorse authorization' | :success
        :private | :guest      | true  | :job_token             | true  | 'rejects rubygems packages access'         | :forbidden
        :private | :developer  | true  | :job_token             | false | 'rejects rubygems packages access'         | :unauthorized
        :private | :guest      | true  | :job_token             | false | 'rejects rubygems packages access'         | :unauthorized
        :private | :developer  | false | :job_token             | true  | 'rejects rubygems packages access'         | :not_found
        :private | :guest      | false | :job_token             | true  | 'rejects rubygems packages access'         | :not_found
        :private | :developer  | false | :job_token             | false | 'rejects rubygems packages access'         | :unauthorized
        :private | :guest      | false | :job_token             | false | 'rejects rubygems packages access'         | :unauthorized
        :public  | :developer  | true  | :deploy_token          | true  | 'process rubygems workhorse authorization' | :success
        :public  | :developer  | true  | :deploy_token          | false | 'rejects rubygems packages access'         | :unauthorized
        :private | :developer  | true  | :deploy_token          | true  | 'process rubygems workhorse authorization' | :success
        :private | :developer  | true  | :deploy_token          | false | 'rejects rubygems packages access'         | :unauthorized
      end

      with_them do
        let(:token) { valid_token ? tokens[token_type] : 'invalid-token123' }
        let(:user_headers) { user_role == :anonymous ? {} : { 'HTTP_AUTHORIZATION' => token } }
        let(:headers) { user_headers.merge(workhorse_headers) }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility.to_s))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end
  end

  describe 'POST /api/v4/projects/:project_id/packages/rubygems/api/v1/gems' do
    include_context 'workhorse headers'

    let(:url) { "/projects/#{project.id}/packages/rubygems/api/v1/gems" }

    let_it_be(:file_name) { 'package.gem' }

    let(:headers) { {} }
    let(:params) { { file: temp_file(file_name) } }
    let(:file_key) { :file }
    let(:send_rewritten_field) { true }

    subject do
      workhorse_finalize(
        api(url),
        method: :post,
        file_key: file_key,
        params: params,
        headers: headers,
        send_rewritten_field: send_rewritten_field
      )
    end

    context 'with valid project' do
      where(:visibility, :user_role, :member, :token_type, :valid_token, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | :personal_access_token | true  | 'process rubygems upload'          | :created
        :public  | :guest      | true  | :personal_access_token | true  | 'rejects rubygems packages access' | :forbidden
        :public  | :developer  | true  | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :guest      | true  | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :developer  | false | :personal_access_token | true  | 'rejects rubygems packages access' | :forbidden
        :public  | :guest      | false | :personal_access_token | true  | 'rejects rubygems packages access' | :forbidden
        :public  | :developer  | false | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :guest      | false | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :anonymous  | false | :personal_access_token | true  | 'rejects rubygems packages access' | :unauthorized
        :private | :developer  | true  | :personal_access_token | true  | 'process rubygems upload'          | :created
        :private | :guest      | true  | :personal_access_token | true  | 'rejects rubygems packages access' | :forbidden
        :private | :developer  | true  | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :private | :guest      | true  | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :private | :developer  | false | :personal_access_token | true  | 'rejects rubygems packages access' | :not_found
        :private | :guest      | false | :personal_access_token | true  | 'rejects rubygems packages access' | :not_found
        :private | :developer  | false | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :private | :guest      | false | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :private | :anonymous  | false | :personal_access_token | true  | 'rejects rubygems packages access' | :unauthorized
        :public  | :developer  | true  | :job_token             | true  | 'process rubygems upload'          | :created
        :public  | :guest      | true  | :job_token             | true  | 'rejects rubygems packages access' | :forbidden
        :public  | :developer  | true  | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :guest      | true  | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :developer  | false | :job_token             | true  | 'rejects rubygems packages access' | :forbidden
        :public  | :guest      | false | :job_token             | true  | 'rejects rubygems packages access' | :forbidden
        :public  | :developer  | false | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :guest      | false | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :private | :developer  | true  | :job_token             | true  | 'process rubygems upload'          | :created
        :private | :guest      | true  | :job_token             | true  | 'rejects rubygems packages access' | :forbidden
        :private | :developer  | true  | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :private | :guest      | true  | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :private | :developer  | false | :job_token             | true  | 'rejects rubygems packages access' | :not_found
        :private | :guest      | false | :job_token             | true  | 'rejects rubygems packages access' | :not_found
        :private | :developer  | false | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :private | :guest      | false | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :developer  | true  | :deploy_token          | true  | 'process rubygems upload'          | :created
        :public  | :developer  | true  | :deploy_token          | false | 'rejects rubygems packages access' | :unauthorized
        :private | :developer  | true  | :deploy_token          | true  | 'process rubygems upload'          | :created
        :private | :developer  | true  | :deploy_token          | false | 'rejects rubygems packages access' | :unauthorized
      end

      with_them do
        let(:token) { valid_token ? tokens[token_type] : 'invalid-token123' }
        let(:user_headers) { user_role == :anonymous ? {} : { 'HTTP_AUTHORIZATION' => token } }
        let(:headers) { user_headers.merge(workhorse_headers) }
        let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, user: snowplow_user } }
        let(:snowplow_user) do
          if token_type == :deploy_token
            deploy_token
          elsif token_type == :job_token
            job.user
          else
            user
          end
        end

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility.to_s))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end

      context 'failed package file save' do
        let(:user_headers) { { 'HTTP_AUTHORIZATION' => personal_access_token.token } }
        let(:headers) { user_headers.merge(workhorse_headers) }

        before do
          project.add_developer(user)
        end

        it 'does not create package record', :aggregate_failures do
          allow(Packages::CreatePackageFileService).to receive(:new).and_raise(StandardError)

          expect { subject }
              .to change { project.packages.count }.by(0)
              .and change { Packages::PackageFile.count }.by(0)
          expect(response).to have_gitlab_http_status(:error)
        end
      end
    end
  end

  describe 'GET /api/v4/projects/:project_id/packages/rubygems/api/v1/dependencies' do
    let_it_be(:package) { create(:rubygems_package, project: project) }

    let(:url) { api("/projects/#{project.id}/packages/rubygems/api/v1/dependencies") }

    subject { get(url, headers: headers, params: params) }

    context 'with valid project' do
      where(:visibility, :user_role, :member, :token_type, :valid_token, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | :personal_access_token | true  | 'dependency endpoint success'      | :success
        :public  | :guest      | true  | :personal_access_token | true  | 'dependency endpoint success'      | :success
        :public  | :developer  | true  | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :guest      | true  | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :developer  | false | :personal_access_token | true  | 'dependency endpoint success'      | :success
        :public  | :guest      | false | :personal_access_token | true  | 'dependency endpoint success'      | :success
        :public  | :developer  | false | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :guest      | false | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :anonymous  | false | :personal_access_token | true  | 'dependency endpoint success'      | :success
        :private | :developer  | true  | :personal_access_token | true  | 'dependency endpoint success'      | :success
        :private | :guest      | true  | :personal_access_token | true  | 'rejects rubygems packages access' | :forbidden
        :private | :developer  | true  | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :private | :guest      | true  | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :private | :developer  | false | :personal_access_token | true  | 'rejects rubygems packages access' | :not_found
        :private | :guest      | false | :personal_access_token | true  | 'rejects rubygems packages access' | :not_found
        :private | :developer  | false | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :private | :guest      | false | :personal_access_token | false | 'rejects rubygems packages access' | :unauthorized
        :private | :anonymous  | false | :personal_access_token | true  | 'rejects rubygems packages access' | :not_found
        :public  | :developer  | true  | :job_token             | true  | 'dependency endpoint success'      | :success
        :public  | :guest      | true  | :job_token             | true  | 'dependency endpoint success'      | :success
        :public  | :developer  | true  | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :guest      | true  | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :developer  | false | :job_token             | true  | 'dependency endpoint success'      | :success
        :public  | :guest      | false | :job_token             | true  | 'dependency endpoint success'      | :success
        :public  | :developer  | false | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :guest      | false | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :private | :developer  | true  | :job_token             | true  | 'dependency endpoint success'      | :success
        :private | :guest      | true  | :job_token             | true  | 'rejects rubygems packages access' | :forbidden
        :private | :developer  | true  | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :private | :guest      | true  | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :private | :developer  | false | :job_token             | true  | 'rejects rubygems packages access' | :not_found
        :private | :guest      | false | :job_token             | true  | 'rejects rubygems packages access' | :not_found
        :private | :developer  | false | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :private | :guest      | false | :job_token             | false | 'rejects rubygems packages access' | :unauthorized
        :public  | :developer  | true  | :deploy_token          | true  | 'dependency endpoint success'      | :success
        :public  | :developer  | true  | :deploy_token          | false | 'rejects rubygems packages access' | :unauthorized
        :private | :developer  | true  | :deploy_token          | true  | 'dependency endpoint success'      | :success
        :private | :developer  | true  | :deploy_token          | false | 'rejects rubygems packages access' | :unauthorized
      end

      with_them do
        let(:token) { valid_token ? tokens[token_type] : 'invalid-token123' }
        let(:headers) { user_role == :anonymous ? {} : { 'HTTP_AUTHORIZATION' => token } }
        let(:params) { {} }

        before do
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end
  end
end
