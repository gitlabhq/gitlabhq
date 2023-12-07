# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'BranchRuleUpdate', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let!(:branch_rule_1) { create(:protected_branch, project: project, name: name_1) }
  let!(:branch_rule_2) { create(:protected_branch, project: project, name: name_2) }
  let(:name_1) { "name_1" }
  let(:name_2) { "name_2" }
  let(:new_name) { "new name" }
  let(:id) { branch_rule_1.to_global_id }
  let(:project_path) { project.full_path }
  let(:name) { new_name }
  let(:params) do
    {
      id: id,
      project_path: project_path,
      name: name
    }
  end

  let(:mutation) { graphql_mutation(:branch_rule_update, params) }

  subject(:post_mutation) { post_graphql_mutation(mutation, current_user: user) }

  def mutation_response
    graphql_mutation_response(:branch_rule_update)
  end

  context 'when the user does not have permission' do
    before_all do
      project.add_developer(user)
    end

    it 'does not update the branch rule' do
      expect { post_mutation }.not_to change { branch_rule_1 }
    end
  end

  context 'when the user can update a branch rules' do
    let(:current_user) { user }

    before_all do
      project.add_maintainer(user)
    end

    it 'updates the protected branch' do
      post_mutation

      expect(branch_rule_1.reload.name).to eq(new_name)
    end

    it 'returns the updated branch rule' do
      post_mutation

      expect(mutation_response).to have_key('branchRule')
      expect(mutation_response['branchRule']['name']).to eq(new_name)
      expect(mutation_response['errors']).to be_empty
    end

    context 'when name already exists for the project' do
      let(:params) do
        {
          id: id,
          project_path: project_path,
          name: name_2
        }
      end

      it 'returns an error' do
        post_mutation

        expect(mutation_response['errors'].first).to eq('Name has already been taken')
      end
    end

    context 'when the protected branch cannot be found' do
      let(:id) { "gid://gitlab/ProtectedBranch/#{non_existing_record_id}" }

      it_behaves_like 'a mutation that returns top-level errors',
        errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    end

    context 'when the project cannot be found' do
      let(:project_path) { 'not a project path' }

      it_behaves_like 'a mutation that returns top-level errors',
        errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    end
  end
end
