# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deleting a BranchRule', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:protected_branch) { create(:protected_branch) }
  let_it_be(:project) { protected_branch.project }

  let(:branch_rule) { Projects::BranchRule.new(project, protected_branch) }
  let(:global_id) { branch_rule.to_global_id.to_s }
  let(:mutation) { graphql_mutation(:branch_rule_delete, { id: global_id }) }
  let(:mutation_response) { graphql_mutation_response(:branch_rule_delete) }

  subject(:mutation_request) { post_graphql_mutation(mutation, current_user: current_user) }

  context 'when the user does not have permission' do
    it_behaves_like 'a mutation that returns top-level errors',
      errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]

    it 'does not destroy the BranchRule' do
      expect { mutation_request }.not_to change { ProtectedBranch.count }
    end
  end

  context 'when the user has permission' do
    before_all do
      project.add_maintainer(current_user)
    end

    it 'destroys the BranchRule' do
      expect { mutation_request }.to change { ProtectedBranch.count }.by(-1)
    end

    it 'returns an empty BranchRule' do
      mutation_request

      expect(mutation_response).to have_key('branchRule')
      expect(mutation_response['branchRule']).to be_nil
    end

    context 'when an invalid global id is given' do
      let(:global_id) { project.to_gid.to_s }
      let(:error_message) { %("#{global_id}" does not represent an instance of Projects::BranchRule) }
      let(:global_id_error) { a_hash_including('message' => a_string_including(error_message)) }

      it 'returns an error' do
        mutation_request

        expect(graphql_errors).to include(global_id_error)
      end

      it 'does not destroy the BranchRule' do
        expect { mutation_request }.not_to change { ProtectedBranch.count }
      end
    end

    context 'when a branch rule is missing' do
      let(:protected_branch) { build(:protected_branch, id: non_existing_record_id) }

      it_behaves_like 'a mutation that returns top-level errors',
        errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]

      it 'does not destroy the BranchRule' do
        expect { mutation_request }.not_to change { ProtectedBranch.count }
      end
    end
  end
end
