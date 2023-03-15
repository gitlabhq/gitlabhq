# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::HandleAssigneesChangeWorker, feature_category: :code_review_workflow do
  include AfterNextHelpers

  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:user) { create(:user) }
  let_it_be(:old_assignees) { create_list(:user, 3) }

  let(:user_ids) { old_assignees.map(&:id).to_a }
  let(:options) { {} }
  let(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [merge_request.id, user.id, user_ids, options] }
  end

  describe '#perform' do
    it 'calls MergeRequests::HandleAssigneesChangeService#execute to handle the changes' do
      expect_next(::MergeRequests::HandleAssigneesChangeService)
        .to receive(:execute).with(merge_request, match_array(old_assignees), options)

      worker.perform(merge_request.id, user.id, user_ids, options)
    end

    context 'when there are no changes' do
      it 'still calls MergeRequests::HandleAssigneesChangeService#execute' do
        expect_next(::MergeRequests::HandleAssigneesChangeService)
          .to receive(:execute).with(merge_request, [], options)

        worker.perform(merge_request.id, user.id, merge_request.assignee_ids, options)
      end
    end

    context 'when the old assignees cannot be found' do
      it 'still calls MergeRequests::HandleAssigneesChangeService#execute' do
        expect_next(::MergeRequests::HandleAssigneesChangeService)
          .to receive(:execute).with(merge_request, [], options)

        worker.perform(merge_request.id, user.id, [non_existing_record_id], options)
      end
    end

    context 'with a non-existing merge request' do
      it 'does nothing' do
        expect(::MergeRequests::HandleAssigneesChangeService).not_to receive(:new)

        worker.perform(non_existing_record_id, user.id, user_ids, options)
      end
    end

    context 'with a non-existing user' do
      it 'does nothing' do
        expect(::MergeRequests::HandleAssigneesChangeService).not_to receive(:new)

        worker.perform(merge_request.id, non_existing_record_id, user_ids, options)
      end
    end
  end
end
