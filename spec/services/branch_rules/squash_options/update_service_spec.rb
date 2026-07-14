# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BranchRules::SquashOptions::UpdateService, feature_category: :source_code_management do
  describe '#execute' do
    let_it_be_with_reload(:project) { create(:project) }
    let_it_be(:maintainer) { create(:user, maintainer_of: project) }
    let_it_be(:developer) { create(:user, developer_of: project) }
    let(:squash_option) { ::Projects::BranchRules::SquashOption.squash_options['always'] }
    let(:branch_rule) { ::Projects::AllBranchesRule.new(project) }
    let(:current_user) { maintainer }

    subject(:execute) do
      described_class.new(branch_rule, user: current_user, params: { squash_option: squash_option }).execute
    end

    context 'when branch rule is an AllBranchesRule' do
      it 'updates the project level squash option' do
        expect { execute }
          .to change { project.reload&.project_setting&.squash_option }.from('default_off').to('always')
      end

      it 'returns the updated squash option in the payload', :aggregate_failures do
        result = execute
        expect(result).to be_success
        expect(result.payload).to eq(project.reload.project_setting)
      end
    end

    context 'when the user is not authorized' do
      let(:current_user) { developer }

      it 'returns an error response', :aggregate_failures do
        expect(execute).to be_error
        expect(execute.message).to eq('Failed to update squash option')
        expect(execute.payload[:errors]).to contain_exactly('Not allowed')
        expect(execute.reason).to eq(:access_denied)
      end
    end

    context 'when branch rule is a BranchRule', unless: Gitlab.ee? do
      let_it_be(:protected_branch) { create(:protected_branch, project: project) }
      let(:branch_rule) { ::Projects::BranchRule.new(project, protected_branch) }

      it 'returns an error response', :aggregate_failures do
        expect(execute).to be_error
        expect(execute.message).to eq('Updating BranchRule not supported')
      end
    end

    context 'when branch rule is an unknown type' do
      let(:branch_rule) { create(:protected_branch, project: project) }

      before do
        allow(Ability).to receive(:allowed?)
          .with(current_user, :update_squash_option, branch_rule)
          .and_return(true)
      end

      it 'returns an error response' do
        expect(execute).to be_error
        expect(execute.message).to eq('Unknown branch rule type.')
      end
    end
  end
end
