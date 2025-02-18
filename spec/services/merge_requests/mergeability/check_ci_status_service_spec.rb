# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckCiStatusService, feature_category: :code_review_workflow do
  subject(:check_ci_status) { described_class.new(merge_request: merge_request, params: params) }

  let(:project) do
    build(:project,
      only_allow_merge_if_pipeline_succeeds: only_allow_merge_if_pipeline_succeeds,
      allow_merge_on_skipped_pipeline: allow_merge_on_skipped_pipeline)
  end

  let(:merge_request) do
    build(:merge_request,
      source_project: project,
      auto_merge_strategy: auto_merge_strategy,
      auto_merge_enabled: auto_merge_enabled)
  end

  let(:allow_merge_on_skipped_pipeline) { false }
  let(:only_allow_merge_if_pipeline_succeeds) { false }
  let(:auto_merge_strategy) { nil }
  let(:auto_merge_enabled) { false }

  let(:params) { { skip_ci_check: skip_check } }
  let(:skip_check) { false }

  let(:result) { check_ci_status.execute }

  it_behaves_like 'mergeability check service', :ci_must_pass, 'Checks whether CI has passed'

  shared_examples 'a valid diff head pipeline is required' do
    context 'when there is no diff head pipeline' do
      it 'is failure' do
        expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
      end
    end

    context 'when there is a diff head pipeline' do
      let(:pipeline) { create(:ci_empty_pipeline, sha: '1982309812309812') }

      before do
        merge_request.update_attribute(:head_pipeline_id, pipeline.id)
      end

      context 'when there is a pipeline being created' do
        before do
          allow(Ci::PipelineCreation::Requests).to receive(:pipeline_creating_for_merge_request?).and_return(true)
        end

        it 'is failure' do
          expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
        end
      end

      context 'when there is no pipeline being created' do
        before do
          allow(Ci::PipelineCreation::Requests).to receive(:pipeline_creating_for_merge_request?).and_return(false)
        end

        context 'when the diff head pipeline is skipped' do
          before do
            pipeline.update_attribute(:status, :skipped)
          end

          context 'when it is allowed to be skipped' do
            let(:allow_merge_on_skipped_pipeline) { true }

            it 'is success' do
              expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
            end
          end

          context 'when it is not allowed to be skipped' do
            let(:allow_merge_on_skipped_pipeline) { false }

            it 'is failed' do
              expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
            end
          end
        end

        context 'when the diff head pipeline is successful' do
          before do
            pipeline.update_attribute(:status, :success)
          end

          it 'is success' do
            expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
          end
        end

        context 'when the diff head pipeline is not skipped or successful' do
          it 'is failed' do
            expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
          end
        end
      end
    end
  end

  describe '#execute' do
    context 'when a successful pipeline is required for merge' do
      let(:only_allow_merge_if_pipeline_succeeds) { true }

      it_behaves_like 'a valid diff head pipeline is required'
    end

    context 'when a successful pipeline is not required for merge' do
      context 'when auto merge is not enabled' do
        it 'is inactive' do
          expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::INACTIVE_STATUS
        end
      end

      context 'when auto merge is enabled' do
        let(:auto_merge_enabled) { true }
        let(:auto_merge_strategy) { ::AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS }

        context 'when the auto merge strategy is STATEGY_MERGE_WHEN_CHECKS_PASS and ci is disabled' do
          it 'is success' do
            expect(result.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
          end
        end

        context 'when the auto merge strategy is STATEGY_MERGE_WHEN_CHECKS_PASS and ci is enabled' do
          let(:auto_merge_strategy) { ::AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS }

          before do
            allow(merge_request).to receive(:has_ci_enabled?).and_return(true)
          end

          it_behaves_like 'a valid diff head pipeline is required'
        end
      end
    end
  end

  describe '#skip?' do
    context 'when skip check is present in the params' do
      let(:skip_check) { true }

      it 'returns true' do
        expect(check_ci_status.skip?).to eq true
      end
    end

    context 'when skip check is not present in the params' do
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
