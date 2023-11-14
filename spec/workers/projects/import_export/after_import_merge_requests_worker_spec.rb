# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::AfterImportMergeRequestsWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:merge_requests) { project.merge_requests }

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
