# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Terraform::Modules::V1::Packages, feature_category: :package_registry do
  include PackagesManagerApiSpecHelpers
  include WorkhorseHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, namespace: group) }
  let_it_be(:package) { create(:terraform_module_package, project: project) }
  let_it_be(:personal_access_token) { create(:personal_access_token) }
  let_it_be(:user) { personal_access_token.user }
  let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:project_deploy_token) { create(:project_deploy_token, deploy_token: deploy_token, project: project) }

  let(:headers) { {} }
  let(:token) { tokens[token_type] }

  let(:tokens) do
    {
      personal_access_token: personal_access_token.token,
      deploy_token: deploy_token.token,
      job_token: job.token,
      invalid: 'invalid-token123'
    }
  end

  describe 'GET /api/v4/packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/versions' do
    let(:url) { api("/packages/terraform/modules/v1/#{group.path}/#{package.name}/versions") }
    let(:headers) { { 'Authorization' => "Bearer #{tokens[:job_token]}" } }

    subject { get(url, headers: headers) }

    context 'with a conflicting package name' do
      let!(:conflicting_package) { create(:terraform_module_package, project: project, name: "conflict-#{package.name}", version: '2.0.0') }

      before do
        group.add_developer(user)
      end

      it 'returns only one version' do
        subject

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
        :private | :developer  | true  | :personal_access_token | 'returns terraform module packages'        | :success
        :private | :guest      | true  | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :private | :developer  | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | false | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :private | :guest      | false | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :private | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :anonymous  | false | nil | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | true  | :job_token | 'returns terraform module packages'        | :success
        :public  | :guest      | true  | :job_token | 'returns no terraform module packages'     | :success
        :public  | :guest      | true  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | false | :job_token | 'returns no terraform module packages'     | :success
        :public  | :guest      | false | :job_token | 'returns no terraform module packages'     | :success
        :public  | :developer  | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | false | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | true  | :job_token | 'returns terraform module packages'        | :success
        :private | :guest      | true  | :job_token | 'rejects terraform module packages access' | :forbidden
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
  end

  describe 'GET /api/v4/packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/download' do
    context 'empty registry' do
      let(:url) { api("/packages/terraform/modules/v1/#{group.path}/module-2/system/download") }
      let(:headers) { {} }

      subject { get(url, headers: headers) }

      it 'returns not found when there is no module' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with valid namespace' do
      let(:url) { api("/packages/terraform/modules/v1/#{group.path}/#{package.name}/download") }
      let(:headers) { {} }

      subject { get(url, headers: headers) }

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
        :private | :guest      | true  | :personal_access_token | 'rejects terraform module packages access' | :forbidden
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
        :private | :guest      | true  | :job_token | 'rejects terraform module packages access' | :forbidden
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
  end

  describe 'GET /api/v4/packages/terraform/modules/v1/:module_namespace/:module_name/:module_system' do
    context 'empty registry' do
      let(:url) { api("/packages/terraform/modules/v1/#{group.path}/non-existent/system") }
      let(:headers) { { 'Authorization' => "Bearer #{tokens[:personal_access_token]}" } }

      subject { get(url, headers: headers) }

      it 'returns not found when there is no module' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with valid namespace' do
      let(:url) { api("/packages/terraform/modules/v1/#{group.path}/#{package.name}") }

      subject { get(url, headers: headers) }

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
        :private | :developer  | true  | :personal_access_token | 'returns terraform module version'         | :success
        :private | :guest      | true  | :personal_access_token | 'rejects terraform module packages access' | :forbidden
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
        :private | :developer  | true  | :job_token | 'returns terraform module version'         | :success
        :private | :guest      | true  | :job_token | 'rejects terraform module packages access' | :forbidden
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
  end

  describe 'GET /api/v4/packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version' do
    let(:url) { api("/packages/terraform/modules/v1/#{group.path}/#{package.name}/#{package.version}") }
    let(:headers) { {} }

    subject { get(url, headers: headers) }

    context 'not found' do
      let(:url) { api("/packages/terraform/modules/v1/#{group.path}/#{package.name}/2.0.0") }
      let(:headers) { { 'Authorization' => "Bearer #{tokens[:job_token]}" } }

      subject { get(url, headers: headers) }

      it 'returns not found when the specified version is not present in the registry' do
        subject

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
        :private | :developer  | true  | :personal_access_token | 'returns terraform module version'         | :success
        :private | :guest      | true  | :personal_access_token | 'rejects terraform module packages access' | :forbidden
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
        :private | :developer  | true  | :job_token | 'returns terraform module version'         | :success
        :private | :guest      | true  | :job_token | 'rejects terraform module packages access' | :forbidden
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
        :private | :developer  | true  | :personal_access_token | 'grants terraform module download'         | :success
        :private | :guest      | true  | :personal_access_token | 'rejects terraform module packages access' | :forbidden
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
        :private | :developer  | true  | :job_token | 'grants terraform module download'         | :success
        :private | :guest      | true  | :job_token | 'rejects terraform module packages access' | :forbidden
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
  end

  describe 'GET /api/v4/packages/terraform/modules/v1/:module_namespace/:module_name/:module_system/:module_version/file' do
    let(:url) { api("/packages/terraform/modules/v1/#{group.path}/#{package.name}/#{package.version}/file?token=#{token}") }
    let(:tokens) do
      {
        personal_access_token: ::Gitlab::JWTToken.new.tap { |jwt| jwt['token'] = personal_access_token.id }.encoded,
        job_token: ::Gitlab::JWTToken.new.tap { |jwt| jwt['token'] = job.token }.encoded,
        invalid: 'invalid-token123'
      }
    end

    subject { get(url, headers: headers) }

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
        :private | :guest      | true  | :personal_access_token | 'rejects terraform module packages access'    | :forbidden
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
        :private | :guest      | true  | :job_token            | 'rejects terraform module packages access'    | :forbidden
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
      let_it_be(:package) { create(:package, package_type: :terraform_module, project: project, name: "module-555/pending-destruction", version: '1.0.0') }
      let_it_be(:package_file_pending_destruction) { create(:package_file, :pending_destruction, :xml, package: package) }
      let_it_be(:package_file) { create(:package_file, :terraform_module, package: package) }

      let(:token) { tokens[:personal_access_token] }
      let(:headers) { { 'Authorization' => "Bearer #{token}" } }

      before do
        project.add_maintainer(user)
      end

      it 'does not return them' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).not_to eq(package_file_pending_destruction.file.file.read)
        expect(response.body).to eq(package_file.file.file.read)
      end
    end
  end

  describe 'PUT /api/v4/projects/:project_id/packages/terraform/modules/:module_name/:module_system/:module_version/file/authorize' do
    include_context 'workhorse headers'

    let(:url) { api("/projects/#{project.id}/packages/terraform/modules/mymodule/mysystem/1.0.0/file/authorize") }
    let(:headers) { {} }

    subject { put(url, headers: headers) }

    context 'with valid project' do
      where(:visibility, :user_role, :member, :token_header, :token_type, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | 'PRIVATE-TOKEN' | :personal_access_token | 'process terraform module workhorse authorization' | :success
        :public  | :guest      | true  | 'PRIVATE-TOKEN' | :personal_access_token | 'rejects terraform module packages access'         | :forbidden
        :public  | :developer  | true  | 'PRIVATE-TOKEN' | :invalid | 'rejects terraform module packages access'         | :unauthorized
        :public  | :guest      | true  | 'PRIVATE-TOKEN' | :invalid | 'rejects terraform module packages access'         | :unauthorized
        :public  | :developer  | false | 'PRIVATE-TOKEN' | :personal_access_token | 'rejects terraform module packages access'         | :forbidden
        :public  | :guest      | false | 'PRIVATE-TOKEN' | :personal_access_token | 'rejects terraform module packages access'         | :forbidden
        :public  | :developer  | false | 'PRIVATE-TOKEN' | :invalid | 'rejects terraform module packages access'         | :unauthorized
        :public  | :guest      | false | 'PRIVATE-TOKEN' | :invalid | 'rejects terraform module packages access'         | :unauthorized
        :public  | :anonymous  | false | nil | nil | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | true  | 'PRIVATE-TOKEN' | :personal_access_token | 'process terraform module workhorse authorization' | :success
        :private | :guest      | true  | 'PRIVATE-TOKEN' | :personal_access_token | 'rejects terraform module packages access'         | :forbidden
        :private | :developer  | true  | 'PRIVATE-TOKEN' | :invalid | 'rejects terraform module packages access'         | :unauthorized
        :private | :guest      | true  | 'PRIVATE-TOKEN' | :invalid | 'rejects terraform module packages access'         | :unauthorized
        :private | :developer  | false | 'PRIVATE-TOKEN' | :personal_access_token | 'rejects terraform module packages access'         | :not_found
        :private | :guest      | false | 'PRIVATE-TOKEN' | :personal_access_token | 'rejects terraform module packages access'         | :not_found
        :private | :developer  | false | 'PRIVATE-TOKEN' | :invalid | 'rejects terraform module packages access'         | :unauthorized
        :private | :guest      | false | 'PRIVATE-TOKEN' | :invalid | 'rejects terraform module packages access'         | :unauthorized
        :private | :anonymous  | false | nil | nil | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | true  | 'JOB-TOKEN'     | :job_token | 'process terraform module workhorse authorization' | :success
        :public  | :guest      | true  | 'JOB-TOKEN'     | :job_token | 'rejects terraform module packages access'         | :forbidden
        :public  | :developer  | true  | 'JOB-TOKEN'     | :invalid | 'rejects terraform module packages access'         | :unauthorized
        :public  | :guest      | true  | 'JOB-TOKEN'     | :invalid | 'rejects terraform module packages access'         | :unauthorized
        :public  | :developer  | false | 'JOB-TOKEN'     | :job_token | 'rejects terraform module packages access'         | :forbidden
        :public  | :guest      | false | 'JOB-TOKEN'     | :job_token | 'rejects terraform module packages access'         | :forbidden
        :public  | :developer  | false | 'JOB-TOKEN'     | :invalid | 'rejects terraform module packages access'         | :unauthorized
        :public  | :guest      | false | 'JOB-TOKEN'     | :invalid | 'rejects terraform module packages access'         | :unauthorized
        :private | :developer  | true  | 'JOB-TOKEN'     | :job_token | 'process terraform module workhorse authorization' | :success
        :private | :guest      | true  | 'JOB-TOKEN'     | :job_token | 'rejects terraform module packages access'         | :forbidden
        :private | :developer  | true  | 'JOB-TOKEN'     | :invalid | 'rejects terraform module packages access'         | :unauthorized
        :private | :guest      | true  | 'JOB-TOKEN'     | :invalid | 'rejects terraform module packages access'         | :unauthorized
        :private | :developer  | false | 'JOB-TOKEN'     | :job_token | 'rejects terraform module packages access'         | :not_found
        :private | :guest      | false | 'JOB-TOKEN'     | :job_token | 'rejects terraform module packages access'         | :not_found
        :private | :developer  | false | 'JOB-TOKEN'     | :invalid | 'rejects terraform module packages access'         | :unauthorized
        :private | :guest      | false | 'JOB-TOKEN'     | :invalid | 'rejects terraform module packages access'         | :unauthorized
        :public  | :developer  | true  | 'DEPLOY-TOKEN'  | :deploy_token | 'process terraform module workhorse authorization' | :success
        :public  | :developer  | true  | 'DEPLOY-TOKEN'  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | true  | 'DEPLOY-TOKEN'  | :deploy_token | 'process terraform module workhorse authorization' | :success
        :private | :developer  | true  | 'DEPLOY-TOKEN'  | :invalid | 'rejects terraform module packages access' | :unauthorized
      end

      with_them do
        let(:headers) { user_headers.merge(workhorse_headers) }
        let(:user_headers) { user_role == :anonymous ? {} : { token_header => token } }

        before do
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end
    end
  end

  describe 'PUT /api/v4/projects/:project_id/packages/terraform/modules/:module_name/:module_system/:module_version/file' do
    include_context 'workhorse headers'

    let_it_be(:file_name) { 'module-system-v1.0.0.tgz' }

    let(:url) { "/projects/#{project.id}/packages/terraform/modules/mymodule/mysystem/1.0.0/file" }
    let(:headers) { {} }
    let(:params) { { file: temp_file(file_name) } }
    let(:file_key) { :file }
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

    context 'with valid project' do
      where(:visibility, :user_role, :member, :token_header, :token_type, :shared_examples_name, :expected_status) do
        :public  | :developer  | true  | 'PRIVATE-TOKEN' | :personal_access_token | 'process terraform module upload'          | :created
        :public  | :guest      | true  | 'PRIVATE-TOKEN' | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :public  | :developer  | true  | 'PRIVATE-TOKEN' | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | true  | 'PRIVATE-TOKEN' | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | false | 'PRIVATE-TOKEN' | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :public  | :guest      | false | 'PRIVATE-TOKEN' | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :public  | :developer  | false | 'PRIVATE-TOKEN' | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | false | 'PRIVATE-TOKEN' | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :anonymous  | false | nil | nil | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | true  | 'PRIVATE-TOKEN' | :personal_access_token | 'process terraform module upload'          | :created
        :private | :guest      | true  | 'PRIVATE-TOKEN' | :personal_access_token | 'rejects terraform module packages access' | :forbidden
        :private | :developer  | true  | 'PRIVATE-TOKEN' | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | true  | 'PRIVATE-TOKEN' | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | false | 'PRIVATE-TOKEN' | :personal_access_token | 'rejects terraform module packages access' | :not_found
        :private | :guest      | false | 'PRIVATE-TOKEN' | :personal_access_token | 'rejects terraform module packages access' | :not_found
        :private | :developer  | false | 'PRIVATE-TOKEN' | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | false | 'PRIVATE-TOKEN' | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :anonymous  | false | nil | nil | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | true  | 'JOB-TOKEN'     | :job_token | 'process terraform module upload'          | :created
        :public  | :guest      | true  | 'JOB-TOKEN'     | :job_token | 'rejects terraform module packages access' | :forbidden
        :public  | :developer  | true  | 'JOB-TOKEN'     | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | true  | 'JOB-TOKEN'     | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | false | 'JOB-TOKEN'     | :job_token | 'rejects terraform module packages access' | :forbidden
        :public  | :guest      | false | 'JOB-TOKEN'     | :job_token | 'rejects terraform module packages access' | :forbidden
        :public  | :developer  | false | 'JOB-TOKEN'     | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :guest      | false | 'JOB-TOKEN'     | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | true  | 'JOB-TOKEN'     | :job_token | 'process terraform module upload'          | :created
        :private | :guest      | true  | 'JOB-TOKEN'     | :job_token | 'rejects terraform module packages access' | :forbidden
        :private | :developer  | true  | 'JOB-TOKEN'     | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | true  | 'JOB-TOKEN'     | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | false | 'JOB-TOKEN'     | :job_token | 'rejects terraform module packages access' | :not_found
        :private | :guest      | false | 'JOB-TOKEN'     | :job_token | 'rejects terraform module packages access' | :not_found
        :private | :developer  | false | 'JOB-TOKEN'     | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :guest      | false | 'JOB-TOKEN'     | :invalid | 'rejects terraform module packages access' | :unauthorized
        :public  | :developer  | true  | 'DEPLOY-TOKEN'  | :deploy_token | 'process terraform module upload' | :created
        :public  | :developer  | true  | 'DEPLOY-TOKEN'  | :invalid | 'rejects terraform module packages access' | :unauthorized
        :private | :developer  | true  | 'DEPLOY-TOKEN'  | :deploy_token | 'process terraform module upload' | :created
        :private | :developer  | true  | 'DEPLOY-TOKEN'  | :invalid | 'rejects terraform module packages access' | :unauthorized
      end

      with_them do
        let(:user_headers) { user_role == :anonymous ? {} : { token_header => token } }
        let(:headers) { user_headers.merge(workhorse_headers) }
        let(:snowplow_gitlab_standard_context) do
          { project: project, namespace: project.namespace, user: snowplow_user, property: 'i_package_terraform_module_user' }
        end

        let(:snowplow_user) do
          case token_type
          when :deploy_token
            deploy_token
          when :job_token
            job.user
          else
            user
          end
        end

        before do
          project.update!(visibility: visibility.to_s)
        end

        it_behaves_like params[:shared_examples_name], params[:user_role], params[:expected_status], params[:member]
      end

      context 'failed package file save' do
        let(:user_headers) { { 'PRIVATE-TOKEN' => personal_access_token.token } }
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

        context 'with an existing package' do
          let_it_be_with_reload(:existing_package) { create(:terraform_module_package, name: 'mymodule/mysystem', version: '1.0.0', project: project) }

          it 'does not create a new package' do
            expect { subject }
              .to change { project.packages.count }.by(0)
              .and change { Packages::PackageFile.count }.by(0)
            expect(response).to have_gitlab_http_status(:forbidden)
          end

          context 'marked as pending_destruction' do
            it 'does create a new package' do
              existing_package.pending_destruction!

              expect { subject }
                .to change { project.packages.count }.by(1)
                .and change { Packages::PackageFile.count }.by(1)
              expect(response).to have_gitlab_http_status(:created)
            end
          end
        end
      end
    end
  end
end
