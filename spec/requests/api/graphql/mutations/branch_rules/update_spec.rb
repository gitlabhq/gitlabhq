# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'BranchRuleUpdate', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let!(:protected_branch_1) { create(:protected_branch, project: project, name: name_1) }
  let!(:protected_branch_2) { create(:protected_branch, project: project, name: name_2) }
  let(:branch_rule) { Projects::BranchRule.new(project, protected_branch_1) }
  let(:name_1) { "name_1" }
  let(:name_2) { "name_2" }
  let(:new_name) { "new name" }
  let(:global_id) { branch_rule.to_global_id }
  let(:name) { new_name }
  let(:params) do
    {
      id: global_id,
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
      post_mutation

      expect(protected_branch_1.reload.name).to eq(name_1)
    end
  end

  context 'when the user can update a branch rules' do
    let(:current_user) { user }

    before_all do
      project.add_maintainer(user)
    end

    it 'updates the branch rule' do
      post_mutation

      expect(protected_branch_1.reload.name).to eq(new_name)
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
          id: global_id,
          name: name_2
        }
      end

      it 'returns an error' do
        post_mutation

        expect(mutation_response['errors'].first).to eq('Name has already been taken')
      end
    end

    context 'when branch rule cannot be found' do
      let(:global_id) { project.to_gid.to_s }
      let(:error_message) { %("#{global_id}" does not represent an instance of Projects::BranchRule) }
      let(:global_id_error) { a_hash_including('message' => a_string_including(error_message)) }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(global_id_error)
      end
    end
  end
end
