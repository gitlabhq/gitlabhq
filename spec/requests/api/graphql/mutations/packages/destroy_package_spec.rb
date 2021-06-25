# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroying a package' do
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  let_it_be_with_reload(:package) { create(:package) }
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
    it 'destroy the package' do
      expect(::Packages::DestroyPackageService)
          .to receive(:new).with(container: package, current_user: user).and_call_original

      expect { mutation_request }.to change { ::Packages::Package.count }.by(-1)
    end

    it_behaves_like 'returning response status', :success
  end

  shared_examples 'denying the mutation request' do
    it 'does not destroy the package' do
      expect(::Packages::DestroyPackageService)
          .not_to receive(:new).with(container: package, current_user: user)

      expect { mutation_request }.not_to change { ::Packages::Package.count }

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
          allow(package).to receive(:destroy!).and_raise(StandardError)
        end

        mutation_request

        expect(mutation_response['errors']).to eq(['Failed to remove the package'])
      end
    end
  end
end
