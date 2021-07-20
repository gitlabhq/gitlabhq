# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating the package settings' do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }

  let(:params) do
    {
      namespace_path: namespace.full_path,
      maven_duplicates_allowed: false,
      maven_duplicate_exception_regex: 'foo-.*',
      generic_duplicates_allowed: false,
      generic_duplicate_exception_regex: 'bar-.*'
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
      from: { maven_duplicates_allowed: true, maven_duplicate_exception_regex: 'SNAPSHOT', generic_duplicates_allowed: true, generic_duplicate_exception_regex: 'foo' },
      to: { maven_duplicates_allowed: false, maven_duplicate_exception_regex: 'foo-.*', generic_duplicates_allowed: false, generic_duplicate_exception_regex: 'bar-.*' }

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
        :maintainer | 'accepting the mutation request updating the package settings'
        :developer  | 'accepting the mutation request updating the package settings'
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
        :maintainer | 'accepting the mutation request creating the package settings'
        :developer  | 'accepting the mutation request creating the package settings'
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
