# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroying a package', feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  let_it_be_with_reload(:package) { create(:generic_package) }
  let_it_be(:user) { create(:user) }

  let(:project) { package.project }
  let(:id) { package.to_global_id.to_s }

  let(:query) do
    <<~GQL
      errors
    GQL
  end

  let(:params) { { id: id } }
  let(:mutation) { graphql_mutation(:destroy_package, params, query) }
  let(:mutation_response) { graphql_mutation_response(:destroyPackage) }

  shared_examples 'destroying the package' do
    it 'marks the package as pending destruction' do
      expect(::Packages::MarkPackageForDestructionService)
        # rubocop:disable Cop/AvoidBecomes -- MarkPackageForDestructionService should work with all package types, hence Packages::Package
        .to receive(:new).with(container: package.becomes(::Packages::Package), current_user: user).and_call_original
      # rubocop:enable Cop/AvoidBecomes
      expect_next_found_instance_of(::Packages::Package) do |package|
        expect(package).to receive(:mark_package_files_for_destruction)
      end

      expect { mutation_request }
        .to change { ::Packages::Package.pending_destruction.count }.by(1)
    end

    context 'when npm package' do
      let_it_be_with_reload(:package) { create(:npm_package) }

      it 'enqueues the worker to sync a metadata cache' do
        expect(Packages::Npm::CreateMetadataCacheWorker)
          .to receive(:perform_async).with(project.id, package.name)

        mutation_request
      end
    end

    it_behaves_like 'returning response status', :success
  end

  shared_examples 'denying the mutation request' do
    it 'does not mark the package as pending destruction' do
      expect(::Packages::MarkPackageForDestructionService)
          .not_to receive(:new).with(container: package, current_user: user)

      expect { mutation_request }
        .to not_change { ::Packages::Package.pending_destruction.count }

      expect(mutation_response).to be_nil
    end

    it_behaves_like 'returning response status', :success
  end

  describe 'post graphql mutation' do
    subject(:mutation_request) { post_graphql_mutation(mutation, current_user: user) }

    context 'with valid id' do
      where(:user_role, :shared_examples_name) do
        :maintainer | 'destroying the package'
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

    context 'with invalid id' do
      let(:params) { { id: 'gid://gitlab/Packages::Package/5555' } }

      it_behaves_like 'denying the mutation request'
    end

    context 'when an error occures' do
      before do
        project.add_maintainer(user)
      end

      it 'returns the errors in the response' do
        allow_next_found_instance_of(::Packages::Package) do |package|
          allow(package).to receive(:pending_destruction!).and_raise(StandardError)
        end

        mutation_request

        expect(mutation_response['errors']).to match_array(['Failed to mark the package as pending destruction'])
      end
    end
  end
end
