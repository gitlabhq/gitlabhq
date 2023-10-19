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
    end

    it 'schedules non-latest merge request diffs removal',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/426807' do
      diffs = merge_request.merge_request_diffs

      expect(diffs.count).to eq(4)

      freeze_time do
        expect(DeleteDiffFilesWorker)
          .to receive(:bulk_perform_in)
          .with(5.minutes, [[diffs.first.id], [diffs.second.id]])
        expect(DeleteDiffFilesWorker)
          .to receive(:bulk_perform_in)
          .with(10.minutes, [[diffs.third.id]])

        subject.execute
      end
    end

    it 'schedules no removal if it is already cleaned' do
      merge_request.merge_request_diffs.each(&:clean!)

      expect(DeleteDiffFilesWorker).not_to receive(:bulk_perform_in)

      subject.execute
    end

    it 'schedules no removal if it is empty' do
      merge_request.merge_request_diffs.each { |diff| diff.update!(state: :empty) }

      expect(DeleteDiffFilesWorker).not_to receive(:bulk_perform_in)

      subject.execute
    end

    it 'schedules no removal if there is no non-latest diffs' do
      # rubocop: disable Cop/DestroyAll
      merge_request
        .merge_request_diffs
        .where.not(id: merge_request.latest_merge_request_diff_id)
        .destroy_all
      # rubocop: enable Cop/DestroyAll

      expect(DeleteDiffFilesWorker).not_to receive(:bulk_perform_in)

      subject.execute
    end
  end
end
