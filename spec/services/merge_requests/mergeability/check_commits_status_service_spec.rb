# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckCommitsStatusService, feature_category: :code_review_workflow do
  subject(:check_commits_status) { described_class.new(merge_request: merge_request, params: {}) }

  let(:merge_request) { build(:merge_request) }

  it_behaves_like 'mergeability check service', :commits_status, 'Checks source branch exists and contains commits.'

  describe '#execute' do
    let(:result) { check_commits_status.execute }
    let(:has_no_commits) { false }
    let(:branch_missing) { false }

    before do
      allow(merge_request).to receive(:has_no_commits?).and_return(has_no_commits)
      allow(merge_request).to receive(:branch_missing?).and_return(branch_missing)
    end

    context 'when the merge request branch is missing' do
      let(:branch_missing) { true }

      it 'returns a check result with status failed' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
        expect(result.payload[:identifier]).to eq(:commits_status)
      end
    end

    context 'when the merge request has no commits' do
      let(:has_no_commits) { true }

      it 'returns a check result with status failed' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
        expect(result.payload[:identifier]).to eq(:commits_status)
      end
    end

    context 'when the merge request contains commits' do
      it 'returns a check result with status success' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
      end
    end
  end

  describe '#skip?' do
    it 'returns false' do
      expect(check_commits_status.skip?).to eq false
    end
  end

  describe '#cacheable?' do
    it 'returns false' do
      expect(check_commits_status.cacheable?).to eq false
    end
  end
end
