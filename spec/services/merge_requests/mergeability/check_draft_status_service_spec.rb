# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckDraftStatusService, feature_category: :code_review_workflow do
  subject(:check_draft_status) { described_class.new(merge_request: merge_request, params: {}) }

  let(:merge_request) { build(:merge_request) }

  describe '#execute' do
    let(:result) { check_draft_status.execute }

    before do
      expect(merge_request).to receive(:draft?).and_return(draft)
    end

    context 'when the merge request is a draft' do
      let(:draft) { true }

      it 'returns a check result with status failed' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
        expect(result.payload[:reason]).to eq(:draft_status)
      end
    end

    context 'when the merge request is not a draft' do
      let(:draft) { false }

      it 'returns a check result with status success' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
      end
    end
  end

  describe '#skip?' do
    it 'returns false' do
      expect(check_draft_status.skip?).to eq false
    end
  end

  describe '#cacheable?' do
    it 'returns false' do
      expect(check_draft_status.cacheable?).to eq false
    end
  end
end
