# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueRebalancingWorker do
  describe '#perform' do
    let_it_be(:issue) { create(:issue) }

    it 'runs an instance of IssueRebalancingService' do
      service = double(execute: nil)
      expect(IssueRebalancingService).to receive(:new).with(issue).and_return(service)

      described_class.new.perform(issue.id)
    end

    it 'anticipates the inability to find the issue' do
      expect(Gitlab::ErrorTracking).to receive(:log_exception).with(ActiveRecord::RecordNotFound, include(issue_id: -1))
      expect(IssueRebalancingService).not_to receive(:new)

      described_class.new.perform(-1)
    end

    it 'anticipates there being too many issues' do
      service = double
      allow(service).to receive(:execute) { raise IssueRebalancingService::TooManyIssues }
      expect(IssueRebalancingService).to receive(:new).with(issue).and_return(service)
      expect(Gitlab::ErrorTracking).to receive(:log_exception).with(IssueRebalancingService::TooManyIssues, include(issue_id: issue.id))

      described_class.new.perform(issue.id)
    end
  end
end
