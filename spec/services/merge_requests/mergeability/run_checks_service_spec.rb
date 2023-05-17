# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::RunChecksService, :clean_gitlab_redis_cache, feature_category: :code_review_workflow do
  subject(:run_checks) { described_class.new(merge_request: merge_request, params: {}) }

  describe '#execute' do
    subject(:execute) { run_checks.execute }

    let_it_be(:merge_request) { create(:merge_request) }

    let(:params) { {} }
    let(:success_result) { Gitlab::MergeRequests::Mergeability::CheckResult.success }

    context 'when every check is skipped', :eager_load do
      before do
        MergeRequests::Mergeability::CheckBaseService.subclasses.each do |subclass|
          allow_next_instance_of(subclass) do |service|
            allow(service).to receive(:skip?).and_return(true)
          end
        end
      end

      it 'is still a success' do
        expect(execute.success?).to eq(true)
      end
    end

    context 'when a check is skipped' do
      it 'does not execute the check' do
        merge_request.mergeability_checks.each do |check|
          allow_next_instance_of(check) do |service|
            allow(service).to receive(:skip?).and_return(false)
            allow(service).to receive(:execute).and_return(success_result)
          end
        end

        expect_next_instance_of(MergeRequests::Mergeability::CheckCiStatusService) do |service|
          expect(service).to receive(:skip?).and_return(true)
          expect(service).not_to receive(:execute)
        end

        expect(execute.success?).to eq(true)
      end
    end

    context 'when a check is not skipped' do
      let(:cacheable) { true }
      let(:merge_check) { instance_double(MergeRequests::Mergeability::CheckCiStatusService) }

      before do
        merge_request.mergeability_checks.each do |check|
          allow_next_instance_of(check) do |service|
            allow(service).to receive(:skip?).and_return(true)
          end
        end

        expect(MergeRequests::Mergeability::CheckCiStatusService).to receive(:new).and_return(merge_check)
        expect(merge_check).to receive(:skip?).and_return(false)
        allow(merge_check).to receive(:cacheable?).and_return(cacheable)
        allow(merge_check).to receive(:execute).and_return(success_result)
      end

      context 'when the check is cacheable' do
        context 'when the check is cached' do
          it 'returns the cached result' do
            expect_next_instance_of(Gitlab::MergeRequests::Mergeability::ResultsStore) do |service|
              expect(service).to receive(:read).with(merge_check: merge_check).and_return(success_result)
            end

            expect_next_instance_of(MergeRequests::Mergeability::Logger, merge_request: merge_request) do |logger|
              expect(logger).to receive(:instrument).with(mergeability_name: 'check_ci_status_service').and_call_original
              expect(logger).to receive(:commit)
            end

            expect(execute.success?).to eq(true)
          end
        end

        context 'when the check is not cached' do
          it 'writes and returns the result' do
            expect_next_instance_of(Gitlab::MergeRequests::Mergeability::ResultsStore) do |service|
              expect(service).to receive(:read).with(merge_check: merge_check).and_return(nil)
              expect(service).to receive(:write).with(merge_check: merge_check, result_hash: success_result.to_hash).and_return(true)
            end

            expect_next_instance_of(MergeRequests::Mergeability::Logger, merge_request: merge_request) do |logger|
              expect(logger).to receive(:instrument).with(mergeability_name: 'check_ci_status_service').and_call_original
              expect(logger).to receive(:commit)
            end

            expect(execute.success?).to eq(true)
          end
        end
      end

      context 'when check is not cacheable' do
        let(:cacheable) { false }

        it 'does not call the results store' do
          expect(Gitlab::MergeRequests::Mergeability::ResultsStore).not_to receive(:new)

          expect(execute.success?).to eq(true)
        end
      end
    end
  end

  describe '#success?' do
    subject(:success) { run_checks.success? }

    let_it_be(:merge_request) { create(:merge_request) }

    context 'when the execute method has been executed' do
      before do
        run_checks.execute
      end

      context 'when all the checks succeed' do
        it 'returns true' do
          expect(success).to eq(true)
        end
      end

      context 'when one check fails' do
        before do
          allow(merge_request).to receive(:open?).and_return(false)
          run_checks.execute
        end

        it 'returns false' do
          expect(success).to eq(false)
        end
      end
    end

    context 'when execute has not been exectued' do
      it 'raises an error' do
        expect { subject }
          .to raise_error(/Execute needs to be called before/)
      end
    end
  end

  describe '#failure_reason' do
    subject(:failure_reason) { run_checks.failure_reason }

    let_it_be(:merge_request) { create(:merge_request) }

    context 'when the execute method has been executed' do
      context 'when all the checks succeed' do
        before do
          run_checks.execute
        end

        it 'returns nil' do
          expect(failure_reason).to eq(nil)
        end
      end

      context 'when one check fails' do
        before do
          allow(merge_request).to receive(:open?).and_return(false)
          run_checks.execute
        end

        it 'returns the open reason' do
          expect(failure_reason).to eq(:not_open)
        end
      end
    end

    context 'when execute has not been exectued' do
      it 'raises an error' do
        expect { subject }
          .to raise_error(/Execute needs to be called before/)
      end
    end
  end
end
