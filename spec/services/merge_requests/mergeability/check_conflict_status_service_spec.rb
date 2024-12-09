# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckConflictStatusService, feature_category: :code_review_workflow do
  subject(:check_conflict_status) { described_class.new(merge_request: merge_request, params: {}) }

  let(:merge_request) { build(:merge_request) }

  it_behaves_like 'mergeability check service', :conflict, 'Checks whether the merge request has a conflict'

  describe '#execute' do
    let(:result) { check_conflict_status.execute }

    before do
      allow(merge_request).to receive(:can_be_merged?).and_return(can_be_merged)
    end

    context 'when MergeRequest#can_be_merged is true' do
      let(:can_be_merged) { true }

      it 'returns a check result with status success' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
      end
    end

    context 'when MergeRequest#can_be_merged is false' do
      let(:can_be_merged) { false }

      it 'returns a check result with status failed' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
        expect(result.payload[:identifier]).to eq(:conflict)
      end
    end
  end

  describe '#skip?' do
    using RSpec::Parameterized::TableSyntax

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
