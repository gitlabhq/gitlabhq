# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::PypiPackages do
  include WorkhorseHelpers
  include PackagesManagerApiSpecHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :public) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }

  describe 'GET /api/v4/projects/:id/packages/pypi/simple/:package_name' do
    let_it_be(:package) { create(:pypi_package, project: project) }
    let(:url) { "/projects/#{project.id}/packages/pypi/simple/#{package.name}" }

    subject { get api(url) }

    context 'without the need for a license' do
      context 'with valid project' do
        using RSpec::Parameterized::TableSyntax

        where(:project_visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
          'PUBLIC'  | :developer  | true  | true  | 'PyPi package versions' | :success
          'PUBLIC'  | :guest      | true  | true  | 'PyPi package versions' | :success
          'PUBLIC'  | :developer  | true  | false | 'PyPi package versions' | :success
          'PUBLIC'  | :guest      | true  | false | 'PyPi package versions' | :success
          'PUBLIC'  | :developer  | false | true  | 'PyPi package versions' | :success
          'PUBLIC'  | :guest      | false | true  | 'PyPi package versions' | :success
          'PUBLIC'  | :developer  | false | false | 'PyPi package versions' | :success
          'PUBLIC'  | :guest      | false | false | 'PyPi package versions' | :success
          'PUBLIC'  | :anonymous  | false | true  | 'PyPi package versions' | :success
          'PRIVATE' | :developer  | true  | true  | 'PyPi package versions' | :success
          'PRIVATE' | :guest      | true  | true  | 'process PyPi api request' | :forbidden
          'PRIVATE' | :developer  | true  | false | 'process PyPi api request' | :unauthorized
          'PRIVATE' | :guest      | true  | false | 'process PyPi api request' | :unauthorized
          'PRIVATE' | :developer  | false | true  | 'process PyPi api request' | :not_found
          'PRIVATE' | :guest      | false | true  | 'process PyPi api request' | :not_found
          'PRIVATE' | :developer  | false | false | 'process PyPi api request' | :unauthorized
          'PRIVATE' | :guest      | false | false | 'process PyPi api request' | :unauthorized
          'PRIVATE' | :anonymous  | false | true  | 'process PyPi api request' | :unauthorized
        end

        with_them do
          let(:token) { user_token ? personal_access_token.token : 'wrong' }
          let(:headers) { user_role == :anonymous ? {} : build_basic_auth_header(user.username, token) }

          subject { get api(url), headers: headers }

          before do
            project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility_level, false))
          end

          it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
        end
      end

      it_behaves_like 'deploy token for package GET requests'

      it_behaves_like 'rejects PyPI access with unknown project id'
    end
  end

  describe 'POST /api/v4/projects/:id/packages/pypi/authorize' do
    let_it_be(:workhorse_token) { JWT.encode({ 'iss' => 'gitlab-workhorse' }, Gitlab::Workhorse.secret, 'HS256') }
    let_it_be(:workhorse_header) { { 'GitLab-Workhorse' => '1.0', Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER => workhorse_token } }
    let(:url) { "/projects/#{project.id}/packages/pypi/authorize" }
    let(:headers) { {} }

    subject { post api(url), headers: headers }

    context 'without the need for a license' do
      context 'with valid project' do
        using RSpec::Parameterized::TableSyntax

        where(:project_visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
          'PUBLIC'  | :developer  | true  | true  | 'process PyPi api request' | :success
          'PUBLIC'  | :guest      | true  | true  | 'process PyPi api request' | :forbidden
          'PUBLIC'  | :developer  | true  | false | 'process PyPi api request' | :unauthorized
          'PUBLIC'  | :guest      | true  | false | 'process PyPi api request' | :unauthorized
          'PUBLIC'  | :developer  | false | true  | 'process PyPi api request' | :forbidden
          'PUBLIC'  | :guest      | false | true  | 'process PyPi api request' | :forbidden
          'PUBLIC'  | :developer  | false | false | 'process PyPi api request' | :unauthorized
          'PUBLIC'  | :guest      | false | false | 'process PyPi api request' | :unauthorized
          'PUBLIC'  | :anonymous  | false | true  | 'process PyPi api request' | :unauthorized
          'PRIVATE' | :developer  | true  | true  | 'process PyPi api request' | :success
          'PRIVATE' | :guest      | true  | true  | 'process PyPi api request' | :forbidden
          'PRIVATE' | :developer  | true  | false | 'process PyPi api request' | :unauthorized
          'PRIVATE' | :guest      | true  | false | 'process PyPi api request' | :unauthorized
          'PRIVATE' | :developer  | false | true  | 'process PyPi api request' | :not_found
          'PRIVATE' | :guest      | false | true  | 'process PyPi api request' | :not_found
          'PRIVATE' | :developer  | false | false | 'process PyPi api request' | :unauthorized
          'PRIVATE' | :guest      | false | false | 'process PyPi api request' | :unauthorized
          'PRIVATE' | :anonymous  | false | true  | 'process PyPi api request' | :unauthorized
        end

        with_them do
          let(:token) { user_token ? personal_access_token.token : 'wrong' }
          let(:user_headers) { user_role == :anonymous ? {} : build_basic_auth_header(user.username, token) }
          let(:headers) { user_headers.merge(workhorse_header) }

          before do
            project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility_level, false))
          end

          it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
        end
      end

      it_behaves_like 'deploy token for package uploads'

      it_behaves_like 'rejects PyPI access with unknown project id'
    end
  end

  describe 'POST /api/v4/projects/:id/packages/pypi' do
    let(:workhorse_token) { JWT.encode({ 'iss' => 'gitlab-workhorse' }, Gitlab::Workhorse.secret, 'HS256') }
    let(:workhorse_header) { { 'GitLab-Workhorse' => '1.0', Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER => workhorse_token } }
    let_it_be(:file_name) { 'package.whl' }
    let(:url) { "/projects/#{project.id}/packages/pypi" }
    let(:headers) { {} }
    let(:base_params) { { requires_python: '>=3.7', version: '1.0.0', name: 'sample-project', sha256_digest: '123' } }
    let(:params) { base_params.merge(content: temp_file(file_name)) }
    let(:send_rewritten_field) { true }

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

    context 'without the need for a license' do
      context 'with valid project' do
        using RSpec::Parameterized::TableSyntax

        where(:project_visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
          'PUBLIC'  | :developer  | true  | true  | 'PyPi package creation'    | :created
          'PUBLIC'  | :guest      | true  | true  | 'process PyPi api request' | :forbidden
          'PUBLIC'  | :developer  | true  | false | 'process PyPi api request' | :unauthorized
          'PUBLIC'  | :guest      | true  | false | 'process PyPi api request' | :unauthorized
          'PUBLIC'  | :developer  | false | true  | 'process PyPi api request' | :forbidden
          'PUBLIC'  | :guest      | false | true  | 'process PyPi api request' | :forbidden
          'PUBLIC'  | :developer  | false | false | 'process PyPi api request' | :unauthorized
          'PUBLIC'  | :guest      | false | false | 'process PyPi api request' | :unauthorized
          'PUBLIC'  | :anonymous  | false | true  | 'process PyPi api request' | :unauthorized
          'PRIVATE' | :developer  | true  | true  | 'process PyPi api request' | :created
          'PRIVATE' | :guest      | true  | true  | 'process PyPi api request' | :forbidden
          'PRIVATE' | :developer  | true  | false | 'process PyPi api request' | :unauthorized
          'PRIVATE' | :guest      | true  | false | 'process PyPi api request' | :unauthorized
          'PRIVATE' | :developer  | false | true  | 'process PyPi api request' | :not_found
          'PRIVATE' | :guest      | false | true  | 'process PyPi api request' | :not_found
          'PRIVATE' | :developer  | false | false | 'process PyPi api request' | :unauthorized
          'PRIVATE' | :guest      | false | false | 'process PyPi api request' | :unauthorized
          'PRIVATE' | :anonymous  | false | true  | 'process PyPi api request' | :unauthorized
        end

        with_them do
          let(:token) { user_token ? personal_access_token.token : 'wrong' }
          let(:user_headers) { user_role == :anonymous ? {} : build_basic_auth_header(user.username, token) }
          let(:headers) { user_headers.merge(workhorse_header) }

          before do
            project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility_level, false))
          end

          it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
        end
      end

      context 'with an invalid package' do
        let(:token) { personal_access_token.token }
        let(:user_headers) { build_basic_auth_header(user.username, token) }
        let(:headers) { user_headers.merge(workhorse_header) }

        before do
          params[:name] = '.$/@!^*'
          project.add_developer(user)
        end

        it_behaves_like 'returning response status', :bad_request
      end

      it_behaves_like 'deploy token for package uploads'

      it_behaves_like 'rejects PyPI access with unknown project id'
    end
  end

  describe 'GET /api/v4/projects/:id/packages/pypi/files/:sha256/*file_identifier' do
    let_it_be(:package_name) { 'Dummy-Package' }
    let_it_be(:package) { create(:pypi_package, project: project, name: package_name, version: '1.0.0') }

    let(:url) { "/projects/#{project.id}/packages/pypi/files/#{package.package_files.first.file_sha256}/#{package_name}-1.0.0.tar.gz" }

    subject { get api(url) }

    context 'without the need for a license' do
      context 'with valid project' do
        using RSpec::Parameterized::TableSyntax

        where(:project_visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
          'PUBLIC'  | :developer  | true  | true  | 'PyPi package download' | :success
          'PUBLIC'  | :guest      | true  | true  | 'PyPi package download' | :success
          'PUBLIC'  | :developer  | true  | false | 'PyPi package download' | :success
          'PUBLIC'  | :guest      | true  | false | 'PyPi package download' | :success
          'PUBLIC'  | :developer  | false | true  | 'PyPi package download' | :success
          'PUBLIC'  | :guest      | false | true  | 'PyPi package download' | :success
          'PUBLIC'  | :developer  | false | false | 'PyPi package download' | :success
          'PUBLIC'  | :guest      | false | false | 'PyPi package download' | :success
          'PUBLIC'  | :anonymous  | false | true  | 'PyPi package download' | :success
          'PRIVATE' | :developer  | true  | true  | 'PyPi package download' | :success
          'PRIVATE' | :guest      | true  | true  | 'PyPi package download' | :success
          'PRIVATE' | :developer  | true  | false | 'PyPi package download' | :success
          'PRIVATE' | :guest      | true  | false | 'PyPi package download' | :success
          'PRIVATE' | :developer  | false | true  | 'PyPi package download' | :success
          'PRIVATE' | :guest      | false | true  | 'PyPi package download' | :success
          'PRIVATE' | :developer  | false | false | 'PyPi package download' | :success
          'PRIVATE' | :guest      | false | false | 'PyPi package download' | :success
          'PRIVATE' | :anonymous  | false | true  | 'PyPi package download' | :success
        end

        with_them do
          let(:token) { user_token ? personal_access_token.token : 'wrong' }
          let(:headers) { user_role == :anonymous ? {} : build_basic_auth_header(user.username, token) }

          subject { get api(url), headers: headers }

          before do
            project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility_level, false))
          end

          it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
        end
      end

      context 'with deploy token headers' do
        let(:headers) { build_basic_auth_header(deploy_token.username, deploy_token.token) }

        context 'valid token' do
          it_behaves_like 'returning response status', :success
        end

        context 'invalid token' do
          let(:headers) { build_basic_auth_header('foo', 'bar') }

          it_behaves_like 'returning response status', :success
        end
      end

      it_behaves_like 'rejects PyPI access with unknown project id'
    end
  end
end
