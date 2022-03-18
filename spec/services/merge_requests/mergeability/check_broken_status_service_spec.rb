# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckBrokenStatusService do
  subject(:check_broken_status) { described_class.new(merge_request: merge_request, params: {}) }

  let(:merge_request) { build(:merge_request) }

  describe '#execute' do
    before do
      expect(merge_request).to receive(:broken?).and_return(broken)
    end

    context 'when the merge request is broken' do
      let(:broken) { true }

      it 'returns a check result with status failed' do
        expect(check_broken_status.execute.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
      end
    end

    context 'when the merge request is not broken' do
      let(:broken) { false }

      it 'returns a check result with status success' do
        expect(check_broken_status.execute.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
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
