# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::SyncMergeRequestWorker do
  describe '#perform' do
    let(:merge_request) { create(:merge_request) }
    let(:merge_request_id) { merge_request.id }

    subject { described_class.new.perform(merge_request_id) }

    it 'calls JiraConnect::SyncService#execute' do
      expect_next_instance_of(JiraConnect::SyncService) do |service|
        expect(service).to receive(:execute).with(merge_requests: [merge_request])
      end

      subject
    end

    context 'when MR no longer exists' do
      let(:merge_request_id) { non_existing_record_id }

      it 'does not call JiraConnect::SyncService' do
        expect(JiraConnect::SyncService).not_to receive(:new)

        subject
      end
    end
  end
end
