# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueRebalancingWorker do
  describe '#perform' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:issue) { create(:issue, project: project) }

    context 'when block_issue_repositioning is enabled' do
      before do
        stub_feature_flags(block_issue_repositioning: group)
      end

      it 'does not run an instance of IssueRebalancingService' do
        expect(IssueRebalancingService).not_to receive(:new)

        described_class.new.perform(nil, issue.project_id)
      end
    end

    it 'runs an instance of IssueRebalancingService' do
      service = double(execute: nil)
      expect(IssueRebalancingService).to receive(:new).with(issue).and_return(service)

      described_class.new.perform(nil, issue.project_id)
    end

    it 'anticipates the inability to find the issue' do
      expect(Gitlab::ErrorTracking).to receive(:log_exception).with(ActiveRecord::RecordNotFound, include(project_id: -1))
      expect(IssueRebalancingService).not_to receive(:new)

      described_class.new.perform(nil, -1)
    end

    it 'anticipates there being too many issues' do
      service = double
      allow(service).to receive(:execute) { raise IssueRebalancingService::TooManyIssues }
      expect(IssueRebalancingService).to receive(:new).with(issue).and_return(service)
      expect(Gitlab::ErrorTracking).to receive(:log_exception).with(IssueRebalancingService::TooManyIssues, include(project_id: issue.project_id))

      described_class.new.perform(nil, issue.project_id)
    end

    it 'takes no action if the value is nil' do
      expect(IssueRebalancingService).not_to receive(:new)
      expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

      described_class.new.perform(nil, nil)
    end
  end
end
