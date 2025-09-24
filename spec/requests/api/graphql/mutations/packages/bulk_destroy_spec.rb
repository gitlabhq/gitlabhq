# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroying multiple packages', feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:packages1) { create_list(:generic_package, 3, project: project1) }
  let_it_be_with_reload(:packages2) { create_list(:generic_package, 2, project: project2) }

  let(:ids) { packages1.append(packages2).flatten.map(&:to_global_id).map(&:to_s) }

  let(:query) do
    <<~GQL
      errors
    GQL
  end

  let(:params) do
    {
      ids: ids
    }
  end

  let(:mutation) { graphql_mutation(:destroy_packages, params, query) }

  describe 'post graphql mutation' do
    subject(:mutation_request) { post_graphql_mutation(mutation, current_user: user) }

    shared_examples 'destroying the packages' do
      it 'marks the packages as pending destruction' do
        expect { mutation_request }.to change { ::Packages::Package.pending_destruction.count }.by(5)
      end

      it_behaves_like 'returning response status', :success

      context 'when npm package' do
        let_it_be_with_reload(:packages1) { create_list(:npm_package, 3, project: project1, name: 'test-package-1') }
        let_it_be_with_reload(:packages2) { create_list(:npm_package, 2, project: project2, name: 'test-package-2') }

        it 'enqueues the worker to sync a metadata cache' do
          arguments = []

          expect(Packages::Npm::CreateMetadataCacheWorker)
            .to receive(:bulk_perform_async_with_contexts).and_wrap_original do |original_method, *args|
            packages = args.first
            arguments = packages.map(&args.second[:arguments_proc]).uniq
            original_method.call(*args)
          end

          mutation_request

          expect(arguments).to contain_exactly([project1.id, 'test-package-1'], [project2.id, 'test-package-2'])
        end
      end
    end

    shared_examples 'denying the mutation request' do
      |response = ::Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR|
      it 'does not mark the packages as pending destruction' do
        expect { mutation_request }.not_to change { ::Packages::Package.pending_destruction.count }
        expect_graphql_errors_to_include(response)
      end

      it_behaves_like 'returning response status', :success
    end

    shared_examples 'mixed protected package deletion' do
      it_behaves_like 'returning response status', :success

      it 'returns protection errors for protected packages' do
        mutation_request

        response_errors = graphql_mutation_response(:destroyPackages)['errors']
        expect(response_errors).to include("Package '#{protected_package1.name}' is deletion protected.")
        expect(response_errors).to include("Package '#{protected_package2.name}' is deletion protected.")
      end

      it 'marks only unprotected packages for destruction' do
        expect { mutation_request }.to change { ::Packages::Package.pending_destruction.count }.by(3)

        # Protected packages should not be marked for destruction
        expect(protected_package1.reload.status).to eq('default')
        expect(protected_package2.reload.status).to eq('default')
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(packages_protected_packages_delete: false)
        end

        it_behaves_like 'destroying the packages'
      end
    end

    context 'with valid params' do
      where(:user_role, :shared_examples_name) do
        :maintainer      | 'destroying the packages'
        :developer       | 'denying the mutation request'
        :not_in_project  | 'denying the mutation request'
      end

      with_them do
        before do
          unless user_role == :not_in_project
            project1.send("add_#{user_role}", user)
            project2.send("add_#{user_role}", user)
          end
        end

        it_behaves_like params[:shared_examples_name]
      end

      context 'for over the limit' do
        before do
          project1.add_maintainer(user)
          project2.add_maintainer(user)
          stub_const("Mutations::Packages::BulkDestroy::MAX_PACKAGES", 2)
        end

        it_behaves_like 'denying the mutation request', ::Mutations::Packages::BulkDestroy::TOO_MANY_IDS_ERROR
      end

      context 'with packages outside of the project' do
        before do
          project1.add_maintainer(user)
        end

        it_behaves_like 'denying the mutation request'
      end
    end

    context 'with protected packages' do
      let_it_be_with_reload(:protected_package1) { packages1.first }
      let_it_be_with_reload(:protected_package2) { packages2.first }
      let_it_be_with_reload(:package_protection_rule1) do
        create(:package_protection_rule,
          project: project1,
          package_name_pattern: protected_package1.name,
          package_type: protected_package1.package_type,
          minimum_access_level_for_delete: :owner
        )
      end

      let_it_be_with_reload(:package_protection_rule2) do
        create(:package_protection_rule,
          project: project2,
          package_name_pattern: protected_package2.name,
          package_type: protected_package2.package_type,
          minimum_access_level_for_delete: :owner
        )
      end

      where(:user_role, :shared_examples_name) do
        :owner      | 'destroying the packages'
        :maintainer | 'mixed protected package deletion'
        :developer  | 'denying the mutation request'
      end

      with_them do
        before do
          project1.send("add_#{user_role}", user)
          project2.send("add_#{user_role}", user)
        end

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'with invalid params' do
      let(:ids) { 'foo' }

      it_behaves_like 'denying the mutation request', 'invalid value for id'
    end

    context 'with multi mutations' do
      let(:package1) { packages1.first }
      let(:package2) { packages2.first }
      let(:query) do
        <<~QUERY
        mutation {
          a: destroyPackages(input: { ids: ["#{package1.to_global_id}"]}) {
            errors
          }
          b: destroyPackages(input: { ids: ["#{package2.to_global_id}"]}) {
            errors
          }
        }
        QUERY
      end

      subject(:mutation_request) { post_graphql(query, current_user: user) }

      before do
        project1.add_maintainer(user)
        project2.add_maintainer(user)
      end

      it 'executes the first mutation but not the second one' do
        expect { mutation_request }.to change { package1.reload.status }.from('default').to('pending_destruction')
                                         .and not_change { package2.reload.status }
        expect_graphql_errors_to_include('"destroyPackages" field can be requested only for 1 Mutation(s) at a time.')
      end
    end
  end
end
