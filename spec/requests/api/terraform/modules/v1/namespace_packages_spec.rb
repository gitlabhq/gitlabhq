# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Terraform::Modules::V1::NamespacePackages, feature_category: :package_registry do
  include_context 'for terraform modules api setup'
  using RSpec::Parameterized::TableSyntax

  describe 'GET /api/v4/packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/versions' do
    let(:url) { api("/packages/terraform/modules/v1/#{group.path}/#{package.name}/versions") }
    let(:headers) { { 'Authorization' => "Bearer #{tokens[:job_token]}" } }

    subject(:get_versions) { get(url, headers: headers) }

    context 'with a conflicting package name' do
      let!(:conflicting_package) do
        create(:terraform_module_package, project: project, name: "conflict-#{package.name}", version: '2.0.0')
      end

      before do
        group.add_developer(user)
      end

      it 'returns only one version' do
        get_versions

        expect(json_response['modules'][0]['versions'].size).to eq(1)
        expect(json_response['modules'][0]['versions'][0]['version']).to eq('1.0.0')
      end
    end

    context 'with valid namespace' do
      where(:visibility, :user_role, :member, :token_type, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | :personal_access_token | 'returns terraform module packages'        | :success
        :public  | :guest      | true  | :personal_access_token | 'returns terraform module packages'        | :success
        :public  | :developer  | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | false | :personal_access_token | 'returns no terraform module packages'     | :success
        :public  | :guest      | false | :personal_access_token | 'returns no terraform module packages'     | :success
        :public  | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :anonymous  | false | nil | 'returns no terraform module packages' | :success
        :private | :developer  | true  | :personal_access_token | 'returns terraform module packages' | :success
        :private | :guest      | true  | :personal_access_token | 'returns terraform module packages' | :success
        :private | :developer  | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | false | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :private | :guest      | false | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :private | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :anonymous  | false | nil | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | true  | :job_token | 'returns terraform module packages' | :success
        :public  | :guest      | true  | :job_token | 'returns terraform module packages' | :success
        :public  | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | false | :job_token | 'returns no terraform module packages'     | :success
        :public  | :guest      | false | :job_token | 'returns no terraform module packages'     | :success
        :public  | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | true  | :job_token | 'returns terraform module packages' | :success
        :private | :guest      | true  | :job_token | 'returns terraform module packages' | :success
        :private | :developer  | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | false | :job_token | 'rejects terraform module packages access' | :forbidden
        :private | :guest      | false | :job_token | 'rejects terraform module packages access' | :forbidden
        :private | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
      end

      with_them do
        let(:headers) { user_role == :anonymous ? {} : { 'Authorization' => "Bearer #{token}" } }

        before do
          group.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end

    it_behaves_like 'accessing a public/internal project with another project\'s job token'
    it_behaves_like 'allowing anyone to pull public terraform modules'
  end

  describe 'GET /api/v4/packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/download' do
    let_it_be(:package_name) { package.name }
    let_it_be(:url) { api("/packages/terraform/modules/v1/#{group.path}/#{package_name}/download") }

    subject(:get_download) { get(url, headers: headers) }

    context 'with empty registry' do
      let(:package_name) { 'non-existent-package' }
      let(:headers) { {} }

      it 'returns not found when there is no module' do
        get_download

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with valid namespace' do
      let(:headers) { {} }

      before_all do
        create(:terraform_module_package, project: project, name: package.name, version: '1.0.1')
      end

      where(:visibility, :user_role, :member, :token_type, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | :personal_access_token | 'redirects to version download'         | :found
        :public  | :guest      | true  | :personal_access_token | 'redirects to version download'         | :found
        :public  | :developer  | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | false | :personal_access_token | 'redirects to version download'         | :found
        :public  | :guest      | false | :personal_access_token | 'redirects to version download'         | :found
        :public  | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :anonymous  | false | nil | 'redirects to version download' | :found
        :private | :developer  | true  | :personal_access_token | 'redirects to version download' | :found
        :private | :guest      | true  | :personal_access_token | 'redirects to version download' | :found
        :private | :developer  | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | false | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :private | :guest      | false | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :private | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :anonymous  | false | nil | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | true  | :job_token | 'redirects to version download'         | :found
        :public  | :guest      | true  | :job_token | 'redirects to version download'         | :found
        :public  | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | false | :job_token | 'redirects to version download'         | :found
        :public  | :guest      | false | :job_token | 'redirects to version download'         | :found
        :public  | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | true  | :job_token | 'redirects to version download' | :found
        :private | :guest      | true  | :job_token | 'redirects to version download' | :found
        :private | :developer  | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | false | :job_token | 'rejects terraform module packages access' | :forbidden
        :private | :guest      | false | :job_token | 'rejects terraform module packages access' | :forbidden
        :private | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
      end

      with_them do
        let(:headers) { user_role == :anonymous ? {} : { 'Authorization' => "Bearer #{token}" } }

        before do
          group.update!(visibility: visibility.to_s)
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end

    it_behaves_like 'accessing a public/internal project with another project\'s job token', :found
    it_behaves_like 'allowing anyone to pull public terraform modules', :found
  end

  describe 'GET /api/v4/packages/terraform/modules/v1/:module_namespace/:module_name/:module_system' do
    let_it_be(:package_name) { package.name }
    let_it_be(:url) { api("/packages/terraform/modules/v1/#{group.path}/#{package_name}") }

    subject(:get_module) { get(url, headers: headers) }

    context 'with empty registry' do
      let(:package_name) { 'non-existent-package' }
      let(:headers) { { 'Authorization' => "Bearer #{tokens[:personal_access_token]}" } }

      it 'returns not found when there is no module' do
        get_module

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with valid namespace' do
      where(:visibility, :user_role, :member, :token_type, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | :personal_access_token | 'returns terraform module version'         | :success
        :public  | :guest      | true  | :personal_access_token | 'returns terraform module version'         | :success
        :public  | :developer  | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | false | :personal_access_token | 'returns terraform module version'         | :success
        :public  | :guest      | false | :personal_access_token | 'returns terraform module version'         | :success
        :public  | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :anonymous  | false | nil | 'returns terraform module version' | :success
        :private | :developer  | true  | :personal_access_token | 'returns terraform module version' | :success
        :private | :guest      | true  | :personal_access_token | 'returns terraform module version' | :success
        :private | :developer  | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | false | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :private | :guest      | false | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :private | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :anonymous  | false | nil | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | true  | :job_token | 'returns terraform module version'         | :success
        :public  | :guest      | true  | :job_token | 'returns terraform module version'         | :success
        :public  | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | false | :job_token | 'returns terraform module version'         | :success
        :public  | :guest      | false | :job_token | 'returns terraform module version'         | :success
        :public  | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | true  | :job_token | 'returns terraform module version' | :success
        :private | :guest      | true  | :job_token | 'returns terraform module version' | :success
        :private | :developer  | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | false | :job_token | 'rejects terraform module packages access' | :forbidden
        :private | :guest      | false | :job_token | 'rejects terraform module packages access' | :forbidden
        :private | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
      end

      with_them do
        let(:headers) { user_role == :anonymous ? {} : { 'Authorization' => "Bearer #{token}" } }

        before do
          group.update!(visibility: visibility.to_s)
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end

    it_behaves_like 'accessing a public/internal project with another project\'s job token'
    it_behaves_like 'allowing anyone to pull public terraform modules'
  end

  describe 'GET /api/v4/packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version' do
    let(:url) { api("/packages/terraform/modules/v1/#{group.path}/#{package.name}/#{package.version}") }
    let(:headers) { {} }

    subject(:get_module_version) { get(url, headers: headers) }

    context 'when not found' do
      let(:url) { api("/packages/terraform/modules/v1/#{group.path}/#{package.name}/2.0.0") }
      let(:headers) { { 'Authorization' => "Bearer #{tokens[:job_token]}" } }

      subject { get(url, headers: headers) }

      it 'returns not found when the specified version is not present in the registry' do
        get_module_version

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with valid namespace' do
      where(:visibility, :user_role, :member, :token_type, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | :personal_access_token | 'returns terraform module version'         | :success
        :public  | :guest      | true  | :personal_access_token | 'returns terraform module version'         | :success
        :public  | :developer  | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | false | :personal_access_token | 'returns terraform module version'         | :success
        :public  | :guest      | false | :personal_access_token | 'returns terraform module version'         | :success
        :public  | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :anonymous  | false | nil | 'returns terraform module version' | :success
        :private | :developer  | true  | :personal_access_token | 'returns terraform module version' | :success
        :private | :guest      | true  | :personal_access_token | 'returns terraform module version' | :success
        :private | :developer  | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | false | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :private | :guest      | false | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :private | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :anonymous  | false | nil | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | true  | :job_token | 'returns terraform module version'         | :success
        :public  | :guest      | true  | :job_token | 'returns terraform module version'         | :success
        :public  | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | false | :job_token | 'returns terraform module version'         | :success
        :public  | :guest      | false | :job_token | 'returns terraform module version'         | :success
        :public  | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | true  | :job_token | 'returns terraform module version' | :success
        :private | :guest      | true  | :job_token | 'returns terraform module version' | :success
        :private | :developer  | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | false | :job_token | 'rejects terraform module packages access' | :forbidden
        :private | :guest      | false | :job_token | 'rejects terraform module packages access' | :forbidden
        :private | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
      end

      with_them do
        let(:headers) { user_role == :anonymous ? {} : { 'Authorization' => "Bearer #{token}" } }

        before do
          group.update!(visibility: visibility.to_s)
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end

    it_behaves_like 'accessing a public/internal project with another project\'s job token'
    it_behaves_like 'allowing anyone to pull public terraform modules'
  end

  describe 'GET /api/v4/packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/download' do
    let(:url) { api("/packages/terraform/modules/v1/#{group.path}/#{package.name}/#{package.version}/download") }
    let(:headers) { {} }

    subject { get(url, headers: headers) }

    context 'with valid namespace' do
      where(:visibility, :user_role, :member, :token_type, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | :personal_access_token | 'grants terraform module download'         | :success
        :public  | :guest      | true  | :personal_access_token | 'grants terraform module download'         | :success
        :public  | :developer  | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | false | :personal_access_token | 'grants terraform module download'         | :success
        :public  | :guest      | false | :personal_access_token | 'grants terraform module download'         | :success
        :public  | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :anonymous  | false | nil | 'grants terraform module download' | :success
        :private | :developer  | true  | :personal_access_token | 'grants terraform module download' | :success
        :private | :guest      | true  | :personal_access_token | 'grants terraform module download' | :success
        :private | :developer  | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | false | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :private | :guest      | false | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :private | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :anonymous  | false | nil | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | true  | :job_token | 'grants terraform module download'         | :success
        :public  | :guest      | true  | :job_token | 'grants terraform module download'         | :success
        :public  | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | false | :job_token | 'grants terraform module download'         | :success
        :public  | :guest      | false | :job_token | 'grants terraform module download'         | :success
        :public  | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | true  | :job_token | 'grants terraform module download' | :success
        :private | :guest      | true  | :job_token | 'grants terraform module download' | :success
        :private | :developer  | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | false | :job_token | 'rejects terraform module packages access' | :forbidden
        :private | :guest      | false | :job_token | 'rejects terraform module packages access' | :forbidden
        :private | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
      end

      with_them do
        let(:headers) { user_role == :anonymous ? {} : { 'Authorization' => "Bearer #{token}" } }

        before do
          group.update!(visibility: visibility.to_s)
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end

    it_behaves_like 'accessing a public/internal project with another project\'s job token'
    it_behaves_like 'allowing anyone to pull public terraform modules'
  end

  describe 'GET /api/v4/packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/file' do
    let(:url) do
      api("/packages/terraform/modules/v1/#{group.path}/#{package.name}/#{package.version}/file?token=#{token}")
    end

    let(:tokens) do
      {
        personal_access_token: ::Gitlab::JWTToken.new.tap { |jwt| jwt['token'] = personal_access_token.id }.encoded,
        job_token: ::Gitlab::JWTToken.new.tap { |jwt| jwt['token'] = job.token }.encoded,
        invalid: 'invalid-token123'
      }
    end

    subject(:get_file) { get(url, headers: headers) }

    context 'with valid namespace' do
      where(:visibility, :user_role, :member, :token_type, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | :personal_access_token | 'grants terraform module package file access' | :success
        :public  | :guest      | true  | :personal_access_token | 'grants terraform module package file access' | :success
        :public  | :developer  | true  | :invalid | 'rejects terraform module packages access'    | :unauthorized
        :public  | :guest      | true  | :invalid | 'rejects terraform module packages access'    | :unauthorized
        :public  | :developer  | false | :personal_access_token | 'grants terraform module package file access'    | :success
        :public  | :guest      | false | :personal_access_token | 'grants terraform module package file access'    | :success
        :public  | :developer  | false | :invalid | 'rejects terraform module packages access'    | :unauthorized
        :public  | :guest      | false | :invalid | 'rejects terraform module packages access'    | :unauthorized
        :public  | :anonymous  | false | nil | 'grants terraform module package file access' | :success
        :private | :developer  | true  | :personal_access_token | 'grants terraform module package file access' | :success
        :private | :guest      | true  | :personal_access_token | 'grants terraform module package file access' | :success
        :private | :developer  | true  | :invalid | 'rejects terraform module packages access'    | :unauthorized
        :private | :guest      | true  | :invalid | 'rejects terraform module packages access'    | :unauthorized
        :private | :developer  | false | :personal_access_token | 'rejects terraform module packages access'    | :forbidden
        :private | :guest      | false | :personal_access_token | 'rejects terraform module packages access'    | :forbidden
        :private | :developer  | false | :invalid | 'rejects terraform module packages access'    | :unauthorized
        :private | :guest      | false | :invalid | 'rejects terraform module packages access'    | :unauthorized
        :private | :anonymous  | false | nil | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | true  | :job_token            | 'grants terraform module package file access' | :success
        :public  | :guest      | true  | :job_token            | 'grants terraform module package file access' | :success
        :public  | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | false | :job_token            | 'grants terraform module package file access'    | :success
        :public  | :guest      | false | :job_token            | 'grants terraform module package file access'    | :success
        :public  | :developer  | false | :invalid | 'rejects terraform module packages access'    | :unauthorized
        :public  | :guest      | false | :invalid | 'rejects terraform module packages access'    | :unauthorized
        :private | :developer  | true  | :job_token            | 'grants terraform module package file access' | :success
        :private | :guest      | true  | :job_token            | 'grants terraform module package file access' | :success
        :private | :developer  | true  | :invalid | 'rejects terraform module packages access'    | :unauthorized
        :private | :guest      | true  | :invalid | 'rejects terraform module packages access'    | :unauthorized
        :private | :developer  | false | :job_token            | 'rejects terraform module packages access'    | :forbidden
        :private | :guest      | false | :job_token            | 'rejects terraform module packages access'    | :forbidden
        :private | :developer  | false | :invalid | 'rejects terraform module packages access'    | :unauthorized
        :private | :guest      | false | :invalid | 'rejects terraform module packages access'    | :unauthorized
      end

      with_them do
        let(:snowplow_gitlab_standard_context) do
          context = {
            project: project,
            namespace: project.namespace,
            property: 'i_package_terraform_module_user'
          }

          context[:user] = user if user_role != :anonymous

          context
        end

        before do
          group.update!(visibility: visibility.to_s)
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end

    context 'with package file pending destruction' do
      let_it_be(:package) do
        create(:terraform_module_package, project: project, name: 'module-555/pending-destruction', version: '1.0.0')
      end

      let_it_be(:package_file_pending_destruction) do
        create(:package_file, :pending_destruction, :xml, package: package)
      end

      let_it_be(:package_file) { create(:package_file, :terraform_module, package: package) }

      let(:token) { tokens[:personal_access_token] }
      let(:headers) { { 'Authorization' => "Bearer #{token}" } }

      before do
        project.add_maintainer(user)
      end

      it 'does not return them' do
        get_file

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).not_to eq(package_file_pending_destruction.file.file.read)
        expect(response.body).to eq(package_file.file.file.read)
      end
    end

    it_behaves_like 'accessing a public/internal project with another project\'s job token', :success do
      let(:token) { tokens[:job_token] }
    end

    it_behaves_like 'allowing anyone to pull public terraform modules' do
      let(:token) { nil }
    end
  end
end
