# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckCiStatusService, feature_category: :code_review_workflow do
  subject(:check_ci_status) { described_class.new(merge_request: merge_request, params: params) }

  let(:merge_request) { build(:merge_request) }
  let(:params) { { skip_ci_check: skip_check } }
  let(:skip_check) { false }

  describe '#execute' do
    let(:result) { check_ci_status.execute }

    before do
      expect(merge_request).to receive(:mergeable_ci_state?).and_return(mergeable)
    end

    context 'when the merge request is in a mergable state' do
      let(:mergeable) { true }

      it 'returns a check result with status success' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
      end
    end

    context 'when the merge request is not in a mergeable state' do
      let(:mergeable) { false }

      it 'returns a check result with status failed' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
        expect(result.payload[:reason]).to eq :ci_must_pass
      end
    end
  end

  describe '#skip?' do
    context 'when skip check is true' do
      let(:skip_check) { true }

      it 'returns true' do
        expect(check_ci_status.skip?).to eq true
      end
    end

    context 'when skip check is false' do
      let(:skip_check) { false }

      it 'returns false' do
        expect(check_ci_status.skip?).to eq false
      end
    end
  end

  describe '#cacheable?' do
    it 'returns false' do
      expect(check_ci_status.cacheable?).to eq false
    end
  end
end
