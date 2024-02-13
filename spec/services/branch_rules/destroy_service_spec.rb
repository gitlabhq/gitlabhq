# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BranchRules::DestroyService, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:protected_branch) { create(:protected_branch) }

  describe '#execute' do
    let(:branch_rule) { Projects::BranchRule.new(project, protected_branch) }
    let(:action_allowed) { true }
    let(:destroy_service) { ProtectedBranches::DestroyService }
    let(:destroy_service_instance) { instance_double(destroy_service) }

    subject(:execute) { described_class.new(branch_rule, user).execute }

    before do
      # We need to stub the call inside the nested services first
      allow(Ability).to receive(:allowed?).and_return(true)
      allow(Ability)
        .to receive(:allowed?).with(user, :destroy_protected_branch, branch_rule)
        .and_return(action_allowed)
    end

    context 'when the current_user cannot destroy the branch rule' do
      let(:action_allowed) { false }

      it 'raises an access denied error' do
        expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    context 'when branch_rule is a Projects::BranchRule' do
      it 'deletes the ProtectedBranch and returns a success execute' do
        expect(execute[:status]).to eq(:success)
        expect(protected_branch).to be_destroyed
      end

      context 'if the deletion fails' do
        before do
          allow(destroy_service).to receive(:new).and_return(destroy_service_instance)
          allow(destroy_service_instance).to receive(:execute).and_return(false)
        end

        it 'returns an error execute' do
          response = execute
          expect(response[:message]).to eq('Failed to delete branch rule.')
          expect(response[:status]).to eq(:error)
        end
      end
    end

    context 'when branch_rule is a ProtectedBranch' do
      let(:branch_rule) { protected_branch }

      it 'returns error' do
        response = execute
        expect(response[:message]).to eq('Unknown branch rule type.')
        expect(response[:status]).to eq(:error)
      end
    end
  end
end
