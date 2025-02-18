# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckConflictStatusService, feature_category: :code_review_workflow do
  using RSpec::Parameterized::TableSyntax

  subject(:check_conflict_status) { described_class.new(merge_request: merge_request, params: {}) }

  let(:merge_request) { build(:merge_request, merge_status: merge_status) }
  let(:merge_status) { :can_be_merged }

  it_behaves_like 'mergeability check service', :conflict, 'Checks whether the merge request has a conflict'

  describe '#execute' do
    where(:merge_status, :expected) do
      :preparing | Gitlab::MergeRequests::Mergeability::CheckResult::CHECKING_STATUS
      :unchecked | Gitlab::MergeRequests::Mergeability::CheckResult::CHECKING_STATUS
      :cannot_be_merged_recheck | Gitlab::MergeRequests::Mergeability::CheckResult::CHECKING_STATUS
      :checking | Gitlab::MergeRequests::Mergeability::CheckResult::CHECKING_STATUS
      :cannot_be_merged_rechecking | Gitlab::MergeRequests::Mergeability::CheckResult::CHECKING_STATUS
      :can_be_merged | Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
      :cannot_be_merged | Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
    end

    with_them do
      let(:result) { check_conflict_status.execute }

      it 'returns the expected status' do
        expect(result.status).to eq expected
        expect(result.payload[:identifier]).to eq(:conflict)
      end
    end
  end

  describe '#skip?' do
    where(:skip_conflict_check, :expected) do
      nil   | false
      false | false
      true  | true
    end

    with_them do
      subject do
        described_class
          .new(merge_request: merge_request, params: { skip_conflict_check: skip_conflict_check })
          .skip?
      end

      it { is_expected.to equal expected }
    end
  end

  describe '#cacheable?' do
    it 'returns false' do
      expect(check_conflict_status.cacheable?).to eq false
    end
  end
end
