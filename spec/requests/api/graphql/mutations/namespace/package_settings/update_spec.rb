# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating the package settings', feature_category: :package_registry do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }

  let(:params) do
    {
      namespace_path: namespace.full_path,
      maven_duplicates_allowed: false,
      maven_duplicate_exception_regex: 'foo-.*',
      generic_duplicates_allowed: false,
      generic_duplicate_exception_regex: 'bar-.*',
      nuget_duplicates_allowed: false,
      nuget_duplicate_exception_regex: 'bar-.*',
      maven_package_requests_forwarding: true,
      lock_maven_package_requests_forwarding: true,
      npm_package_requests_forwarding: true,
      lock_npm_package_requests_forwarding: true,
      pypi_package_requests_forwarding: true,
      lock_pypi_package_requests_forwarding: true,
      nuget_symbol_server_enabled: true,
      terraform_module_duplicates_allowed: true,
      terraform_module_duplicate_exception_regex: 'foo-.*'
    }
  end

  let(:mutation) do
    graphql_mutation(:update_namespace_package_settings, params) do
      <<~QL
        packageSettings {
          mavenDuplicatesAllowed
          mavenDuplicateExceptionRegex
          genericDuplicatesAllowed
          genericDuplicateExceptionRegex
          nugetDuplicatesAllowed
          nugetDuplicateExceptionRegex
          mavenPackageRequestsForwarding
          lockMavenPackageRequestsForwarding
          npmPackageRequestsForwarding
          lockNpmPackageRequestsForwarding
          pypiPackageRequestsForwarding
          lockPypiPackageRequestsForwarding
          nugetSymbolServerEnabled
          terraformModuleDuplicatesAllowed
          terraformModuleDuplicateExceptionRegex
        }
        errors
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:update_namespace_package_settings) }
  let(:package_settings_response) { mutation_response['packageSettings'] }

  RSpec.shared_examples 'returning a success' do
    it_behaves_like 'returning response status', :success

    it 'returns the updated package settings', :aggregate_failures do
      subject

      expect(mutation_response['errors']).to be_empty
      expect(package_settings_response['mavenDuplicatesAllowed']).to eq(params[:maven_duplicates_allowed])
      expect(package_settings_response['mavenDuplicateExceptionRegex']).to eq(params[:maven_duplicate_exception_regex])
      expect(package_settings_response['genericDuplicatesAllowed']).to eq(params[:generic_duplicates_allowed])
      expect(package_settings_response['genericDuplicateExceptionRegex']).to eq(params[:generic_duplicate_exception_regex])
      expect(package_settings_response['nugetDuplicatesAllowed']).to eq(params[:nuget_duplicates_allowed])
      expect(package_settings_response['nugetDuplicateExceptionRegex']).to eq(params[:nuget_duplicate_exception_regex])
      expect(package_settings_response['mavenPackageRequestsForwarding']).to eq(params[:maven_package_requests_forwarding])
      expect(package_settings_response['lockMavenPackageRequestsForwarding']).to eq(params[:lock_maven_package_requests_forwarding])
      expect(package_settings_response['pypiPackageRequestsForwarding']).to eq(params[:pypi_package_requests_forwarding])
      expect(package_settings_response['lockPypiPackageRequestsForwarding']).to eq(params[:lock_pypi_package_requests_forwarding])
      expect(package_settings_response['npmPackageRequestsForwarding']).to eq(params[:npm_package_requests_forwarding])
      expect(package_settings_response['lockNpmPackageRequestsForwarding']).to eq(params[:lock_npm_package_requests_forwarding])
      expect(package_settings_response['nugetSymbolServerEnabled']).to eq(params[:nuget_symbol_server_enabled])
      expect(package_settings_response['terraformModuleDuplicatesAllowed']).to eq(params[:terraform_module_duplicates_allowed])
      expect(package_settings_response['terraformModuleDuplicateExceptionRegex']).to eq(params[:terraform_module_duplicate_exception_regex])
    end
  end

  RSpec.shared_examples 'rejecting invalid regex' do
    context "for field mavenDuplicateExceptionRegex" do
      let_it_be(:invalid_regex) { '][' }

      let(:params) do
        {
          :namespace_path => namespace.full_path,
          'mavenDuplicateExceptionRegex' => invalid_regex
        }
      end

      it_behaves_like 'returning response status', :success

      it_behaves_like 'not creating the namespace package setting'

      it 'returns an error', :aggregate_failures do
        subject

        expect(graphql_errors.size).to eq(1)
        expect(graphql_errors.first['message']).to include("#{invalid_regex} is an invalid regexp")
      end
    end
  end

  RSpec.shared_examples 'accepting the mutation request updating the package settings' do
    it_behaves_like 'updating the namespace package setting attributes',
      from: {
        maven_duplicates_allowed: true,
        maven_duplicate_exception_regex: 'SNAPSHOT',
        generic_duplicates_allowed: true,
        generic_duplicate_exception_regex: 'foo',
        nuget_duplicates_allowed: true,
        nuget_duplicate_exception_regex: 'foo',
        maven_package_requests_forwarding: nil,
        lock_maven_package_requests_forwarding: false,
        npm_package_requests_forwarding: nil,
        lock_npm_package_requests_forwarding: false,
        pypi_package_requests_forwarding: nil,
        lock_pypi_package_requests_forwarding: false,
        nuget_symbol_server_enabled: false,
        terraform_module_duplicates_allowed: false,
        terraform_module_duplicate_exception_regex: 'foo'
      }, to: {
        maven_duplicates_allowed: false,
        maven_duplicate_exception_regex: 'foo-.*',
        generic_duplicates_allowed: false,
        generic_duplicate_exception_regex: 'bar-.*',
        nuget_duplicates_allowed: false,
        nuget_duplicate_exception_regex: 'bar-.*',
        maven_package_requests_forwarding: true,
        lock_maven_package_requests_forwarding: true,
        npm_package_requests_forwarding: true,
        lock_npm_package_requests_forwarding: true,
        pypi_package_requests_forwarding: true,
        lock_pypi_package_requests_forwarding: true,
        nuget_symbol_server_enabled: true,
        terraform_module_duplicates_allowed: true,
        terraform_module_duplicate_exception_regex: 'foo-.*'
      }

    it_behaves_like 'returning a success'
    it_behaves_like 'rejecting invalid regex'
  end

  RSpec.shared_examples 'accepting the mutation request creating the package settings' do
    it_behaves_like 'creating the namespace package setting'
    it_behaves_like 'returning a success'
    it_behaves_like 'rejecting invalid regex'
  end

  RSpec.shared_examples 'denying the mutation request' do
    it_behaves_like 'not creating the namespace package setting'

    it_behaves_like 'returning response status', :success

    it 'returns no response' do
      subject

      expect(mutation_response).to be_nil
    end
  end

  describe 'post graphql mutation' do
    subject { post_graphql_mutation(mutation, current_user: user) }

    context 'with existing package settings' do
      let_it_be(:package_settings, reload: true) { create(:namespace_package_setting, :group) }
      let_it_be(:namespace, reload: true) { package_settings.namespace }

      where(:user_role, :shared_examples_name) do
        :owner      | 'accepting the mutation request updating the package settings'
        :maintainer | 'denying the mutation request'
        :developer  | 'denying the mutation request'
        :reporter   | 'denying the mutation request'
        :guest      | 'denying the mutation request'
        :anonymous  | 'denying the mutation request'
      end

      with_them do
        before do
          namespace.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'without existing package settings' do
      let_it_be(:namespace, reload: true) { create(:group) }

      let(:package_settings) { namespace.package_settings }

      where(:user_role, :shared_examples_name) do
        :owner      | 'accepting the mutation request creating the package settings'
        :maintainer | 'denying the mutation request'
        :developer  | 'denying the mutation request'
        :reporter   | 'denying the mutation request'
        :guest      | 'denying the mutation request'
        :anonymous  | 'denying the mutation request'
      end

      with_them do
        before do
          namespace.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end
  end
end
