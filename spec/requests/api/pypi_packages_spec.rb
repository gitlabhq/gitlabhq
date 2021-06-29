# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::PypiPackages do
  include WorkhorseHelpers
  include PackagesManagerApiSpecHelpers
  include HttpBasicAuthHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, :public, group: group) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }
  let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }

  let(:headers) { {} }

  context 'simple API endpoint' do
    let_it_be(:package) { create(:pypi_package, project: project) }

    subject { get api(url), headers: headers }

    describe 'GET /api/v4/groups/:id/-/packages/pypi/simple/:package_name' do
      let(:url) { "/groups/#{group.id}/-/packages/pypi/simple/#{package.name}" }
      let(:snowplow_gitlab_standard_context) { {} }

      it_behaves_like 'pypi simple API endpoint'
      it_behaves_like 'rejects PyPI access with unknown group id'

      context 'deploy tokens' do
        let_it_be(:group_deploy_token) { create(:group_deploy_token, deploy_token: deploy_token, group: group) }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
          group.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
        end

        it_behaves_like 'deploy token for package GET requests'
      end

      context 'job token' do
        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
          group.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
          group.add_developer(user)
        end

        it_behaves_like 'job token for package GET requests'
      end

      it_behaves_like 'a pypi user namespace endpoint'
    end

    describe 'GET /api/v4/projects/:id/packages/pypi/simple/:package_name' do
      let(:url) { "/projects/#{project.id}/packages/pypi/simple/#{package.name}" }
      let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace } }

      it_behaves_like 'pypi simple API endpoint'
      it_behaves_like 'rejects PyPI access with unknown project id'
      it_behaves_like 'deploy token for package GET requests'
      it_behaves_like 'job token for package GET requests'
    end
  end

  describe 'POST /api/v4/projects/:id/packages/pypi/authorize' do
    include_context 'workhorse headers'

    let(:url) { "/projects/#{project.id}/packages/pypi/authorize" }
    let(:headers) { {} }

    subject { post api(url), headers: headers }

    context 'with valid project' do
      where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | true  | 'process PyPI api request' | :success
        :public  | :guest      | true  | true  | 'process PyPI api request' | :forbidden
        :public  | :developer  | true  | false | 'process PyPI api request' | :unauthorized
        :public  | :guest      | true  | false | 'process PyPI api request' | :unauthorized
        :public  | :developer  | false | true  | 'process PyPI api request' | :forbidden
        :public  | :guest      | false | true  | 'process PyPI api request' | :forbidden
        :public  | :developer  | false | false | 'process PyPI api request' | :unauthorized
        :public  | :guest      | false | false | 'process PyPI api request' | :unauthorized
        :public  | :anonymous  | false | true  | 'process PyPI api request' | :unauthorized
        :private | :developer  | true  | true  | 'process PyPI api request' | :success
        :private | :guest      | true  | true  | 'process PyPI api request' | :forbidden
        :private | :developer  | true  | false | 'process PyPI api request' | :unauthorized
        :private | :guest      | true  | false | 'process PyPI api request' | :unauthorized
        :private | :developer  | false | true  | 'process PyPI api request' | :not_found
        :private | :guest      | false | true  | 'process PyPI api request' | :not_found
        :private | :developer  | false | false | 'process PyPI api request' | :unauthorized
        :private | :guest      | false | false | 'process PyPI api request' | :unauthorized
        :private | :anonymous  | false | true  | 'process PyPI api request' | :unauthorized
      end

      with_them do
        let(:token) { user_token ? personal_access_token.token : 'wrong' }
        let(:user_headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }
        let(:headers) { user_headers.merge(workhorse_headers) }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level.to_s))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end

    it_behaves_like 'deploy token for package uploads'

    it_behaves_like 'job token for package uploads', authorize_endpoint: true

    it_behaves_like 'rejects PyPI access with unknown project id'
  end

  describe 'POST /api/v4/projects/:id/packages/pypi' do
    include_context 'workhorse headers'

    let_it_be(:file_name) { 'package.whl' }

    let(:url) { "/projects/#{project.id}/packages/pypi" }
    let(:headers) { {} }
    let(:requires_python) { '>=3.7' }
    let(:base_params) { { requires_python: requires_python, version: '1.0.0', name: 'sample-project', sha256_digest: '123' } }
    let(:params) { base_params.merge(content: temp_file(file_name)) }
    let(:send_rewritten_field) { true }
    let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, user: user } }

    subject do
      workhorse_finalize(
        api(url),
        method: :post,
        file_key: :content,
        params: params,
        headers: headers,
        send_rewritten_field: send_rewritten_field
      )
    end

    context 'with valid project' do
      where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | true  | 'PyPI package creation'    | :created
        :public  | :guest      | true  | true  | 'process PyPI api request' | :forbidden
        :public  | :developer  | true  | false | 'process PyPI api request' | :unauthorized
        :public  | :guest      | true  | false | 'process PyPI api request' | :unauthorized
        :public  | :developer  | false | true  | 'process PyPI api request' | :forbidden
        :public  | :guest      | false | true  | 'process PyPI api request' | :forbidden
        :public  | :developer  | false | false | 'process PyPI api request' | :unauthorized
        :public  | :guest      | false | false | 'process PyPI api request' | :unauthorized
        :public  | :anonymous  | false | true  | 'process PyPI api request' | :unauthorized
        :private | :developer  | true  | true  | 'process PyPI api request' | :created
        :private | :guest      | true  | true  | 'process PyPI api request' | :forbidden
        :private | :developer  | true  | false | 'process PyPI api request' | :unauthorized
        :private | :guest      | true  | false | 'process PyPI api request' | :unauthorized
        :private | :developer  | false | true  | 'process PyPI api request' | :not_found
        :private | :guest      | false | true  | 'process PyPI api request' | :not_found
        :private | :developer  | false | false | 'process PyPI api request' | :unauthorized
        :private | :guest      | false | false | 'process PyPI api request' | :unauthorized
        :private | :anonymous  | false | true  | 'process PyPI api request' | :unauthorized
      end

      with_them do
        let(:token) { user_token ? personal_access_token.token : 'wrong' }
        let(:user_headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }
        let(:headers) { user_headers.merge(workhorse_headers) }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level.to_s))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end

    context 'with required_python too big' do
      let(:requires_python) { 'x' * 256 }
      let(:token) { personal_access_token.token }
      let(:user_headers) { basic_auth_header(user.username, token) }
      let(:headers) { user_headers.merge(workhorse_headers) }

      before do
        project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
      end

      it_behaves_like 'process PyPI api request', :developer, :bad_request, true
    end

    context 'with an invalid package' do
      let(:token) { personal_access_token.token }
      let(:user_headers) { basic_auth_header(user.username, token) }
      let(:headers) { user_headers.merge(workhorse_headers) }

      before do
        params[:name] = '.$/@!^*'
        project.add_developer(user)
      end

      it_behaves_like 'returning response status', :bad_request
    end

    it_behaves_like 'deploy token for package uploads'

    it_behaves_like 'job token for package uploads'

    it_behaves_like 'rejects PyPI access with unknown project id'

    context 'file size above maximum limit' do
      let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token).merge(workhorse_headers) }

      before do
        allow_next_instance_of(UploadedFile) do |uploaded_file|
          allow(uploaded_file).to receive(:size).and_return(project.actual_limits.pypi_max_file_size + 1)
        end
      end

      it_behaves_like 'returning response status', :bad_request
    end
  end

  context 'file download endpoint' do
    let_it_be(:package_name) { 'Dummy-Package' }
    let_it_be(:package) { create(:pypi_package, project: project, name: package_name, version: '1.0.0') }

    subject { get api(url), headers: headers }

    describe 'GET /api/v4/groups/:id/-/packages/pypi/files/:sha256/*file_identifier' do
      let(:url) { "/groups/#{group.id}/-/packages/pypi/files/#{package.package_files.first.file_sha256}/#{package_name}-1.0.0.tar.gz" }
      let(:snowplow_gitlab_standard_context) { {} }

      it_behaves_like 'pypi file download endpoint'
      it_behaves_like 'rejects PyPI access with unknown group id'
      it_behaves_like 'a pypi user namespace endpoint'
    end

    describe 'GET /api/v4/projects/:id/packages/pypi/files/:sha256/*file_identifier' do
      let(:url) { "/projects/#{project.id}/packages/pypi/files/#{package.package_files.first.file_sha256}/#{package_name}-1.0.0.tar.gz" }
      let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace } }

      it_behaves_like 'pypi file download endpoint'
      it_behaves_like 'rejects PyPI access with unknown project id'
    end
  end
end
