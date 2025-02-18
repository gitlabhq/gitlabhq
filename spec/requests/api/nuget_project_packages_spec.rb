# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::NugetProjectPackages, feature_category: :package_registry do
  include_context 'nuget api setup'

  using RSpec::Parameterized::TableSyntax

  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }
  let_it_be(:package_name) { 'Dummy.Package' }

  let(:target) { project }
  let(:target_type) { 'projects' }
  let(:snowplow_gitlab_standard_context) { snowplow_context }

  def snowplow_context(user_role: :developer, event_user: user)
    { project: target, namespace: target.namespace, property: 'i_package_nuget_user' }.tap do |context|
      context[:user] = event_user unless user_role == :anonymous
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

  shared_examples 'nuget serialize odata package endpoint' do
    subject { get api(url), params: params }

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'returning response status', :success

    it 'returns a valid xml response and invokes OdataPackageEntryService' do
      expect(Packages::Nuget::OdataPackageEntryService).to receive(:new).with(target, service_params).and_call_original

      subject

      expect(response.media_type).to eq('application/xml')
    end

    [nil, '', '%20', '..%2F..', '../..'].each do |value|
      context "with invalid package name #{value}" do
        let(:package_name) { value }

        it_behaves_like 'returning response status', :bad_request
      end
    end

    context 'with missing required params' do
      let(:params) { {} }
      let(:package_version) { nil }

      it_behaves_like 'returning response status', :bad_request
    end
  end

  describe 'GET /api/v4/projects/:id/packages/nuget' do
    let(:url) { "/projects/#{target.id}/packages/nuget/index.json" }

    it_behaves_like 'handling nuget service requests'

    it_behaves_like 'accept get request on private project with access to package registry for everyone'
  end

  describe 'GET /api/v4/projects/:id/packages/nuget/v2' do
    let(:url) { "/projects/#{target.id}/packages/nuget/v2" }

    it_behaves_like 'handling nuget service requests', v2: true

    it_behaves_like 'accept get request on private project with access to package registry for everyone'
  end

  describe 'GET /api/v4/projects/:id/packages/nuget/v2/$metadata' do
    let(:url) { "/projects/#{target.id}/packages/nuget/v2/$metadata" }

    subject(:api_request) { get api(url) }

    it { is_expected.to have_request_urgency(:low) }

    context 'with valid target' do
      using RSpec::Parameterized::TableSyntax

      where(:visibility_level, :user_role, :member, :expected_status) do
        'PUBLIC'   | :developer  | true  | :success
        'PUBLIC'   | :guest      | true  | :success
        'PUBLIC'   | :developer  | false | :success
        'PUBLIC'   | :guest      | false | :success
        'PUBLIC'   | :anonymous  | false | :success
        'PRIVATE'  | :developer  | true  | :success
        'PRIVATE'  | :guest      | true  | :success
        'PRIVATE'  | :developer  | false | :success
        'PRIVATE'  | :guest      | false | :success
        'PRIVATE'  | :anonymous  | false | :success
        'INTERNAL' | :developer  | true  | :success
        'INTERNAL' | :guest      | true  | :success
        'INTERNAL' | :developer  | false | :success
        'INTERNAL' | :guest      | false | :success
        'INTERNAL' | :anonymous  | false | :success
      end

      with_them do
        before do
          update_visibility_to(Gitlab::VisibilityLevel.const_get(visibility_level, false))
        end

        it_behaves_like 'process nuget v2 $metadata service request', params[:user_role], params[:expected_status],
          params[:member]
      end
    end
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
        'PRIVATE' | :guest      | true  | true  | 'process nuget download versions request'   | :success
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
    let_it_be(:package) do
      create(:nuget_package, :with_symbol_package, :with_metadatum, project: project, name: package_name,
        version: '0.1')
    end

    let_it_be(:package_version) { package.version }

    let(:format) { 'nupkg' }
    let(:url) do
      "/projects/#{target.id}/packages/nuget/download/" \
        "#{package.name}/#{package_version}/#{package.name}.#{package_version}.#{format}"
    end

    subject { get api(url), headers: headers }

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
        'PRIVATE' | :guest      | true  | true  | 'process nuget download content request'   | :success
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

  describe 'GET /api/v4/projects/:id/packages/nuget/v2/FindPackagesById()' do
    it_behaves_like 'nuget serialize odata package endpoint' do
      let(:url) { "/projects/#{target.id}/packages/nuget/v2/FindPackagesById()" }
      let(:params) { { id: "'#{package_name}'" } }
      let(:service_params) { { package_name: package_name } }
    end
  end

  describe 'GET /api/v4/projects/:id/packages/nuget/v2/Packages()' do
    it_behaves_like 'nuget serialize odata package endpoint' do
      let(:url) { "/projects/#{target.id}/packages/nuget/v2/Packages()" }
      let(:params) { { '$filter' => "(tolower(Id) eq '#{package_name&.downcase}')" } }
      let(:service_params) { { package_name: package_name&.downcase } }
    end
  end

  describe 'GET /api/v4/projects/:id/packages/nuget/v2/Packages(Id=\'*\',Version=\'*\')' do
    let(:package_version) { '1.0.0' }
    let(:url) { "/projects/#{target.id}/packages/nuget/v2/Packages(Id='#{package_name}',Version='#{package_version}')" }
    let(:params) { {} }
    let(:service_params) { { package_name: package_name, package_version: package_version } }

    it_behaves_like 'nuget serialize odata package endpoint'

    context 'with invalid package version' do
      subject { get api(url) }

      ['', '1', '1./2.3', '%20', '..%2F..', '../..'].each do |value|
        context "with invalid package version #{value}" do
          let(:package_version) { value }

          it_behaves_like 'returning response status', :bad_request
        end
      end
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/nuget/authorize' do
    it_behaves_like 'nuget authorize upload endpoint' do
      let(:url) { "/projects/#{target.id}/packages/nuget/authorize" }
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/nuget' do
    it_behaves_like 'nuget upload endpoint' do
      let(:url) { "/projects/#{target.id}/packages/nuget" }
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/nuget/symbolpackage/authorize' do
    it_behaves_like 'nuget authorize upload endpoint' do
      let(:url) { "/projects/#{target.id}/packages/nuget/symbolpackage/authorize" }
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/nuget/symbolpackage' do
    it_behaves_like 'nuget upload endpoint', symbol_package: true do
      let(:url) { "/projects/#{target.id}/packages/nuget/symbolpackage" }
    end
  end

  describe 'DELETE /api/v4/projects/:id/packages/nuget/*package_name/*package_version' do
    let_it_be(:package) { create(:nuget_package, project: project, name: package_name) }

    let(:url) { "/projects/#{target.id}/packages/nuget/#{package_name}/#{package.version}" }

    subject { delete api(url), headers: headers }

    it { is_expected.to have_request_urgency(:low) }

    context 'with valid target' do
      where(:auth, :visibility, :user_role, :shared_examples_name, :expected_status) do
        nil    | :public   | :anonymous    | 'rejects nuget packages access' | :unauthorized
        nil    | :private  | :anonymous    | 'rejects nuget packages access' | :unauthorized
        nil    | :internal | :anonymous    | 'rejects nuget packages access' | :unauthorized

        :personal_access_token | :public   | :guest      | 'rejects nuget packages access' | :forbidden
        :personal_access_token | :public   | :developer  | 'rejects nuget packages access' | :forbidden
        :personal_access_token | :public   | :maintainer | 'process nuget delete request'  | :no_content
        :personal_access_token | :private  | :guest      | 'rejects nuget packages access' | :forbidden
        :personal_access_token | :private  | :developer  | 'rejects nuget packages access' | :forbidden
        :personal_access_token | :private  | :maintainer | 'process nuget delete request'  | :no_content
        :personal_access_token | :internal | :guest      | 'rejects nuget packages access' | :forbidden
        :personal_access_token | :internal | :developer  | 'rejects nuget packages access' | :forbidden
        :personal_access_token | :internal | :maintainer | 'process nuget delete request'  | :no_content

        :job_token | :public   | :guest      | 'rejects nuget packages access' | :forbidden
        :job_token | :public   | :developer  | 'rejects nuget packages access' | :forbidden
        :job_token | :public   | :maintainer | 'process nuget delete request'  | :no_content
        :job_token | :private  | :guest      | 'rejects nuget packages access' | :forbidden
        :job_token | :private  | :developer  | 'rejects nuget packages access' | :forbidden
        :job_token | :private  | :maintainer | 'process nuget delete request'  | :no_content
        :job_token | :internal | :guest      | 'rejects nuget packages access' | :forbidden
        :job_token | :internal | :developer  | 'rejects nuget packages access' | :forbidden
        :job_token | :internal | :maintainer | 'process nuget delete request'  | :no_content

        :deploy_token | :public   | nil | 'process nuget delete request'  | :no_content
        :deploy_token | :private  | nil | 'process nuget delete request'  | :no_content
        :deploy_token | :internal | nil | 'process nuget delete request'  | :no_content

        :api_key | :public   | :guest      | 'rejects nuget packages access' | :forbidden
        :api_key | :public   | :developer  | 'rejects nuget packages access' | :forbidden
        :api_key | :public   | :maintainer | 'process nuget delete request'  | :no_content
        :api_key | :private  | :guest      | 'rejects nuget packages access' | :forbidden
        :api_key | :private  | :developer  | 'rejects nuget packages access' | :forbidden
        :api_key | :private  | :maintainer | 'process nuget delete request'  | :no_content
        :api_key | :internal | :guest      | 'rejects nuget packages access' | :forbidden
        :api_key | :internal | :developer  | 'rejects nuget packages access' | :forbidden
        :api_key | :internal | :maintainer | 'process nuget delete request'  | :no_content
      end

      with_them do
        let(:snowplow_gitlab_standard_context) do
          snowplow_context(user_role: user_role, event_user: auth == :deploy_token ? deploy_token : user)
        end

        let(:headers) do
          case auth
          when :personal_access_token
            basic_auth_header(user.username, personal_access_token.token)
          when :job_token
            basic_auth_header(::Gitlab::Auth::CI_JOB_USER, job.token)
          when :deploy_token
            basic_auth_header(deploy_token.username, deploy_token.token)
          when :api_key
            { 'X-NuGet-ApiKey' => personal_access_token.token }
          else
            {}
          end
        end

        before do
          update_visibility_to(Gitlab::VisibilityLevel.const_get(visibility.to_s.upcase, false))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:auth]
      end
    end

    it_behaves_like 'rejects nuget access with unknown target id'

    it_behaves_like 'rejects nuget access with invalid target id'

    ['%20', '..%2F..', '../..'].each do |value|
      context "with invalid package name #{value}" do
        let(:package_name) { value }

        it_behaves_like 'returning response status', :bad_request
      end
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/nuget/v2/authorize' do
    it_behaves_like 'nuget authorize upload endpoint' do
      let(:url) { "/projects/#{target.id}/packages/nuget/v2/authorize" }
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/nuget/v2' do
    it_behaves_like 'nuget upload endpoint' do
      let(:url) { "/projects/#{target.id}/packages/nuget/v2" }
    end
  end

  describe 'GET /api/v4/projects/:id/packages/nuget/symbolfiles/*file_name/*signature/*file_name' do
    it_behaves_like 'nuget symbol file endpoint' do
      let(:url) { "/projects/#{target.id}/packages/nuget/symbolfiles/#{filename}/#{signature}/#{filename}" }
    end
  end

  def update_visibility_to(visibility)
    project.update!(visibility_level: visibility)
  end
end
