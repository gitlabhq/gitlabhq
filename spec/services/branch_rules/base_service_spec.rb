# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BranchRules::BaseService, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:protected_branch) { create(:protected_branch) }

  describe '#execute' do
    subject(:execute) { described_class.new(branch_rule, user).execute(skip_authorization: skip_authorization) }

    let(:branch_rule) { Projects::BranchRule.new(project, protected_branch) }

    shared_examples 'missing_method_error' do |method_name|
      it 'raises a missing method error' do
        expect { execute }.to raise_error(
          described_class::MISSING_METHOD_ERROR,
          "Please define an `#{method_name}` method in #{described_class.name}"
        )
      end
    end

    context 'with skip_authorization: false' do
      let(:skip_authorization) { false }

      it_behaves_like 'missing_method_error', 'authorized?'
    end

    context 'with skip_authorization: true' do
      let(:skip_authorization) { true }

      context 'when branch_rule is an instance of Projects::BranchRule' do
        it_behaves_like 'missing_method_error', 'execute_on_branch_rule'
      end

      context 'when branch_rule is not an instance of Projects::BranchRule' do
        let(:branch_rule) { Project.new }

        it 'returns an unknown branch rule type error' do
          expect(execute.message).to eq('Unknown branch rule type.')
        end
      end

      context 'when branch_rule is nil' do
        let(:branch_rule) { nil }

        it 'returns an unknown branch rule type error' do
          expect(execute.message).to eq('Unknown branch rule type.')
        end
      end
    end
  end
end
