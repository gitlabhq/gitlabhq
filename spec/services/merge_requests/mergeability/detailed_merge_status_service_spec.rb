# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::MergeRequests::Mergeability::DetailedMergeStatusService, feature_category: :code_review_workflow do
  subject(:detailed_merge_status) { described_class.new(merge_request: merge_request).execute }

  let(:merge_request) { create(:merge_request) }

  it 'calls every mergeability check' do
    expect(merge_request).to receive(:execute_merge_checks)
      .with(MergeRequest.all_mergeability_checks, any_args)
      .and_call_original

    detailed_merge_status
  end

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

    before do
      merge_request.project.update!(only_allow_merge_if_pipeline_succeeds: false)
    end

    it 'returns :mergeable' do
      expect(detailed_merge_status).to eq(:mergeable)
    end
  end

  context 'when merge status have a failure' do
    let(:merge_request) { create(:merge_request) }

    before do
      merge_request.close!
    end

    it 'returns the failed check' do
      expect(detailed_merge_status).to eq(:not_open)
    end
  end

  context 'when all but the ci check fails' do
    let(:merge_request) { create(:merge_request) }

    before do
      merge_request.project.update!(only_allow_merge_if_pipeline_succeeds: true)
    end

    context 'when pipeline does not exist' do
      it 'returns the failed check' do
        expect(detailed_merge_status).to eq(:ci_must_pass)
      end
    end

    context 'when pipeline exists' do
      using RSpec::Parameterized::TableSyntax

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

      where(:ci_status, :expected_detailed_merge_status) do
        :created   | :ci_still_running
        :pending   | :ci_still_running
        :running   | :ci_still_running
        :manual    | :ci_still_running
        :scheduled | :ci_still_running
        :failed    | :ci_must_pass
        :success   | :mergeable
      end

      with_them do
        it { expect(detailed_merge_status).to eq(expected_detailed_merge_status) }
      end
    end
  end

  context 'with duration logging' do
    let(:current_user) { create(:user) }

    before do
      merge_request.project.update!(only_allow_merge_if_pipeline_succeeds: false)
      allow(Gitlab::AppJsonLogger).to receive(:info)
    end

    it 'logs duration for mergeability checks' do
      expect(Gitlab::AppJsonLogger).to receive(:info).with(
        hash_including(
          event: 'merge_requests_detailed_merge_status_service_executed',
          operation: :verify_all_mr_mergeability_checks,
          merge_request_id: merge_request.id,
          duration_s: a_kind_of(Numeric)
        )
      )

      detailed_merge_status
    end

    it 'logs duration for ci status check' do
      expect(Gitlab::AppJsonLogger).to receive(:info).with(
        hash_including(
          event: 'merge_requests_detailed_merge_status_service_executed',
          operation: :check_ci_status,
          merge_request_id: merge_request.id,
          duration_s: a_kind_of(Numeric)
        )
      )

      detailed_merge_status
    end

    context 'when log_detailed_merge_status_duration_enabled feature flag is disabled' do
      before do
        stub_feature_flags(log_detailed_merge_status_duration_enabled: false)
      end

      it 'does not log duration' do
        expect(Gitlab::AppJsonLogger).not_to receive(:info).with(
          hash_including(event: 'merge_requests_detailed_merge_status_service_executed'))
        detailed_merge_status
      end
    end
  end
end
