# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating the packages cleanup policy', feature_category: :package_registry do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:params) do
    {
      project_path: project.full_path,
      keep_n_duplicated_package_files: 'TWENTY_PACKAGE_FILES'
    }
  end

  let(:mutation) do
    graphql_mutation(
      :update_packages_cleanup_policy,
      params,
      <<~QUERY
        packagesCleanupPolicy {
          keepNDuplicatedPackageFiles
          nextRunAt
        }
        errors
      QUERY
    )
  end

  let(:mutation_response) { graphql_mutation_response(:update_packages_cleanup_policy) }
  let(:packages_cleanup_policy_response) { mutation_response['packagesCleanupPolicy'] }

  shared_examples 'accepting the mutation request and updates the existing policy' do
    it 'returns the updated packages cleanup policy' do
      expect { subject }.not_to change { ::Packages::Cleanup::Policy.count }

      expect(project.packages_cleanup_policy.keep_n_duplicated_package_files).to eq('20')
      expect_graphql_errors_to_be_empty
      expect(packages_cleanup_policy_response['keepNDuplicatedPackageFiles'])
        .to eq(params[:keep_n_duplicated_package_files])
      expect(packages_cleanup_policy_response['nextRunAt']).not_to eq(nil)
    end
  end

  shared_examples 'accepting the mutation request and creates a policy' do
    it 'returns the created packages cleanup policy' do
      expect { subject }.to change { ::Packages::Cleanup::Policy.count }.by(1)

      expect(project.packages_cleanup_policy.keep_n_duplicated_package_files).to eq('20')
      expect_graphql_errors_to_be_empty
      expect(packages_cleanup_policy_response['keepNDuplicatedPackageFiles'])
        .to eq(params[:keep_n_duplicated_package_files])
      expect(packages_cleanup_policy_response['nextRunAt']).not_to eq(nil)
    end
  end

  shared_examples 'denying the mutation request' do
    it 'returns an error' do
      expect { subject }.not_to change { ::Packages::Cleanup::Policy.count }

      expect(project.packages_cleanup_policy.keep_n_duplicated_package_files).not_to eq('20')
      expect(mutation_response).to be_nil
      expect_graphql_errors_to_include(/you don't have permission to perform this action/)
    end
  end

  describe 'post graphql mutation' do
    subject { post_graphql_mutation(mutation, current_user: user) }

    context 'with existing packages cleanup policy' do
      let_it_be(:project_packages_cleanup_policy) { create(:packages_cleanup_policy, project: project) }

      where(:user_role, :shared_examples_name) do
        :maintainer | 'accepting the mutation request and updates the existing policy'
        :developer  | 'denying the mutation request'
        :reporter   | 'denying the mutation request'
        :guest      | 'denying the mutation request'
        :anonymous  | 'denying the mutation request'
      end

      with_them do
        before do
          project.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'without existing packages cleanup policy' do
      where(:user_role, :shared_examples_name) do
        :maintainer | 'accepting the mutation request and creates a policy'
        :developer  | 'denying the mutation request'
        :reporter   | 'denying the mutation request'
        :guest      | 'denying the mutation request'
        :anonymous  | 'denying the mutation request'
      end

      with_them do
        before do
          project.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end
  end
end
