# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckBrokenStatusService, feature_category: :code_review_workflow do
  subject(:check_broken_status) { described_class.new(merge_request: merge_request, params: {}) }

  let(:merge_request) { build(:merge_request) }

  it_behaves_like 'mergeability check service', :broken_status, 'Checks whether the merge request is broken'

  describe '#execute' do
    let(:result) { check_broken_status.execute }

    before do
      expect(merge_request).to receive(:broken?).and_return(broken)
    end

    context 'when the merge request is broken' do
      let(:broken) { true }

      it 'returns a check result with status failed' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
        expect(result.payload[:identifier]).to eq(:broken_status)
      end
    end

    context 'when the merge request is not broken' do
      let(:broken) { false }

      it 'returns a check result with status success' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
      end
    end
  end

  describe '#skip?' do
    it 'returns false' do
      expect(check_broken_status.skip?).to eq false
    end
  end

  describe '#cacheable?' do
    it 'returns false' do
      expect(check_broken_status.cacheable?).to eq false
    end
  end
end
