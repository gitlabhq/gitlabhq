# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BranchRules::SquashOption, feature_category: :source_code_management do
  it_behaves_like 'projects squash option'

  describe 'Associations' do
    it { is_expected.to belong_to(:protected_branch).optional(false) }
    it { is_expected.to belong_to(:project).optional(false) }
  end

  describe 'Validations' do
    let_it_be(:project) { create(:project) }
    let(:protected_branch) { build(:protected_branch, name: 'master', project: project) }

    context 'for protected_branch' do
      subject do
        described_class
          .new(protected_branch: protected_branch, project: project)
          .tap(&:valid?)
          .errors.messages_for(:protected_branch)
      end

      it { is_expected.to be_empty }

      context 'when protected_branch is nil' do
        let(:protected_branch) { nil }

        it { is_expected.to contain_exactly('must exist') }
      end

      context 'when protected_branch is wildcard' do
        let(:protected_branch) { build(:protected_branch, name: '*', project: project) }

        it { is_expected.to contain_exactly('cannot be a wildcard') }
      end

      context 'when protected_branch belongs to a different project' do
        let(:protected_branch) { build(:protected_branch, name: 'master') }

        it { is_expected.to contain_exactly('must belong to project') }
      end
    end
  end
end
