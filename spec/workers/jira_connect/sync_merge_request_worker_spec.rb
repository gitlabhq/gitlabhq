# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::SyncMergeRequestWorker do
  include AfterNextHelpers

  it_behaves_like 'worker with data consistency',
                  described_class,
                  data_consistency: :delayed

  describe '#perform' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :repository, group: group) }
    let_it_be(:subscription) { create(:jira_connect_subscription, installation: create(:jira_connect_installation), namespace: group) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }

    let(:merge_request_id) { merge_request.id }
    let(:update_sequence_id) { 1 }

    def perform
      described_class.new.perform(merge_request_id, update_sequence_id)
    end

    it 'calls JiraConnect::SyncService#execute' do
      expect_next(JiraConnect::SyncService).to receive(:execute)
        .with(merge_requests: [merge_request], update_sequence_id: update_sequence_id)

      perform
    end

    context 'when MR no longer exists' do
      let(:merge_request_id) { non_existing_record_id }

      it 'does not call JiraConnect::SyncService' do
        expect(JiraConnect::SyncService).not_to receive(:new)

        perform
      end
    end
  end
end
