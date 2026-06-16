# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BranchRules::BaseService, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:protected_branch) { create(:protected_branch) }

  describe '#execute' do
    subject(:execute) { described_class.new(branch_rule, user: user).execute(skip_authorization: skip_authorization) }

    let(:branch_rule) { Projects::BranchRule.new(project, protected_branch) }

    shared_examples 'missing_method_error' do |method_name|
      it 'raises a missing method error' do
        expect { execute }.to raise_error(
          described_class::MISSING_METHOD_ERROR,
          "Please define an `#{method_name}` method in #{described_class.name}"
        )
      end
    end

    context 'when not authorized' do
      let(:skip_authorization) { false }

      before do
        allow_next_instance_of(described_class) do |service|
          allow(service).to receive_messages(authorized?: false, action: 'update', object_name: 'branch rule')
        end
      end

      it 'returns an access denied error response', :aggregate_failures do
        expect(execute).to be_error
        expect(execute.reason).to eq(:access_denied)
        expect(execute.message).to eq('Failed to update branch rule')
        expect(execute.payload[:errors]).to contain_exactly('Not allowed')
      end
    end

    context 'when a record is not found' do
      let(:skip_authorization) { true }
      let(:exception) { ActiveRecord::RecordNotFound.new('Record not found') }

      before do
        allow_next_instance_of(described_class) do |service|
          allow(service).to receive(:execute_on_branch_rule_type).and_raise(exception)
        end
      end

      it 'returns a not found error response', :aggregate_failures do
        expect(execute).to be_error
        expect(execute.reason).to eq(:not_found)
        expect(execute.message).to eq('Record not found')
        expect(execute.payload[:errors]).to contain_exactly('Not found')
      end
    end

    context 'when an access denied error is raised during execution' do
      let(:skip_authorization) { true }

      before do
        allow_next_instance_of(described_class) do |service|
          allow(service).to receive_messages(action: 'delete', object_name: 'branch rule')
          allow(service).to receive(:execute_on_branch_rule_type).and_raise(Gitlab::Access::AccessDeniedError)
        end
      end

      it 'returns an access denied error response', :aggregate_failures do
        expect(execute).to be_error
        expect(execute.reason).to eq(:access_denied)
        expect(execute.message).to eq('Failed to delete branch rule')
        expect(execute.payload[:errors]).to contain_exactly('Not allowed')
      end
    end

    context 'when authorized? is not defined' do
      let(:skip_authorization) { false }

      it_behaves_like 'missing_method_error', 'authorized?'
    end

    context 'when authorized' do
      let(:skip_authorization) { false }

      before do
        allow_next_instance_of(described_class) do |service|
          allow(service).to receive(:authorized?).and_return(true)
        end
      end

      context 'when branch_rule is an instance of Projects::BranchRule' do
        it_behaves_like 'missing_method_error', 'execute_on_branch_rule'
      end

      context 'when branch_rule is an instance of Projects::AllBranchesRule' do
        let(:branch_rule) { Projects::AllBranchesRule.new(project) }

        it_behaves_like 'missing_method_error', 'execute_on_all_branches_rule'
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
