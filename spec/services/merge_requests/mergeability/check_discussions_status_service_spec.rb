# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckDiscussionsStatusService, feature_category: :code_review_workflow do
  subject(:check_discussions_status) { described_class.new(merge_request: merge_request, params: params) }

  let_it_be(:project) { build(:project) }
  let_it_be(:merge_request) { build(:merge_request, source_project: project) }
  let(:params) { { skip_discussions_check: skip_check } }
  let(:skip_check) { false }

  it_behaves_like 'mergeability check service', :discussions_not_resolved,
    'Checks whether the merge request has open discussions'

  describe '#execute' do
    let(:result) { check_discussions_status.execute }

    before do
      allow(merge_request)
        .to receive(:only_allow_merge_if_all_discussions_are_resolved?)
        .and_return(only_allow_merge_if_all_discussions_are_resolved?)
    end

    context 'when only_allow_merge_if_all_discussions_are_resolved is true' do
      let(:only_allow_merge_if_all_discussions_are_resolved?) { true }

      before do
        allow(merge_request).to receive(:mergeable_discussions_state?).and_return(mergeable)
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
          expect(result.payload[:identifier]).to eq(:discussions_not_resolved)
        end
      end
    end

    context 'when only_allow_merge_if_all_discussions_are_resolved is false' do
      let(:only_allow_merge_if_all_discussions_are_resolved?) { false }

      it 'returns a check result with inactive status' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::INACTIVE_STATUS
      end
    end
  end

  describe '#skip?' do
    context 'when skip check is true' do
      let(:skip_check) { true }

      it 'returns true' do
        expect(check_discussions_status.skip?).to eq true
      end
    end

    context 'when skip check is false' do
      let(:skip_check) { false }

      it 'returns false' do
        expect(check_discussions_status.skip?).to eq false
      end
    end
  end

  describe '#cacheable?' do
    it 'returns false' do
      expect(check_discussions_status.cacheable?).to eq false
    end
  end
end
