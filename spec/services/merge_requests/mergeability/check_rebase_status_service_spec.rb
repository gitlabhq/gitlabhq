# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckRebaseStatusService, feature_category: :code_review_workflow do
  subject(:check_rebase_status) { described_class.new(merge_request: merge_request, params: params) }

  let(:merge_request) { build(:merge_request) }
  let(:params) { { skip_rebase_check: skip_check } }
  let(:skip_check) { false }

  describe '#execute' do
    let(:result) { check_rebase_status.execute }

    before do
      allow(merge_request).to receive(:should_be_rebased?).and_return(should_be_rebased)
    end

    context 'when the merge request should be rebased' do
      let(:should_be_rebased) { true }

      it 'returns a check result with status failed' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
        expect(result.payload[:reason]).to eq :need_rebase
      end
    end

    context 'when the merge request should not be rebased' do
      let(:should_be_rebased) { false }

      it 'returns a check result with status success' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
      end
    end
  end

  describe '#skip?' do
    context 'when skip check is true' do
      let(:skip_check) { true }

      it 'returns true' do
        expect(check_rebase_status.skip?).to eq true
      end
    end

    context 'when skip check is false' do
      let(:skip_check) { false }

      it 'returns false' do
        expect(check_rebase_status.skip?).to eq false
      end
    end
  end

  describe '#cacheable?' do
    it 'returns false' do
      expect(check_rebase_status.cacheable?).to eq false
    end
  end
end
