# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckApprovedStatusService, feature_category: :code_review_workflow do
  subject(:check_approved_status) { described_class.new(merge_request: merge_request, params: params) }

  let_it_be(:project) { build(:project) }
  let_it_be(:merge_request) { build(:merge_request, source_project: project) }
  let(:params) { { skip_approved_check: skip_check } }
  let(:skip_check) { false }

  it_behaves_like 'mergeability check service', :not_approved,
    'Checks whether the merge request has the required approvals'

  describe '#execute' do
    let(:result) { check_approved_status.execute }

    before do
      allow(merge_request).to receive(:requires_approvals?).and_return(requires_approvals)
    end

    context 'when the project does not require approvals' do
      let(:requires_approvals) { false }

      it 'returns a check result with inactive status' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::INACTIVE_STATUS
      end
    end

    context 'when the project requires approvals' do
      let(:requires_approvals) { true }

      before do
        allow(merge_request).to receive(:approvals_required).and_return(2)
        allow(merge_request).to receive(:approvals_given).and_return(approvals_given)
      end

      context 'when sufficient approvals have been given' do
        let(:approvals_given) { 2 }

        it 'returns a check result with status success' do
          expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
        end
      end

      context 'when more approvals than required have been given' do
        let(:approvals_given) { 3 }

        it 'returns a check result with status success' do
          expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
        end
      end

      context 'when insufficient approvals have been given' do
        let(:approvals_given) { 1 }

        it 'returns a check result with status failed' do
          expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
          expect(result.payload[:identifier]).to eq(:not_approved)
        end
      end

      context 'when no approvals have been given' do
        let(:approvals_given) { 0 }

        it 'returns a check result with status failed' do
          expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
          expect(result.payload[:identifier]).to eq(:not_approved)
        end
      end
    end
  end

  describe '#skip?' do
    context 'when skip check is true' do
      let(:skip_check) { true }

      it 'returns true' do
        expect(check_approved_status.skip?).to eq true
      end
    end

    context 'when skip check is false' do
      let(:skip_check) { false }

      it 'returns false' do
        expect(check_approved_status.skip?).to eq false
      end
    end
  end

  describe '#cacheable?' do
    it 'returns false' do
      expect(check_approved_status.cacheable?).to eq false
    end
  end
end
