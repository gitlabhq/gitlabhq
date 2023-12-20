# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'BranchRuleCreate', feature_category: :source_code_management do
  include GraphqlHelpers
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:current_user, reload: true) { create(:user) }

  let(:params) do
    {
      project_path: project.full_path,
      name: branch_name
    }
  end

  let(:branch_name) { 'branch_name/*' }
  let(:mutation) { graphql_mutation(:branch_rule_create, params) }
  let(:mutation_response) { graphql_mutation_response(:branch_rule_create) }
  let(:mutation_errors) { mutation_response['errors'] }

  subject(:post_mutation) { post_graphql_mutation(mutation, current_user: current_user) }

  context 'when the user does not have permission' do
    before_all do
      project.add_developer(current_user)
    end

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not create the board' do
      expect { post_mutation }.not_to change { ProtectedBranch.count }
    end
  end

  context 'when the user can create a branch rules' do
    before_all do
      project.add_maintainer(current_user)
    end

    it 'creates the protected branch' do
      expect { post_mutation }.to change { ProtectedBranch.count }.by(1)
    end

    it 'returns the created branch rule' do
      post_mutation

      expect(mutation_response).to have_key('branchRule')
      expect(mutation_response['branchRule']['name']).to eq(branch_name)
      expect(mutation_errors).to be_empty
    end

    context 'when the branch rule already exist' do
      let!(:existing_rule) { create :protected_branch, name: branch_name, project: project }

      it 'does not create the protected branch' do
        expect { post_mutation }.not_to change { ProtectedBranch.count }
      end

      it 'return an error message' do
        post_mutation

        expect(mutation_errors).to include 'Name has already been taken'
        expect(mutation_response['branchRule']).to be_nil
      end
    end
  end
end
