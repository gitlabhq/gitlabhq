# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestCleanupRefsWorker do
  describe '#perform' do
    context 'when merge request exists' do
      let(:merge_request) { create(:merge_request) }
      let(:job_args) { merge_request.id }

      include_examples 'an idempotent worker' do
        it 'calls MergeRequests::CleanupRefsService#execute' do
          expect_next_instance_of(MergeRequests::CleanupRefsService, merge_request) do |svc|
            expect(svc).to receive(:execute).and_call_original
          end.twice

          subject
        end
      end
    end

    context 'when merge request does not exist' do
      it 'does not call MergeRequests::CleanupRefsService' do
        expect(MergeRequests::CleanupRefsService).not_to receive(:new)

        perform_multiple(1)
      end
    end
  end
end
