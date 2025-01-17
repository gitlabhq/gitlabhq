# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::HelmPackages, feature_category: :package_registry do
  include_context 'helm api setup'

  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) { create(:project, :public) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }
  let_it_be(:package) { create(:helm_package, project: project, without_package_files: true) }
  let_it_be(:package_file1) { create(:helm_package_file, package: package) }
  let_it_be(:package_file2) { create(:helm_package_file, package: package) }
  let_it_be(:package2) { create(:helm_package, project: project, without_package_files: true) }
  let_it_be(:package_file2_1) { create(:helm_package_file, package: package2, file_sha256: 'file2', file_name: 'filename2.tgz', description: 'hello from stable channel') }
  let_it_be(:package_file2_2) { create(:helm_package_file, package: package2, file_sha256: 'file2', file_name: 'filename2.tgz', channel: 'test', description: 'hello from test channel') }
  let_it_be(:other_package) { create(:npm_package, project: project) }

  let(:snowplow_gitlab_standard_context) { snowplow_context }

  def snowplow_context(user_role: :developer)
    if user_role == :anonymous
      { project: project, namespace: project.namespace, property: 'i_package_helm_user' }
    else
      { project: project, namespace: project.namespace, property: 'i_package_helm_user', user: user }
    end
  end

  describe 'GET /api/v4/projects/:id/packages/helm/:channel/index.yaml' do
    let(:project_id) { project.id }
    let(:channel) { 'stable' }
    let(:url) { "/projects/#{project_id}/packages/helm/#{channel}/index.yaml" }

    context 'with a project id' do
      it_behaves_like 'handling helm chart index requests'
    end

    context 'with an url encoded project id' do
      let(:project_id) { ERB::Util.url_encode(project.full_path) }

      it_behaves_like 'handling helm chart index requests'
    end

    context 'with dot in channel' do
      let(:channel) { 'with.dot' }

      subject { get api(url) }

      before do
        project.update!(visibility: 'public')
      end

      it_behaves_like 'returning response status', :success
    end
  end

  describe 'GET /api/v4/projects/:id/packages/helm/:channel/charts/:file_name.tgz' do
    let(:url) { "/projects/#{project.id}/packages/helm/stable/charts/#{package.name}-#{package.version}.tgz" }

    subject { get api(url), headers: headers }

    context 'with valid project' do
      where(:visibility, :user_role, :shared_examples_name, :expected_status) do
        :public  | :guest        | 'process helm download content request'   | :success
        :public  | :not_a_member | 'process helm download content request'   | :success
        :public  | :anonymous    | 'process helm download content request'   | :success
        :private | :reporter     | 'process helm download content request'   | :success
        :private | :guest        | 'process helm download content request'   | :success
        :private | :not_a_member | 'rejects helm packages access'            | :not_found
        :private | :anonymous    | 'rejects helm packages access'            | :unauthorized
      end

      with_them do
        let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, personal_access_token.token) }
        let(:snowplow_gitlab_standard_context) { snowplow_context(user_role: user_role) }

        before do
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status]
      end
    end

    context 'with access to package registry for everyone' do
      let(:snowplow_gitlab_standard_context) { snowplow_context(user_role: :anonymous) }

      before do
        project.update!(visibility: Gitlab::VisibilityLevel::PRIVATE)
        project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
      end

      it_behaves_like 'process helm download content request', :anonymous, :success
    end

    context 'when an invalid token is passed' do
      let(:headers) { basic_auth_header(user.username, 'wrong') }

      it_behaves_like 'returning response status', :unauthorized
    end

    it_behaves_like 'deploy token for package GET requests'

    context 'when format param is not nil' do
      let(:url) { "/projects/#{project.id}/packages/helm/stable/charts/#{package.name}-#{package.version}.tgz.prov" }

      it_behaves_like 'rejects helm packages access', :maintainer, :not_found, '{"message":"404 Format prov Not Found"}'
    end
  end

  describe 'POST /api/v4/projects/:id/packages/helm/api/:channel/charts/authorize' do
    include_context 'workhorse headers'

    let(:channel) { 'stable' }
    let(:url) { "/projects/#{project.id}/packages/helm/api/#{channel}/charts/authorize" }
    let(:headers) { {} }

    subject { post api(url), headers: headers }

    context 'with valid project' do
      where(:visibility_level, :user_role, :shared_examples_name, :expected_status) do
        :public  | :developer    | 'process helm workhorse authorization' | :success
        :public  | :reporter     | 'rejects helm packages access'         | :forbidden
        :public  | :not_a_member | 'rejects helm packages access'         | :forbidden
        :public  | :anonymous    | 'rejects helm packages access'         | :unauthorized
        :private | :developer    | 'process helm workhorse authorization' | :success
        :private | :reporter     | 'rejects helm packages access'         | :forbidden
        :private | :not_a_member | 'rejects helm packages access'         | :not_found
        :private | :anonymous    | 'rejects helm packages access'         | :unauthorized
      end

      with_them do
        let(:user_headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, personal_access_token.token) }
        let(:headers) { user_headers.merge(workhorse_headers) }
        let(:snowplow_gitlab_standard_context) { snowplow_context(user_role: user_role) }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level.to_s))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status]
      end
    end

    context 'when an invalid token is passed' do
      let(:headers) { basic_auth_header(user.username, 'wrong') }

      it_behaves_like 'returning response status', :unauthorized
    end

    it_behaves_like 'deploy token for package uploads'

    it_behaves_like 'job token for package uploads', authorize_endpoint: true, accept_invalid_username: true do
      let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }
    end

    it_behaves_like 'rejects helm access with unknown project id'
  end

  describe 'POST /api/v4/projects/:id/packages/helm/api/:channel/charts' do
    include_context 'workhorse headers'

    let_it_be(:file_name) { 'package.tgz' }

    let(:channel) { 'stable' }
    let(:url) { "/projects/#{project.id}/packages/helm/api/#{channel}/charts" }
    let(:headers) { {} }
    let(:params) { { chart: temp_file(file_name) } }
    let(:file_key) { :chart }
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
      where(:visibility_level, :user_role, :shared_examples_name, :expected_status) do
        :public  | :developer     | 'process helm upload'          | :created
        :public  | :reporter      | 'rejects helm packages access' | :forbidden
        :public  | :not_a_member  | 'rejects helm packages access' | :forbidden
        :public  | :anonymous     | 'rejects helm packages access' | :unauthorized
        :private | :developer     | 'process helm upload'          | :created
        :private | :guest         | 'rejects helm packages access' | :forbidden
        :private | :not_a_member  | 'rejects helm packages access' | :not_found
        :private | :anonymous     | 'rejects helm packages access' | :unauthorized
      end

      with_them do
        let(:user_headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, personal_access_token.token) }
        let(:headers) { user_headers.merge(workhorse_headers) }
        let(:snowplow_gitlab_standard_context) { snowplow_context(user_role: user_role) }

        before do
          project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value(visibility_level.to_s))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status]
      end
    end

    context 'when an invalid token is passed' do
      let(:headers) { basic_auth_header(user.username, 'wrong') }

      it_behaves_like 'returning response status', :unauthorized
    end

    it_behaves_like 'deploy token for package uploads'

    it_behaves_like 'job token for package uploads', accept_invalid_username: true do
      let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }
    end

    it_behaves_like 'rejects helm access with unknown project id'

    context 'file size above maximum limit' do
      let(:headers) { basic_auth_header(deploy_token.username, deploy_token.token).merge(workhorse_headers) }

      before do
        allow_next_instance_of(UploadedFile) do |uploaded_file|
          allow(uploaded_file).to receive(:size).and_return(project.actual_limits.helm_max_file_size + 1)
        end
      end

      it_behaves_like 'returning response status', :bad_request
    end
  end
end
