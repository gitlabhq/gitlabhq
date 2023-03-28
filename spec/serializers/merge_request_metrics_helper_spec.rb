# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestMetricsHelper do
  let_it_be(:user) { create(:user) }

  let(:merge_request) { create(:merge_request) }
  let(:helper) { Class.new.include(described_class).new }

  describe '#build_metrics' do
    subject do
      helper.build_metrics(merge_request)
    end

    shared_examples 'does not rebuild the metrics' do
      it 'does not call the merge request metrics class' do
        expect(MergeRequest::Metrics).not_to receive(:new)

        subject
      end

      it 'returns the metrics for the given merge request' do
        expect(subject).to be_kind_of(MergeRequest::Metrics)
        expect(subject[:merge_request_id]).to eq(merge_request.id)
      end
    end

    context 'when closed and metrics exists' do
      before do
        merge_request.close!
        merge_request.metrics.update!(latest_closed_by: user)
      end

      include_examples 'does not rebuild the metrics'
    end

    context 'when merged and metrics exists' do
      before do
        merge_request.mark_as_merged!
        merge_request.metrics.update!(merged_by: user)
      end

      include_examples 'does not rebuild the metrics'
    end

    context 'when merged and metrics do not exists' do
      before do
        merge_request.mark_as_merged!
        merge_request.metrics.destroy!
        merge_request.reload
      end

      it 'rebuilds the merge request metrics' do
        closed_event = merge_request.closed_event
        merge_event = merge_request.merge_event

        expect(MergeRequest::Metrics).to receive(:new).with(
          latest_closed_at: closed_event&.updated_at,
          latest_closed_by: closed_event&.author,
          merged_at: merge_event&.updated_at,
          merged_by: merge_event&.author
        ).and_call_original

        subject
      end
    end
  end
end
