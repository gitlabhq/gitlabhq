# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ReloadMergeHeadDiffService do
  let(:merge_request) { create(:merge_request) }

  subject { described_class.new(merge_request).execute }

  describe '#execute' do
    before do
      MergeRequests::MergeToRefService
        .new(project: merge_request.project, current_user: merge_request.author)
        .execute(merge_request)
    end

    it 'creates a merge head diff' do
      expect(subject[:status]).to eq(:success)
      expect(merge_request.reload.merge_head_diff).to be_present
    end

    context 'when merge ref head is not present' do
      before do
        allow(merge_request).to receive(:merge_ref_head).and_return(nil)
      end

      it 'returns error' do
        expect(subject[:status]).to eq(:error)
      end
    end

    context 'when failed to create merge head diff' do
      before do
        allow(merge_request).to receive(:create_merge_head_diff!).and_raise('fail')
      end

      it 'returns error' do
        expect(subject[:status]).to eq(:error)
      end
    end

    context 'when there is existing merge head diff' do
      let!(:existing_merge_head_diff) { create(:merge_request_diff, :merge_head, merge_request: merge_request) }

      it 'recreates merge head diff' do
        expect(subject[:status]).to eq(:success)
        expect(merge_request.reload.merge_head_diff).not_to eq(existing_merge_head_diff)
      end
    end

    context 'when default_merge_ref_for_diffs feature flag is disabled' do
      before do
        stub_feature_flags(default_merge_ref_for_diffs: false)
      end

      it 'returns error' do
        expect(subject[:status]).to eq(:error)
      end
    end
  end
end
