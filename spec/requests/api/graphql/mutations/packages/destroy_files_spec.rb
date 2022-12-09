# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroying multiple package files', feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  let_it_be_with_reload(:package) { create(:maven_package) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { package.project }

  let(:ids) { package.package_files.first(2).map { |pf| pf.to_global_id.to_s } }

  let(:query) do
    <<~GQL
      errors
    GQL
  end

  let(:params) do
    {
      project_path: project.full_path,
      ids: ids
    }
  end

  let(:mutation) { graphql_mutation(:destroy_package_files, params, query) }

  describe 'post graphql mutation' do
    subject(:mutation_request) { post_graphql_mutation(mutation, current_user: user) }

    shared_examples 'destroying the package files' do
      it 'marks the package file as pending destruction' do
        expect { mutation_request }.to change { ::Packages::PackageFile.pending_destruction.count }.by(2)
      end

      it_behaves_like 'returning response status', :success
    end

    shared_examples 'denying the mutation request' do |response = "you don't have permission to perform this action"|
      it 'does not mark the package file as pending destruction' do
        expect { mutation_request }.not_to change { ::Packages::PackageFile.pending_destruction.count }

        expect_graphql_errors_to_include(response)
      end

      it_behaves_like 'returning response status', :success
    end

    context 'with valid params' do
      where(:user_role, :shared_examples_name) do
        :maintainer | 'destroying the package files'
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

      context 'with more than 100 files' do
        let(:ids) { package.package_files.map { |pf| pf.to_global_id.to_s } }

        before do
          project.add_maintainer(user)
          create_list(:package_file, 99, package: package)
        end

        it_behaves_like 'denying the mutation request', 'Cannot delete more than 100 files'
      end

      context 'with files outside of the project' do
        let_it_be(:package2) { create(:maven_package) }

        let(:ids) { super().push(package2.package_files.first.to_global_id.to_s) }

        before do
          project.add_maintainer(user)
        end

        it_behaves_like 'denying the mutation request', 'All files must be in the requested project'
      end
    end

    context 'with invalid params' do
      let(:params) { { id: 'foo' } }

      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'denying the mutation request', 'invalid value for id'
    end
  end
end
