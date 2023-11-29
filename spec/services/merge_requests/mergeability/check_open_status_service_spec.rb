# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckOpenStatusService, feature_category: :code_review_workflow do
  subject(:check_open_status) { described_class.new(merge_request: merge_request, params: {}) }

  let(:merge_request) { build(:merge_request) }

  it_behaves_like 'mergeability check service', :not_open, 'Checks whether the merge request is open'

  describe '#execute' do
    let(:result) { check_open_status.execute }

    before do
      expect(merge_request).to receive(:open?).and_return(open)
    end

    context 'when the merge request is open' do
      let(:open) { true }

      it 'returns a check result with status success' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
      end
    end

    context 'when the merge request is not open' do
      let(:open) { false }

      it 'returns a check result with status failed' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
        expect(result.payload[:identifier]).to eq(:not_open)
      end
    end
  end

  describe '#skip?' do
    it 'returns false' do
      expect(check_open_status.skip?).to eq false
    end
  end

  describe '#cacheable?' do
    it 'returns false' do
      expect(check_open_status.cacheable?).to eq false
    end
  end
end
