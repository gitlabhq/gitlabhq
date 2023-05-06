# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::MergeRequests::Mergeability::DetailedMergeStatusService, feature_category: :code_review_workflow do
  subject(:detailed_merge_status) { described_class.new(merge_request: merge_request).execute }

  context 'when merge status is cannot_be_merged_rechecking' do
    let(:merge_request) { create(:merge_request, merge_status: :cannot_be_merged_rechecking) }

    it 'returns :checking' do
      expect(detailed_merge_status).to eq(:checking)
    end
  end

  context 'when merge status is preparing' do
    let(:merge_request) { create(:merge_request, merge_status: :preparing) }

    it 'returns :checking' do
      allow(merge_request.merge_request_diff).to receive(:persisted?).and_return(false)

      expect(detailed_merge_status).to eq(:preparing)
    end
  end

  context 'when merge status is preparing and merge request diff is persisted' do
    let(:merge_request) { create(:merge_request, merge_status: :preparing) }

    it 'returns :checking' do
      allow(merge_request.merge_request_diff).to receive(:persisted?).and_return(true)

      expect(detailed_merge_status).to eq(:mergeable)
    end
  end

  context 'when merge status is checking' do
    let(:merge_request) { create(:merge_request, merge_status: :checking) }

    it 'returns :checking' do
      expect(detailed_merge_status).to eq(:checking)
    end
  end

  context 'when merge status is unchecked' do
    let(:merge_request) { create(:merge_request, merge_status: :unchecked) }

    it 'returns :unchecked' do
      expect(detailed_merge_status).to eq(:unchecked)
    end
  end

  context 'when merge checks are a success' do
    let(:merge_request) { create(:merge_request) }

    it 'returns :mergeable' do
      expect(detailed_merge_status).to eq(:mergeable)
    end
  end

  context 'when merge status have a failure' do
    let(:merge_request) { create(:merge_request) }

    before do
      merge_request.close!
    end

    it 'returns the failure reason' do
      expect(detailed_merge_status).to eq(:not_open)
    end
  end

  context 'when all but the ci check fails' do
    let(:merge_request) { create(:merge_request) }

    before do
      merge_request.project.update!(only_allow_merge_if_pipeline_succeeds: true)
    end

    context 'when pipeline does not exist' do
      it 'returns the failure reason' do
        expect(detailed_merge_status).to eq(:ci_must_pass)
      end
    end

    context 'when pipeline exists' do
      before do
        create(
          :ci_pipeline,
          ci_status,
          merge_request: merge_request,
          project: merge_request.project,
          sha: merge_request.source_branch_sha,
          head_pipeline_of: merge_request
        )
      end

      context 'when the pipeline is running' do
        let(:ci_status) { :running }

        it 'returns the failure reason' do
          expect(detailed_merge_status).to eq(:ci_still_running)
        end
      end

      context 'when the pipeline is not running' do
        let(:ci_status) { :failed }

        it 'returns the failure reason' do
          expect(detailed_merge_status).to eq(:ci_must_pass)
        end
      end
    end
  end
end
