# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckOpenStatusService do
  subject(:check_open_status) { described_class.new(merge_request: merge_request, params: {}) }

  let(:merge_request) { build(:merge_request) }

  describe '#execute' do
    before do
      expect(merge_request).to receive(:open?).and_return(open)
    end

    context 'when the merge request is open' do
      let(:open) { true }

      it 'returns a check result with status success' do
        expect(check_open_status.execute.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
      end
    end

    context 'when the merge request is not open' do
      let(:open) { false }

      it 'returns a check result with status failed' do
        expect(check_open_status.execute.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
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
