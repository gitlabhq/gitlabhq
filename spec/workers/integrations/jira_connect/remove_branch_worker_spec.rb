# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::JiraConnect::RemoveBranchWorker, feature_category: :integrations do
  include AfterNextHelpers

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed

  describe '#perform' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :repository, group: group) }
    let_it_be(:subscription) do
      create(:jira_connect_subscription, installation: create(:jira_connect_installation), namespace: group)
    end

    let(:project_id) { project.id }
    let(:branch_name) { 'master' }
    let(:commit_shas) { %w[b83d6e3 5a62481] }
    let(:update_sequence_id) { 1 }
    let(:params) do
      {
        branch_name: branch_name
      }
    end

    def perform
      described_class.new.perform(project_id, params)
    end

    def expect_jira_sync_service_execute(args)
      expect_next(JiraConnect::SyncService).to receive(:execute).with(args)
    end

    it 'calls JiraConnect::SyncService#execute' do
      expect_jira_sync_service_execute(
        remove_branch_info: branch_name
      )

      perform
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
