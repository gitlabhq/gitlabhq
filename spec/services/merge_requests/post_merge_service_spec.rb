require 'spec_helper'

describe MergeRequests::PostMergeService do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, assignee: user) }
  let(:project) { merge_request.project }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    it_behaves_like 'cache counters invalidator'

    it 'refreshes the number of open merge requests for a valid MR', :use_clean_rails_memory_store_caching do
      # Cache the counter before the MR changed state.
      project.open_merge_requests_count
      merge_request.update!(state: 'merged')

      service = described_class.new(project, user, {})

      expect { service.execute(merge_request) }
        .to change { project.open_merge_requests_count }.from(1).to(0)
    end

    it 'updates metrics' do
      metrics = merge_request.metrics
      metrics_service = double(MergeRequestMetricsService)
      allow(MergeRequestMetricsService)
        .to receive(:new)
        .with(metrics)
        .and_return(metrics_service)

      expect(metrics_service).to receive(:merge)

      described_class.new(project, user, {}).execute(merge_request)
    end

    it 'deletes non-latest diffs' do
      diff_removal_service = instance_double(MergeRequests::DeleteNonLatestDiffsService, execute: nil)

      expect(MergeRequests::DeleteNonLatestDiffsService)
        .to receive(:new).with(merge_request)
        .and_return(diff_removal_service)

      described_class.new(project, user, {}).execute(merge_request)

      expect(diff_removal_service).to have_received(:execute)
    end

    it 'marks MR as merged regardless of errors when closing issues' do
      merge_request.update(target_branch: 'foo')
      allow(project).to receive(:default_branch).and_return('foo')

      issue = create(:issue, project: project)
      allow(merge_request).to receive(:closes_issues).and_return([issue])
      allow_any_instance_of(Issues::CloseService).to receive(:execute).with(issue, commit: merge_request).and_raise

      expect { described_class.new(project, user, {}).execute(merge_request) }.to raise_error

      expect(merge_request.reload).to be_merged
    end
  end
end
