# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckMergeTimeService, feature_category: :code_review_workflow do
  subject(:check_merge_time) { described_class.new(merge_request: merge_request, params: params) }

  let_it_be(:merge_request) { build(:merge_request) }

  let(:params) { { skip_merge_time_check: skip_check } }
  let(:skip_check) { false }

  it_behaves_like 'mergeability check service', :merge_time,
    'Checks whether the merge is blocked due to a scheduled merge time'

  describe '#execute' do
    let(:result) { check_merge_time.execute }

    before do
      merge_request.merge_schedule = build(
        :merge_request_merge_schedule,
        merge_request: merge_request,
        merge_after: merge_after
      )
    end

    context 'when merge_after is not set' do
      let(:merge_after) { nil }

      it 'returns a check result with status inactive' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::INACTIVE_STATUS
        expect(result.payload[:identifier]).to eq(:merge_time)
      end
    end

    context 'when merge_after is in the future' do
      let(:merge_after) { 1.minute.from_now }

      it 'returns a check result with status failed' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
        expect(result.payload[:identifier]).to eq(:merge_time)
      end
    end

    context 'when merge_after is in the past' do
      let(:merge_after) { 1.minute.ago }

      it 'returns a check result with status success' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
        expect(result.payload[:identifier]).to eq(:merge_time)
      end
    end
  end

  describe '#skip?' do
    context 'when skip check param is true' do
      let(:skip_check) { true }

      it 'returns true' do
        expect(check_merge_time.skip?).to eq true
      end
    end

    context 'when skip check param is false' do
      let(:skip_check) { false }

      it 'returns false' do
        expect(check_merge_time.skip?).to eq false
      end
    end
  end

  describe '#cacheable?' do
    it 'returns false' do
      expect(check_merge_time.cacheable?).to eq false
    end
  end
end
