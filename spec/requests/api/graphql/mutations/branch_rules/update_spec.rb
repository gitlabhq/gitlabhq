# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'BranchRuleUpdate', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:protected_branch) do
    create(:protected_branch, project: project)
  end

  let!(:allow_force_push) { !protected_branch.allow_force_push }

  let(:current_user) { user }
  let(:branch_rule) { Projects::BranchRule.new(project, protected_branch) }
  let(:global_id) { branch_rule.to_global_id }
  let(:name) { 'new_name' }
  let(:merge_access_levels) { [{ access_level: 0 }] }
  let(:push_access_levels) { [{ access_level: 0 }] }
  let(:mutation) { graphql_mutation(:branch_rule_update, params) }
  let(:mutation_response) { graphql_mutation_response(:branch_rule_update) }
  let(:params) do
    {
      id: global_id,
      name: name,
      branch_protection: {
        allow_force_push: allow_force_push,
        merge_access_levels: merge_access_levels,
        push_access_levels: push_access_levels
      }
    }
  end

  subject(:post_mutation) { post_graphql_mutation(mutation, current_user: user) }

  context 'when the user does not have permission' do
    before_all do
      project.add_developer(user)
    end

    it_behaves_like 'a mutation that returns top-level errors', errors: [<<~ERROR.chomp]
      The resource that you are attempting to access does not exist or you don't have permission to perform this action
    ERROR

    it 'does not update the branch rule' do
      expect { post_mutation }.not_to change { protected_branch.reload.attributes }
    end
  end

  context 'when the user can update a branch rules' do
    before_all do
      project.add_maintainer(user)
    end

    it 'updates the branch rule' do
      post_mutation

      expect(protected_branch.reload.name).to eq(name)
      expect(protected_branch.allow_force_push).to eq(allow_force_push)

      merge_access_level = an_object_having_attributes(**merge_access_levels.first)
      expect(protected_branch.merge_access_levels).to contain_exactly(merge_access_level)

      push_access_level = an_object_having_attributes(**push_access_levels.first)
      expect(protected_branch.push_access_levels).to contain_exactly(push_access_level)
    end

    it 'returns the updated branch rule' do
      post_mutation

      expect(mutation_response).to have_key('branchRule')
      expect(mutation_response['branchRule']['name']).to eq(name)
      expect(mutation_response['errors']).to be_empty
    end

    context 'when name already exists for the project' do
      before do
        create(:protected_branch, project: project, name: name)
      end

      it 'returns an error' do
        post_mutation

        expect(mutation_response['errors'].first).to eq('Name has already been taken')
      end
    end

    context 'when an invalid global id is given' do
      let(:global_id) { project.to_gid.to_s }
      let(:error_message) { %("#{global_id}" does not represent an instance of Projects::BranchRule) }
      let(:global_id_error) { a_hash_including('message' => a_string_including(error_message)) }

      it 'returns an error' do
        post_mutation

        expect(graphql_errors).to include(global_id_error)
      end
    end

    context 'when a branch rule is missing' do
      let(:protected_branch) { build(:protected_branch, id: non_existing_record_id) }

      it_behaves_like 'a mutation that returns top-level errors',
        errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    end
  end
end
