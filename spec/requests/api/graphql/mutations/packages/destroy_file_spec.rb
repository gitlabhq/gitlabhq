# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroying a package file', feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  let_it_be_with_reload(:package) { create(:maven_package) }
  let_it_be(:user) { create(:user) }

  let(:project) { package.project }
  let(:id) { package.package_files.first.to_global_id.to_s }

  let(:query) do
    <<~GQL
      errors
    GQL
  end

  let(:params) { { id: id } }
  let(:mutation) { graphql_mutation(:destroy_package_file, params, query) }
  let(:mutation_response) { graphql_mutation_response(:destroyPackageFile) }

  shared_examples 'destroying the package file' do
    it 'marks the package file as pending destruction' do
      expect { mutation_request }.to change { ::Packages::PackageFile.pending_destruction.count }.by(1)
    end

    it_behaves_like 'returning response status', :success
  end

  shared_examples 'denying the mutation request' do
    it 'does not mark the package file as pending destruction' do
      expect { mutation_request }.not_to change { ::Packages::PackageFile.pending_destruction.count }

      expect(mutation_response).to be_nil
    end

    it_behaves_like 'returning response status', :success

    it 'does not sync helm metadata cache' do
      expect(::Packages::Helm::CreateMetadataCacheWorker).not_to receive(:perform_async)

      mutation_request
    end
  end

  shared_examples 'protected deletion of package file' do
    it_behaves_like 'returning response status', :success

    it 'returns protection error' do
      mutation_request

      expect(mutation_response).to include('errors' => ['Package is deletion protected.'])
    end

    it 'does not mark package file for destruction' do
      expect { mutation_request }.not_to change { ::Packages::PackageFile.pending_destruction.count }
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(packages_protected_packages_delete: false)
      end

      it_behaves_like 'destroying the package file'
    end
  end

  describe 'post graphql mutation' do
    subject(:mutation_request) { post_graphql_mutation(mutation, current_user: user) }

    context 'with valid id' do
      where(:user_role, :shared_examples_name) do
        :maintainer | 'destroying the package file'
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

      context 'when package file is helm package type' do
        let_it_be(:helm_package) { create(:helm_package, project: package.project) }

        let(:package_file) { helm_package.package_files.first }
        let(:id) { package_file.to_global_id.to_s }

        before do
          project.add_maintainer(user)
        end

        it 'enqueue worker to sync helm metadata cache' do
          expect(::Packages::Helm::BulkSyncHelmMetadataCacheService)
            .to receive(:new)
            .with(user, ::Packages::PackageFile.id_in(package_file.id))
            .and_call_original

          mutation_request
        end
      end
    end

    context 'with protected package file' do
      let_it_be_with_reload(:package_protection_rule) do
        create(:package_protection_rule,
          project: package.project,
          package_name_pattern: package.name,
          package_type: package.package_type,
          minimum_access_level_for_delete: :owner
        )
      end

      where(:user_role, :shared_examples_name) do
        :owner      | 'destroying the package file'
        :maintainer | 'protected deletion of package file'
        :developer  | 'denying the mutation request'
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
      let(:params) { { id: 'gid://gitlab/Packages::PackageFile/5555' } }

      it_behaves_like 'denying the mutation request'
    end

    context 'when an error occurs' do
      let(:error_messages) { ['some error'] }

      before do
        project.add_maintainer(user)
      end

      it 'returns the errors in the response' do
        allow_next_found_instance_of(::Packages::PackageFile) do |package_file|
          allow(package_file).to receive(:pending_destruction!)
          allow(package_file).to receive_message_chain(:errors, :full_messages).and_return(error_messages)
        end

        mutation_request

        expect(mutation_response['errors']).to eq(error_messages)
      end
    end
  end
end
