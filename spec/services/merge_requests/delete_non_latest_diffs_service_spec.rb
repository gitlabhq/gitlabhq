# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::DeleteNonLatestDiffsService, :clean_gitlab_redis_shared_state,
  feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }

  let!(:subject) { described_class.new(merge_request) }

  describe '#execute' do
    before do
      stub_const("#{described_class.name}::BATCH_SIZE", 2)

      3.times { merge_request.create_merge_request_diff }
      merge_request.create_merge_head_diff
      merge_request.reset
      merge_request.merge_request_diffs.reload
    end

    it 'schedules non-latest merge request diffs removal' do
      diffs = merge_request.merge_request_diffs.order(:id)

      expect(diffs.count).to eq(4)

      expected_ids = diffs.first(2).map { |d| [d.id] }

      freeze_time do
        expect(DeleteDiffFilesWorker)
          .to receive(:bulk_perform_in)
          .with(5.minutes, match_array(expected_ids))
        expect(DeleteDiffFilesWorker)
          .to receive(:bulk_perform_in)
          .with(10.minutes, [[diffs.third.id]])

        subject.execute
      end
    end

    it 'schedules no removal if it is already cleaned' do
      merge_request.merge_request_diffs.each(&:clean!)
      merge_request.merge_request_diffs.reload

      expect(DeleteDiffFilesWorker).not_to receive(:bulk_perform_in)

      subject.execute
    end

    it 'schedules no removal if it is empty' do
      merge_request.merge_request_diffs.each { |diff| diff.update!(state: :empty) }
      merge_request.merge_request_diffs.reload

      expect(DeleteDiffFilesWorker).not_to receive(:bulk_perform_in)

      subject.execute
    end

    it 'schedules no removal if there is no non-latest diffs' do
      # rubocop: disable Cop/DestroyAll
      merge_request
        .merge_request_diffs
        .where.not(id: merge_request.latest_merge_request_diff_id)
        .destroy_all
      merge_request.merge_request_diffs.reload
      # rubocop: enable Cop/DestroyAll

      expect(DeleteDiffFilesWorker).not_to receive(:bulk_perform_in)

      subject.execute
    end
  end
end
