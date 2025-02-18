# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Projects::BranchRules::SquashOptions::UpdateService, feature_category: :source_code_management do
  describe '#execute' do
    let_it_be_with_reload(:project) { create(:project) }
    let_it_be(:maintainer) { create(:user, maintainer_of: project) }
    let_it_be(:developer) { create(:user, developer_of: project) }
    let(:squash_option) { ::Projects::BranchRules::SquashOption.squash_options['always'] }
    let(:branch_rule) { ::Projects::AllBranchesRule.new(project) }

    subject(:execute) do
      described_class.new(branch_rule, squash_option: squash_option, current_user: current_user).execute
    end

    context 'when branch rule is an AllBranchesRule' do
      let(:current_user) { maintainer }

      it 'updates the project level squash option' do
        expect { execute }
          .to change { project.reload&.project_setting&.squash_option }.from('default_off').to('always')
      end
    end

    context 'when the user is not authorized' do
      let(:current_user) { developer }

      it 'returns an error response' do
        result = execute

        expect(result.message).to eq(described_class::AUTHORIZATION_ERROR_MESSAGE)
        expect(result).to be_error
      end
    end

    context 'when branch rule is BranchRule' do
      let_it_be(:protected_branch) { create :protected_branch, project: project }
      let(:branch_rule) { ::Projects::BranchRule.new(project, protected_branch) }
      let(:current_user) { maintainer }

      it 'returns an error response' do
        expect(execute).to be_error
        expect(execute.message).to eq('Updating BranchRule not supported')
      end
    end
  end
end
