# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::NugetProjectPackages, feature_category: :package_registry do
  include_context 'nuget api setup'

  using RSpec::Parameterized::TableSyntax

  let_it_be(:deploy_token) do
    create(:deploy_token, read_package_registry: true, write_package_registry: true, projects: [project])
  end

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
    let_it_be(:packages) { create_list(:nuget_package, 5, :with_metadatum, name: package_name, project: project) }
    let(:url) { "/projects/#{target.id}/packages/nuget/metadata/#{package_name}/index.json" }

    it_behaves_like 'handling nuget metadata requests with package name'

    it_behaves_like 'accept get request on private project with access to package registry for everyone'

    it_behaves_like 'authorizing granular token permissions', :read_nuget_package do
      let(:boundary_object) { project }
      let(:request) { get api(url), headers: basic_auth_header(user.username, pat.token) }

      before do
        project.add_developer(user)
      end
    end
  end

  describe 'GET /api/v4/projects/:id/packages/nuget/metadata/*package_name/*package_version' do
    let_it_be(:package) { create(:nuget_package, :with_metadatum, name: package_name, project: project) }
    let(:url) { "/projects/#{target.id}/packages/nuget/metadata/#{package_name}/#{package.version}.json" }

    it_behaves_like 'handling nuget metadata requests with package name and package version'

    it_behaves_like 'accept get request on private project with access to package registry for everyone'

    it_behaves_like 'authorizing granular token permissions', :read_nuget_package do
      let(:boundary_object) { project }
      let(:request) { get api(url), headers: basic_auth_header(user.username, pat.token) }

      before do
        project.add_developer(user)
      end
    end
  end

  describe 'GET /api/v4/projects/:id/packages/nuget/query' do
    let_it_be(:query_parameters) { { q: 'query', take: 5, skip: 0, prerelease: true } }
    let(:url) { "/projects/#{target.id}/packages/nuget/query?#{query_parameters.to_query}" }

    it_behaves_like 'handling nuget search requests'

    it_behaves_like 'accept get request on private project with access to package registry for everyone'

    it_behaves_like 'authorizing granular token permissions', :search_nuget_package do
      let(:boundary_object) { project }
      let(:request) { get api(url), headers: basic_auth_header(user.username, pat.token) }

      before do
        project.add_developer(user)
      end
    end
  end

  describe 'GET /api/v4/projects/:id/packages/nuget/download/*package_name/index' do
    let_it_be(:packages) { create_list(:nuget_package, 5, name: package_name, project: project) }

    let(:url) { "/projects/#{target.id}/packages/nuget/download/#{package_name}/index.json" }

    subject { get api(url), headers: }

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

        before do
          update_visibility_to(Gitlab::VisibilityLevel.const_get(visibility_level, false))
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end

    it_behaves_like 'updating personal access token last used' do
      let(:headers) { basic_auth_header(user.username, personal_access_token.token) }
    end

    it_behaves_like 'deploy token for package GET requests'

    it_behaves_like 'rejects nuget access with unknown target id'

    it_behaves_like 'rejects nuget access with invalid target id'

    it_behaves_like 'accept get request on private project with access to package registry for everyone'

    it_behaves_like 'authorizing granular token permissions', :read_nuget_package do
      let(:boundary_object) { project }
      let(:headers) { basic_auth_header(user.username, pat.token) }
      let(:request) { subject }

      before do
        project.add_developer(user)
      end
    end
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

    it_behaves_like 'updating personal access token last used' do
      let(:headers) { basic_auth_header(user.username, personal_access_token.token) }
    end

    it_behaves_like 'rejects nuget access with unknown target id'

    it_behaves_like 'rejects nuget access with invalid target id'

    it_behaves_like 'authorizing granular token permissions', :download_nuget_package do
      let(:boundary_object) { project }
      let(:headers) { basic_auth_header(user.username, pat.token) }
      let(:request) { subject }

      before do
        project.add_developer(user)
      end
    end
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
    let(:url) { "/projects/#{target.id}/packages/nuget/authorize" }

    it_behaves_like 'nuget authorize upload endpoint'
  end

  describe 'PUT /api/v4/projects/:id/packages/nuget' do
    let(:url) { "/projects/#{target.id}/packages/nuget" }

    it_behaves_like 'nuget upload endpoint'

    it_behaves_like 'authorizing granular token permissions', :upload_nuget_package do
      include_context 'workhorse headers'

      let(:file_name) { 'package.nupkg' }
      let(:boundary_object) { project }
      let(:request) do
        workhorse_finalize(
          api(url),
          method: :put,
          file_key: :package,
          params: { package: fixture_file_upload("spec/fixtures/packages/nuget/#{file_name}") },
          headers: workhorse_headers.merge(basic_auth_header(user.username, pat.token)),
          send_rewritten_field: true
        )
      end

      before do
        project.add_developer(user)
      end
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/nuget/symbolpackage/authorize' do
    let(:url) { "/projects/#{target.id}/packages/nuget/symbolpackage/authorize" }

    it_behaves_like 'nuget authorize upload endpoint'
  end

  describe 'PUT /api/v4/projects/:id/packages/nuget/symbolpackage' do
    let(:url) { "/projects/#{target.id}/packages/nuget/symbolpackage" }

    it_behaves_like 'nuget upload endpoint', symbol_package: true

    it_behaves_like 'authorizing granular token permissions', :upload_nuget_package do
      include_context 'workhorse headers'

      let(:file_name) { 'package.snupkg' }
      let(:boundary_object) { project }
      let(:request) do
        workhorse_finalize(
          api(url),
          method: :put,
          file_key: :package,
          params: { package: fixture_file_upload("spec/fixtures/packages/nuget/#{file_name}") },
          headers: workhorse_headers.merge(basic_auth_header(user.username, pat.token)),
          send_rewritten_field: true
        )
      end

      before do
        project.add_developer(user)
      end
    end
  end

  describe 'DELETE /api/v4/projects/:id/packages/nuget/*package_name/*package_version' do
    let_it_be(:package) { create(:nuget_package, project: project, name: package_name) }

    let(:url) { "/projects/#{target.id}/packages/nuget/#{package_name}/#{package.version}" }

    subject { delete api(url), headers: headers }

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'authorizing granular token permissions', :delete_nuget_package do
      let(:boundary_object) { project }
      let(:request) { delete api(url), headers: basic_auth_header(user.username, pat.token) }

      before do
        project.add_maintainer(user)
      end
    end

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

    context 'with package protection rules' do
      let_it_be_with_reload(:package_protection_rule) { create(:package_protection_rule, :nuget, project:) }

      let_it_be(:pat_project_maintainer) do
        create(:personal_access_token, user: create(:user, maintainer_of: [project]))
      end

      let_it_be(:pat_project_owner) { create(:personal_access_token, user: create(:user, owner_of: [project])) }
      let_it_be(:pat_instance_admin) { create(:personal_access_token, :admin_mode, user: create(:admin)) }
      let_it_be(:job_from_project_maintainer) do
        create(:ci_build, :running, user: pat_project_maintainer.user, project: project)
      end

      let_it_be(:job_from_project_owner) { create(:ci_build, :running, user: pat_project_owner.user, project: project) }

      let(:headers_maintainer) { user_basic_auth_header(pat_project_maintainer.user, pat_project_maintainer) }
      let(:headers_owner) { user_basic_auth_header(pat_project_owner.user, pat_project_owner) }
      let(:headers_admin) { user_basic_auth_header(pat_instance_admin.user, pat_instance_admin) }
      let(:headers_job_maintainer) { job_basic_auth_header(job_from_project_maintainer) }
      let(:headers_job_owner) { job_basic_auth_header(job_from_project_owner) }

      let(:package_name_no_match) { "#{package_name}_no_match" }

      subject do
        delete api(url), headers: headers
        response
      end

      shared_examples 'deleting nuget package protected' do
        it_behaves_like 'returning response status with message',
          status: :forbidden,
          message: 'Package is deletion protected.'

        it { expect { subject }.not_to change { ::Packages::Nuget::Package.pending_destruction.size } }

        context 'when feature flag :packages_protected_packages_delete is disabled' do
          before do
            stub_feature_flags(packages_protected_packages_delete: false)
          end

          it_behaves_like 'deleting nuget package'
        end
      end

      shared_examples 'deleting nuget package' do
        it 'marks the package for destruction' do
          expect { subject }.to change { ::Packages::Nuget::Package.pending_destruction.size }.by(1)
          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      where(:package_name_pattern, :minimum_access_level_for_delete, :headers, :shared_examples_name) do
        ref(:package_name)          | :owner | ref(:headers_job_maintainer) | 'deleting nuget package protected'
        ref(:package_name)          | :owner | ref(:headers_job_owner)      | 'deleting nuget package'
        ref(:package_name)          | :owner | ref(:headers_maintainer)     | 'deleting nuget package protected'
        ref(:package_name)          | :owner | ref(:headers_owner)          | 'deleting nuget package'
        ref(:package_name)          | :owner | ref(:headers_admin)          | 'deleting nuget package'

        ref(:package_name)          | :admin | ref(:headers_job_owner)      | 'deleting nuget package protected'
        ref(:package_name)          | :admin | ref(:headers_maintainer)     | 'deleting nuget package protected'
        ref(:package_name)          | :admin | ref(:headers_owner)          | 'deleting nuget package protected'
        ref(:package_name)          | :admin | ref(:headers_admin)          | 'deleting nuget package'

        ref(:package_name_no_match) | :owner | ref(:headers_owner)          | 'deleting nuget package'
      end

      with_them do
        before do
          package_protection_rule.update!(
            package_name_pattern: package_name_pattern,
            minimum_access_level_for_delete: minimum_access_level_for_delete
          )
        end

        it_behaves_like params[:shared_examples_name]
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

    it_behaves_like 'updating personal access token last used' do
      let(:headers) { basic_auth_header(user.username, personal_access_token.token) }
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/nuget/v2/authorize' do
    let(:url) { "/projects/#{target.id}/packages/nuget/v2/authorize" }

    it_behaves_like 'nuget authorize upload endpoint'
  end

  describe 'PUT /api/v4/projects/:id/packages/nuget/v2' do
    let(:url) { "/projects/#{target.id}/packages/nuget/v2" }

    it_behaves_like 'nuget upload endpoint'

    it_behaves_like 'authorizing granular token permissions', :upload_nuget_package do
      include_context 'workhorse headers'

      let(:file_name) { 'package.nupkg' }
      let(:boundary_object) { project }
      let(:request) do
        workhorse_finalize(
          api(url),
          method: :put,
          file_key: :package,
          params: { package: fixture_file_upload("spec/fixtures/packages/nuget/#{file_name}") },
          headers: workhorse_headers.merge(basic_auth_header(user.username, pat.token)),
          send_rewritten_field: true
        )
      end

      before do
        project.add_developer(user)
      end
    end
  end

  describe 'GET /api/v4/projects/:id/packages/nuget/symbolfiles/*file_name/*signature/*file_name' do
    it_behaves_like 'nuget symbol file endpoint' do
      let(:url) { "/projects/#{target.id}/packages/nuget/symbolfiles/#{filename}/#{signature}/#{filename}" }

      context 'when symbol belongs to a different project within the same namespace' do
        before do
          allow_next_instance_of(::Namespace::PackageSetting) do |setting|
            allow(setting).to receive(:nuget_symbol_server_enabled).and_return(true)
          end
        end

        let_it_be(:other_project) { create(:project, namespace: project.namespace) }
        let_it_be(:other_package) { create(:nuget_package, project: other_project, without_package_files: true) }
        let_it_be(:other_symbol) { create(:nuget_symbol, package: other_package) }

        let(:filename) { other_symbol.file.filename }
        let(:signature) { other_symbol.signature }
        let(:checksum) { other_symbol.file_sha256.delete("\n") }

        it_behaves_like 'returning response status', :not_found
      end
    end
  end

  describe 'X-NuGet-Warning header' do
    context 'with an unauthorized request' do
      let(:url) { "/projects/#{target.id}/packages/nuget/metadata/Dummy.Package/index.json" }
      let(:expected_status) { :unauthorized }

      subject { get api(url) }

      before do
        update_visibility_to(Gitlab::VisibilityLevel::PRIVATE)
      end

      it_behaves_like 'setting the X-NuGet-Warning header on error responses',
        expected_warning: '401 Unauthorized'
    end

    context 'with a forbidden request' do
      include_context 'workhorse headers'

      let(:url) { "/projects/#{target.id}/packages/nuget/authorize" }
      let(:expected_status) { :forbidden }

      subject do
        put api(url),
          headers: basic_auth_header(user.username, personal_access_token.token).merge(workhorse_headers)
      end

      before do
        target.add_guest(user)
      end

      it_behaves_like 'setting the X-NuGet-Warning header on error responses',
        expected_warning: '403 Forbidden'
    end

    context 'with a not found request' do
      let(:url) { "/projects/#{non_existing_record_id}/packages/nuget/metadata/Dummy.Package/index.json" }
      let(:expected_status) { :not_found }

      subject { get api(url), headers: basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'setting the X-NuGet-Warning header on error responses',
        expected_warning: '404 Not Found'
    end

    context 'with a successful request' do
      let(:url) { "/projects/#{target.id}/packages/nuget/index.json" }

      it 'does not include the X-NuGet-Warning header' do
        get api(url)

        expect(response).to have_gitlab_http_status(:success)
        expect(response.headers['X-NuGet-Warning']).to be_nil
      end
    end
  end

  def update_visibility_to(visibility)
    project.update!(visibility_level: visibility)
  end
end
