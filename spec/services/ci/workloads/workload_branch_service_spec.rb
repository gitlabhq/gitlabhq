# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Workloads::WorkloadBranchService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let(:user) { create(:user, developer_of: project) }
  let(:source_branch) { 'feature-branch' }

  describe '#execute' do
    subject(:execute) do
      described_class.new(project: project, source_branch: source_branch, current_user: user).execute
    end

    before do
      allow(SecureRandom).to receive(:hex).and_return('abcdef12345')
    end

    context 'when user does not have access to push code to the project' do
      let(:user) { create(:user) }

      it 'returns an error response' do
        result = execute
        expect(result).to be_error
        expect(result.message).to eq('You are not allowed to create branches in this project')
      end
    end

    context 'when source branch exists' do
      before do
        project.repository.create_branch(source_branch, project.default_branch)
      end

      it 'creates a new workload branch from the source branch' do
        expected_branch_name = 'workloads/abcdef12345'

        expect(project.repository).to receive(:add_branch)
                                        .with(user, expected_branch_name, source_branch, skip_ci: true)
                                        .and_return(double)

        result = execute

        expect(result).to be_success
        expect(result.payload[:branch_name]).to eq(expected_branch_name)
      end
    end

    context 'when source branch does not exist' do
      let(:source_branch) { 'non-existent-branch' }

      it 'creates a new workload branch from the default branch' do
        expected_branch_name = 'workloads/abcdef12345'

        expect(project.repository).to receive(:add_branch)
                                        .with(user, expected_branch_name, project.default_branch_or_main, skip_ci: true)
                                        .and_return(double)

        result = execute

        expect(result).to be_success
        expect(result.payload[:branch_name]).to eq(expected_branch_name)
      end
    end

    context 'when source branch is nil' do
      let(:source_branch) { nil }

      it 'creates a new workload branch from the default branch' do
        expected_branch_name = 'workloads/abcdef12345'

        expect(project.repository).to receive(:add_branch)
                                        .with(user, expected_branch_name, project.default_branch_or_main, skip_ci: true)
                                        .and_return(double)

        result = execute

        expect(result).to be_success
        expect(result.payload[:branch_name]).to eq(expected_branch_name)
      end
    end

    context 'when git branch creation fails' do
      before do
        allow(project.repository).to receive(:add_branch).and_return(nil)
      end

      it 'returns an error response' do
        result = execute

        expect(result).to be_error
        expect(result.message).to eq('Error in git branch creation')
      end
    end

    context 'when branch name already exists' do
      before do
        allow(project.repository).to receive(:branch_exists?)
                                       .with(match(%r{^workloads/\w+}))
                                       .and_return(true)
      end

      it 'returns an error response' do
        result = execute

        expect(result).to be_error
        expect(result.message).to eq('Branch already exists')
      end
    end

    context 'when git command raises an error' do
      before do
        allow(project.repository).to receive(:add_branch)
                                       .and_raise(Gitlab::Git::CommandError.new('git error'))
      end

      it 'tracks the exception and returns an error response' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
                                           .with(instance_of(Gitlab::Git::CommandError))

        result = execute

        expect(result).to be_error
        expect(result.message).to eq('Failed to create branch')
      end
    end
  end
end
