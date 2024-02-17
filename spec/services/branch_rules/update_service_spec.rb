# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BranchRules::UpdateService, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:protected_branch) { create(:protected_branch) }

  describe '#execute' do
    let(:branch_rule) { Projects::BranchRule.new(project, protected_branch) }
    let(:action_allowed) { true }
    let(:update_service) { ProtectedBranches::UpdateService }
    let(:update_service_instance) { instance_double(update_service) }
    let(:new_name) { 'new_name' }
    let(:errors) { ["Error 1", "Error 2"] }
    let(:params) { { name: new_name } }

    subject(:execute) { described_class.new(branch_rule, user, params).execute }

    before do
      allow(Ability).to receive(:allowed?).and_return(true)
      allow(Ability)
        .to receive(:allowed?).with(user, :update_protected_branch, branch_rule)
                              .and_return(action_allowed)
    end

    context 'when the current_user cannot update the branch rule' do
      let(:action_allowed) { false }

      it 'raises an access denied error' do
        expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    context 'when branch_rule is a Projects::BranchRule' do
      it 'updates the ProtectedBranch and returns a success execute' do
        expect(execute[:status]).to eq(:success)
        expect(protected_branch.reload.name).to eq(new_name)
      end

      context 'if the update fails' do
        before do
          allow(update_service).to receive(:new).and_return(update_service_instance)
          allow(update_service_instance).to receive(:execute).and_return(protected_branch)
          allow(protected_branch).to receive_message_chain(:errors, :any?).and_return(errors)
          allow(protected_branch).to receive_message_chain(:errors, :full_messages).and_return(errors)
        end

        it 'returns an error' do
          response = execute
          expect(response[:message]).to eq(errors)
          expect(response[:status]).to eq(:error)
        end
      end
    end

    context 'when branch_rule is a ProtectedBranch' do
      let(:branch_rule) { protected_branch }

      it 'returns an error' do
        response = execute
        expect(response[:message]).to eq('Unknown branch rule type.')
        expect(response[:status]).to eq(:error)
      end
    end

    context 'when unpermitted params are provided' do
      let(:params) { { name: new_name, not_permitted: 'not_permitted' } }

      it 'removes them' do
        expect(update_service).to receive(:new).with(project, user, { name: new_name }).and_call_original
        execute
      end
    end
  end
end
