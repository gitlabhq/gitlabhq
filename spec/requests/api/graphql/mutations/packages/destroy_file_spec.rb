# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroying a package file' do
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
    it 'destroy the package file' do
      expect { mutation_request }.to change { ::Packages::PackageFile.count }.by(-1)
    end

    it_behaves_like 'returning response status', :success
  end

  shared_examples 'denying the mutation request' do
    it 'does not destroy the package file' do
      expect(::Packages::PackageFile)
          .not_to receive(:destroy)

      expect { mutation_request }.not_to change { ::Packages::PackageFile.count }

      expect(mutation_response).to be_nil
    end

    it_behaves_like 'returning response status', :success
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
    end

    context 'with invalid id' do
      let(:params) { { id: 'gid://gitlab/Packages::PackageFile/5555' } }

      it_behaves_like 'denying the mutation request'
    end

    context 'when an error occures' do
      let(:error_messages) { ['some error'] }

      before do
        project.add_maintainer(user)
      end

      it 'returns the errors in the response' do
        allow_next_found_instance_of(::Packages::PackageFile) do |package_file|
          allow(package_file).to receive(:destroy).and_return(false)
          allow(package_file).to receive_message_chain(:errors, :full_messages).and_return(error_messages)
        end

        mutation_request

        expect(mutation_response['errors']).to eq(error_messages)
      end
    end
  end
end
