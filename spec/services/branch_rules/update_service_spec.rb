# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BranchRules::UpdateService, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:protected_branch, reload: true) { create(:protected_branch) }

  describe '#execute' do
    let(:branch_rule) { Projects::BranchRule.new(project, protected_branch) }
    let(:ability_allowed) { true }
    let(:new_name) { 'new_name' }
    let(:params) { { name: new_name } }
    let(:skip_authorization) { false }

    subject(:execute) do
      described_class.new(branch_rule, user, params).execute(skip_authorization: skip_authorization)
    end

    before do
      allow(Ability).to receive(:allowed?).and_return(true)
      allow(Ability).to receive(:allowed?)
        .with(user, :update_branch_rule, branch_rule)
        .and_return(ability_allowed)
    end

    context 'when the current_user cannot update the branch rule' do
      let(:ability_allowed) { false }

      it 'raises an access denied error' do
        expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end

      context 'and skip_authorization is true' do
        let(:skip_authorization) { true }

        it 'raises an access denied error' do
          expect { execute }.not_to raise_error
        end
      end
    end

    context 'when branch_rule is a Projects::BranchRule' do
      let(:update_service) { ProtectedBranches::UpdateService }
      let(:update_service_instance) { instance_double(update_service) }

      it 'updates the ProtectedBranch and returns a success response' do
        expect(execute).to be_success
        expect(protected_branch.reload.name).to eq(new_name)
      end

      context 'if the update fails' do
        let(:errors) { ["Error 1", "Error 2"] }

        before do
          allow(update_service).to receive(:new).and_return(update_service_instance)
          allow(update_service_instance).to receive(:execute).and_return(protected_branch)
          allow(protected_branch).to receive_message_chain(:errors, :any?).and_return(errors)
          allow(protected_branch).to receive_message_chain(:errors, :full_messages).and_return(errors)
        end

        it 'returns an error' do
          expect(response = execute).to be_error
          expect(response[:message]).to eq(errors)
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

    context 'when branch_rule is a ProtectedBranch' do
      let(:branch_rule) { protected_branch }

      it 'returns an error' do
        expect(response = execute).to be_error
        expect(response[:message]).to eq('Unknown branch rule type.')
      end
    end
  end
end
