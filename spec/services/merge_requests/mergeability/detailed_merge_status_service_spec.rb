# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::MergeRequests::Mergeability::DetailedMergeStatusService, feature_category: :code_review_workflow do
  subject(:detailed_merge_status) do
    described_class.new(merge_request: merge_request, precomputed_results: precomputed_results).execute
  end

  let(:precomputed) { false }
  let(:precomputed_results) { merge_request.all_mergeability_checks_results if precomputed }
  let(:merge_request) { create(:merge_request) }

  it 'calls every mergeability check' do
    expect(merge_request).to receive(:execute_merge_checks)
      .with(MergeRequest.all_mergeability_checks, any_args)
      .and_call_original

    detailed_merge_status
  end

  context 'when check results are passed in' do
    let(:results) { merge_request.all_mergeability_checks_results }

    it 'reuses them instead of running the checks' do
      results

      expect(merge_request).not_to receive(:execute_merge_checks)

      described_class.new(merge_request: merge_request, precomputed_results: results).execute
    end

    context 'when they have no CI check result' do
      before do
        merge_request.project.update!(only_allow_merge_if_pipeline_succeeds: true)
      end

      it 'runs the CI check itself' do
        results_without_ci = results.reject { |result| result.identifier == :ci_must_pass }

        expect(
          described_class.new(merge_request: merge_request, precomputed_results: results_without_ci).execute
        ).to eq(:ci_must_pass)
      end
    end

    context 'when the reuse_mergeability_check_results feature flag is disabled' do
      before do
        stub_feature_flags(reuse_mergeability_check_results: false)
      end

      it 'runs its own checks' do
        results

        expect(merge_request).to receive(:execute_merge_checks)
          .with(MergeRequest.all_mergeability_checks, any_args)
          .and_call_original

        described_class.new(merge_request: merge_request, precomputed_results: results).execute
      end
    end
  end

  shared_examples 'detailed merge status' do
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
  end

  it_behaves_like 'detailed merge status'

  context 'when the full check results are passed in' do
    let(:precomputed) { true }

    it_behaves_like 'detailed merge status'
  end
end
