# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ResolveTodosWorker, feature_category: :code_review_workflow do
  include AfterNextHelpers

  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:user) { create(:user) }

  let(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [merge_request.id, user.id] }
  end

  describe '#perform' do
    it 'calls MergeRequests::ResolveTodosService#execute' do
      expect_next(::MergeRequests::ResolveTodosService, merge_request, user)
        .to receive(:execute)

      worker.perform(merge_request.id, user.id)
    end

    context 'with a non-existing merge request' do
      it 'does nothing' do
        expect(::MergeRequests::ResolveTodosService).not_to receive(:new)

        worker.perform(non_existing_record_id, user.id)
      end
    end

    context 'with a non-existing user' do
      it 'does nothing' do
        expect(::MergeRequests::ResolveTodosService).not_to receive(:new)

        worker.perform(merge_request.id, non_existing_record_id)
      end
    end
  end
end
