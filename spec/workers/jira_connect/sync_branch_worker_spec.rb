# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::SyncBranchWorker do
  describe '#perform' do
    let_it_be(:project) { create(:project, :repository) }
    let(:project_id) { project.id }
    let(:branch_name) { 'master' }
    let(:commit_shas) { %w(b83d6e3 5a62481) }

    subject { described_class.new.perform(project_id, branch_name, commit_shas) }

    def expect_jira_sync_service_execute(args)
      expect_next_instance_of(JiraConnect::SyncService) do |instance|
        expect(instance).to receive(:execute).with(args)
      end
    end

    it 'calls JiraConnect::SyncService#execute' do
      expect_jira_sync_service_execute(
        branches: [instance_of(Gitlab::Git::Branch)],
        commits: project.commits_by(oids: commit_shas)
      )

      subject
    end

    context 'without branch name' do
      let(:branch_name) { nil }

      it 'calls JiraConnect::SyncService#execute' do
        expect_jira_sync_service_execute(
          branches: nil,
          commits: project.commits_by(oids: commit_shas)
        )

        subject
      end
    end

    context 'without commits' do
      let(:commit_shas) { nil }

      it 'calls JiraConnect::SyncService#execute' do
        expect_jira_sync_service_execute(
          branches: [instance_of(Gitlab::Git::Branch)],
          commits: nil
        )

        subject
      end
    end

    context 'when project no longer exists' do
      let(:project_id) { non_existing_record_id }

      it 'does not call JiraConnect::SyncService' do
        expect(JiraConnect::SyncService).not_to receive(:new)

        subject
      end
    end
  end
end
