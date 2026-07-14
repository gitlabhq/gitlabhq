# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::AfterImportMergeRequestsWorker, feature_category: :importers do
  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be(:project, freeze: false) { create(:project) }
  let_it_be(:merge_requests, freeze: false) { project.merge_requests }

  let(:worker) { described_class.new }

  describe '#perform' do
    it 'sets the latest merge request diff ids' do
      expect(project.class).to receive(:find_by_id).and_return(project)
      expect(merge_requests).to receive(:set_latest_merge_request_diff_ids!)

      worker.perform(project.id)
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [project.id] }
    end
  end
end
