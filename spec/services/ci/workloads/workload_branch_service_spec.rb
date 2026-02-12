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

    context 'when source branch exists' do
      before do
        project.repository.create_branch(source_branch, project.default_branch)
      end

      it 'creates a new workload ref from the source branch' do
        workload_ref = 'refs/workloads/abcdef12345'
        source_sha = project.repository.commit(source_branch).sha

        expect(project.repository).to receive(:create_ref)
                                        .with(source_sha, workload_ref)
                                        .and_return(true)

        result = execute

        expect(result).to be_success
        expect(result.payload[:ref]).to eq(workload_ref)
      end
    end

    context 'when source branch does not exist' do
      let(:source_branch) { 'non-existent-branch' }

      it 'creates a new workload ref from the default branch' do
        workload_ref = 'refs/workloads/abcdef12345'
        default_sha = project.repository.commit(project.default_branch_or_main).sha

        expect(project.repository).to receive(:create_ref)
                                        .with(default_sha, workload_ref)
                                        .and_return(true)

        result = execute

        expect(result).to be_success
        expect(result.payload[:ref]).to eq(workload_ref)
      end
    end

    context 'when source branch is nil' do
      let(:source_branch) { nil }

      it 'creates a new workload ref from the default branch' do
        workload_ref = 'refs/workloads/abcdef12345'
        default_sha = project.repository.commit(project.default_branch_or_main).sha

        expect(project.repository).to receive(:create_ref)
                                        .with(default_sha, workload_ref)
                                        .and_return(true)

        result = execute

        expect(result).to be_success
        expect(result.payload[:ref]).to eq(workload_ref)
      end
    end

    context 'when git ref creation fails' do
      before do
        allow(project.repository).to receive(:create_ref).and_return(nil)
      end

      it 'returns an error response' do
        result = execute

        expect(result).to be_error
        expect(result.message).to eq('Error in git ref creation')
      end
    end

    context 'when ref already exists' do
      before do
        allow(project.repository).to receive(:ref_exists?)
                                      .with(match(%r{^refs/workloads/\w+}))
                                      .and_return(true)
      end

      it 'returns an error response' do
        result = execute

        expect(result).to be_error
        expect(result.message).to eq('Ref already exists')
      end
    end

    context 'when source ref is not found' do
      before do
        allow(project.repository).to receive(:commit).and_return(nil)
      end

      it 'returns an error response' do
        result = execute

        expect(result).to be_error
        expect(result.message).to eq('Source ref not found')
      end
    end

    context 'when git command raises an error' do
      before do
        allow(project.repository).to receive(:create_ref)
                                      .and_raise(Gitlab::Git::CommandError.new('git error'))
      end

      it 'tracks the exception and returns an error response' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
                                          .with(instance_of(Gitlab::Git::CommandError))

        result = execute

        expect(result).to be_error
        expect(result.message).to eq('Failed to create workload ref')
      end
    end
  end
end
