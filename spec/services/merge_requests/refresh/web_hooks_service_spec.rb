# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Refresh::WebHooksService, feature_category: :code_review_workflow do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:fork) { fork_project(project, nil, repository: true) }

  let(:service) { described_class.new(project: project, current_user: user) }
  let(:oldrev) { 'old_sha_123' }
  let(:newrev) { 'new_sha_456' }
  let(:ref) { 'refs/heads/master' }

  describe '#execute' do
    let_it_be(:merge_request) do
      create(
        :merge_request,
        source_project: project,
        source_branch: 'master',
        target_branch: 'feature',
        target_project: project
      )
    end

    let_it_be(:another_merge_request) do
      create(
        :merge_request,
        source_project: project,
        source_branch: 'master',
        target_branch: 'develop',
        target_project: project
      )
    end

    let_it_be(:fork_merge_request) do
      create(
        :merge_request,
        source_project: fork,
        source_branch: 'master',
        target_branch: 'feature',
        target_project: project
      )
    end

    it 'creates a push object with correct parameters' do
      expect(Gitlab::Git::Push).to receive(:new).with(project, oldrev, newrev, ref).and_call_original

      service.execute(oldrev, newrev, ref)
    end

    it 'executes hooks for all merge requests with update action and old_rev' do
      expect(service).to receive(:execute_hooks).with(merge_request, 'update', old_rev: oldrev)
      expect(service).to receive(:execute_hooks).with(another_merge_request, 'update', old_rev: oldrev)

      service.execute(oldrev, newrev, ref)
    end

    context 'when there are no merge requests for the source branch' do
      before do
        allow(service).to receive(:merge_requests_for_source_branch).and_return([])
      end

      it 'does not execute any hooks' do
        expect(service).not_to receive(:execute_hooks)
        expect(project).not_to receive(:execute_hooks)

        service.execute(oldrev, newrev, ref)
      end
    end

    context 'with fork merge requests' do
      let(:fork_service) { described_class.new(project: fork, current_user: user) }

      it 'executes hooks for fork merge requests' do
        expect(fork_service).to receive(:execute_hooks).with(fork_merge_request, 'update', old_rev: oldrev)

        fork_service.execute(oldrev, newrev, ref)
      end
    end

    context 'with closed merge requests' do
      let_it_be(:closed_merge_request) do
        create(
          :merge_request,
          :closed,
          source_project: project,
          source_branch: 'master',
          target_branch: 'closed-target',
          target_project: project
        )
      end

      it 'executes hooks for closed merge requests' do
        expect(service).not_to receive(:execute_hooks).with(closed_merge_request, 'update', old_rev: oldrev)

        service.execute(oldrev, newrev, ref)
      end
    end
  end
end
