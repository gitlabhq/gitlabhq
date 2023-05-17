# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::NugetProjectPackages, feature_category: :package_registry do
  include_context 'nuget api setup'

  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) { create(:project, :public) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }
  let_it_be(:package_name) { 'Dummy.Package' }

  let(:target) { project }
  let(:target_type) { 'projects' }
  let(:snowplow_gitlab_standard_context) { snowplow_context }

  def snowplow_context(user_role: :developer)
    if user_role == :anonymous
      { project: target, namespace: target.namespace, property: 'i_package_nuget_user' }
    else
      { project: target, namespace: target.namespace, property: 'i_package_nuget_user', user: user }
    end
  end

  shared_examples 'accept get request on private project with access to package registry for everyone' do
    subject { get api(url) }

    before do
      update_visibility_to(Gitlab::VisibilityLevel::PRIVATE)
      project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
    end

    it_behaves_like 'returning response status', :ok
  end

  describe 'GET /api/v4/projects/:id/packages/nuget' do
    let(:url) { "/projects/#{target.id}/packages/nuget/index.json" }

    it_behaves_like 'handling nuget service requests'

    it_behaves_like 'accept get request on private project with access to package registry for everyone'
  end

  describe 'GET /api/v4/projects/:id/packages/nuget/metadata/*package_name/index' do
    let(:url) { "/projects/#{target.id}/packages/nuget/metadata/#{package_name}/index.json" }

    it_behaves_like 'handling nuget metadata requests with package name'

    it_behaves_like 'accept get request on private project with access to package registry for everyone' do
      let_it_be(:packages) { create_list(:nuget_package, 5, :with_metadatum, name: package_name, project: project) }
    end
  end

  describe 'GET /api/v4/projects/:id/packages/nuget/metadata/*package_name/*package_version' do
    let(:url) { "/projects/#{target.id}/packages/nuget/metadata/#{package_name}/#{package.version}.json" }

    it_behaves_like 'handling nuget metadata requests with package name and package version'

    it_behaves_like 'accept get request on private project with access to package registry for everyone' do
      let_it_be(:package) { create(:nuget_package, :with_metadatum, name: package_name, project: project) }
    end
  end

  describe 'GET /api/v4/projects/:id/packages/nuget/query' do
    let(:url) { "/projects/#{target.id}/packages/nuget/query?#{query_parameters.to_query}" }

    it_behaves_like 'handling nuget search requests'

    it_behaves_like 'accept get request on private project with access to package registry for everyone' do
      let_it_be(:query_parameters) { { q: 'query', take: 5, skip: 0, prerelease: true } }
    end
  end

  describe 'GET /api/v4/projects/:id/packages/nuget/download/*package_name/index' do
    let_it_be(:packages) { create_list(:nuget_package, 5, name: package_name, project: project) }

    let(:url) { "/projects/#{target.id}/packages/nuget/download/#{package_name}/index.json" }

    subject { get api(url) }

    context 'with valid target' do
      where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
        'PUBLIC'  | :developer  | true  | true  | 'process nuget download versions request'   | :success
        'PUBLIC'  | :guest      | true  | true  | 'process nuget download versions request'   | :success
        'PUBLIC'  | :developer  | true  | false | 'rejects nuget packages access'             | :unauthorized
        'PUBLIC'  | :guest      | true  | false | 'rejects nuget packages access'             | :unauthorized
        'PUBLIC'  | :developer  | false | true  | 'process nuget download versions request'   | :success
        'PUBLIC'  | :guest      | false | true  | 'process nuget download versions request'   | :success
        'PUBLIC'  | :developer  | false | false | 'rejects nuget packages access'             | :unauthorized
        'PUBLIC'  | :guest      | false | false | 'rejects nuget packages access'             | :unauthorized
        'PUBLIC'  | :anonymous  | false | true  | 'process nuget download versions request'   | :success
        'PRIVATE' | :developer  | true  | true  | 'process nuget download versions request'   | :success
        'PRIVATE' | :guest      | true  | true  | 'rejects nuget packages access'             | :forbidden
        'PRIVATE' | :developer  | true  | false | 'rejects nuget packages access'             | :unauthorized
        'PRIVATE' | :guest      | true  | false | 'rejects nuget packages access'             | :unauthorized
        'PRIVATE' | :developer  | false | true  | 'rejects nuget packages access'             | :not_found
        'PRIVATE' | :guest      | false | true  | 'rejects nuget packages access'             | :not_found
        'PRIVATE' | :developer  | false | false | 'rejects nuget packages access'             | :unauthorized
        'PRIVATE' | :guest      | false | false | 'rejects nuget packages access'             | :unauthorized
        'PRIVATE' | :anonymous  | false | true  | 'rejects nuget packages access'             | :unauthorized
      end

      with_them do
        let(:token) { user_token ? personal_access_token.token : 'wrong' }
        let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }

        subject { get api(url), headers: headers }

        before do
          update_visibility_to(Gitlab::VisibilityLevel.const_get(visibility_level, false))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end

    it_behaves_like 'deploy token for package GET requests'

    it_behaves_like 'rejects nuget access with unknown target id'

    it_behaves_like 'rejects nuget access with invalid target id'

    it_behaves_like 'accept get request on private project with access to package registry for everyone'
  end

  describe 'GET /api/v4/projects/:id/packages/nuget/download/*package_name/*package_version/*package_filename' do
    let_it_be(:package) { create(:nuget_package, :with_symbol_package, project: project, name: package_name) }

    let(:format) { 'nupkg' }
    let(:url) { "/projects/#{target.id}/packages/nuget/download/#{package.name}/#{package.version}/#{package.name}.#{package.version}.#{format}" }

    subject { get api(url) }

    context 'with valid target' do
      where(:visibility_level, :user_role, :member, :user_token, :shared_examples_name, :expected_status) do
        'PUBLIC'  | :developer  | true  | true  | 'process nuget download content request'   | :success
        'PUBLIC'  | :guest      | true  | true  | 'process nuget download content request'   | :success
        'PUBLIC'  | :developer  | true  | false | 'rejects nuget packages access'            | :unauthorized
        'PUBLIC'  | :guest      | true  | false | 'rejects nuget packages access'            | :unauthorized
        'PUBLIC'  | :developer  | false | true  | 'process nuget download content request'   | :success
        'PUBLIC'  | :guest      | false | true  | 'process nuget download content request'   | :success
        'PUBLIC'  | :developer  | false | false | 'rejects nuget packages access'            | :unauthorized
        'PUBLIC'  | :guest      | false | false | 'rejects nuget packages access'            | :unauthorized
        'PUBLIC'  | :anonymous  | false | true  | 'process nuget download content request'   | :success
        'PRIVATE' | :developer  | true  | true  | 'process nuget download content request'   | :success
        'PRIVATE' | :guest      | true  | true  | 'rejects nuget packages access'            | :forbidden
        'PRIVATE' | :developer  | true  | false | 'rejects nuget packages access'            | :unauthorized
        'PRIVATE' | :guest      | true  | false | 'rejects nuget packages access'            | :unauthorized
        'PRIVATE' | :developer  | false | true  | 'rejects nuget packages access'            | :not_found
        'PRIVATE' | :guest      | false | true  | 'rejects nuget packages access'            | :not_found
        'PRIVATE' | :developer  | false | false | 'rejects nuget packages access'            | :unauthorized
        'PRIVATE' | :guest      | false | false | 'rejects nuget packages access'            | :unauthorized
        'PRIVATE' | :anonymous  | false | true  | 'rejects nuget packages access'            | :unauthorized
      end

      with_them do
        let(:token) { user_token ? personal_access_token.token : 'wrong' }
        let(:headers) { user_role == :anonymous ? {} : basic_auth_header(user.username, token) }
        let(:snowplow_gitlab_standard_context) { snowplow_context(user_role: user_role) }

        subject { get api(url), headers: headers }

        before do
          update_visibility_to(Gitlab::VisibilityLevel.const_get(visibility_level, false))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end

      it_behaves_like 'accept get request on private project with access to package registry for everyone'
    end

    it_behaves_like 'deploy token for package GET requests' do
      before do
        update_visibility_to(Gitlab::VisibilityLevel::PRIVATE)
      end
    end

    it_behaves_like 'rejects nuget access with unknown target id'

    it_behaves_like 'rejects nuget access with invalid target id'
  end

  describe 'PUT /api/v4/projects/:id/packages/nuget/authorize' do
    include_context 'workhorse headers'

    let(:url) { "/projects/#{target.id}/packages/nuget/authorize" }
    let(:headers) { {} }

    subject { put api(url), headers: headers }

    it_behaves_like 'nuget authorize upload endpoint'
  end

  describe 'PUT /api/v4/projects/:id/packages/nuget' do
    include_context 'workhorse headers'

    let_it_be(:file_name) { 'package.nupkg' }

    let(:url) { "/projects/#{target.id}/packages/nuget" }
    let(:headers) { {} }
    let(:params) { { package: temp_file(file_name) } }
    let(:file_key) { :package }
    let(:send_rewritten_field) { true }

    subject do
      workhorse_finalize(
        api(url),
        method: :put,
        file_key: file_key,
        params: params,
        headers: headers,
        send_rewritten_field: send_rewritten_field
      )
    end

    it_behaves_like 'nuget upload endpoint'
  end

  describe 'PUT /api/v4/projects/:id/packages/nuget/symbolpackage/authorize' do
    include_context 'workhorse headers'

    let(:url) { "/projects/#{target.id}/packages/nuget/symbolpackage/authorize" }
    let(:headers) { {} }

    subject { put api(url), headers: headers }

    it_behaves_like 'nuget authorize upload endpoint'
  end

  describe 'PUT /api/v4/projects/:id/packages/nuget/symbolpackage' do
    include_context 'workhorse headers'

    let_it_be(:file_name) { 'package.snupkg' }

    let(:url) { "/projects/#{target.id}/packages/nuget/symbolpackage" }
    let(:headers) { {} }
    let(:params) { { package: temp_file(file_name) } }
    let(:file_key) { :package }
    let(:send_rewritten_field) { true }

    subject do
      workhorse_finalize(
        api(url),
        method: :put,
        file_key: file_key,
        params: params,
        headers: headers,
        send_rewritten_field: send_rewritten_field
      )
    end

    it_behaves_like 'nuget upload endpoint', symbol_package: true
  end

  def update_visibility_to(visibility)
    project.update!(visibility_level: visibility)
  end
end
