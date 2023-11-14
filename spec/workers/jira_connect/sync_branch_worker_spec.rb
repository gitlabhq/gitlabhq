# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::SyncBranchWorker, feature_category: :integrations do
  include AfterNextHelpers

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed

  describe '#perform' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :repository, group: group) }
    let_it_be(:subscription) { create(:jira_connect_subscription, installation: create(:jira_connect_installation), namespace: group) }

    let(:project_id) { project.id }
    let(:branch_name) { 'master' }
    let(:commit_shas) { %w[b83d6e3 5a62481] }
    let(:update_sequence_id) { 1 }

    def perform
      described_class.new.perform(project_id, branch_name, commit_shas, update_sequence_id)
    end

    def expect_jira_sync_service_execute(args)
      expect_next(JiraConnect::SyncService).to receive(:execute).with(args)
    end

    it 'calls JiraConnect::SyncService#execute' do
      expect_jira_sync_service_execute(
        branches: [instance_of(Gitlab::Git::Branch)],
        commits: project.commits_by(oids: commit_shas),
        update_sequence_id: update_sequence_id
      )

      perform
    end

    context 'without branch name' do
      let(:branch_name) { nil }

      it 'calls JiraConnect::SyncService#execute' do
        expect_jira_sync_service_execute(
          branches: nil,
          commits: project.commits_by(oids: commit_shas),
          update_sequence_id: update_sequence_id
        )

        perform
      end
    end

    context 'without commits' do
      let(:commit_shas) { nil }

      it 'calls JiraConnect::SyncService#execute' do
        expect_jira_sync_service_execute(
          branches: [instance_of(Gitlab::Git::Branch)],
          commits: nil,
          update_sequence_id: update_sequence_id
        )

        perform
      end
    end

    context 'when project no longer exists' do
      let(:project_id) { non_existing_record_id }

      it 'does not call JiraConnect::SyncService' do
        expect(JiraConnect::SyncService).not_to receive(:new)

        perform
      end
    end
  end
end
