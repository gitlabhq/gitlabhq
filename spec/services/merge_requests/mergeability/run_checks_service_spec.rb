# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::RunChecksService, :clean_gitlab_redis_cache, feature_category: :code_review_workflow do
  let(:checks) { MergeRequest.all_mergeability_checks }
  let(:execute_all) { false }

  subject(:run_checks) { described_class.new(merge_request: merge_request, params: {}) }

  describe '#execute' do
    subject(:execute) { run_checks.execute(checks, execute_all: execute_all) }

    let_it_be(:merge_request) { create(:merge_request) }

    let(:params) { {} }
    let(:success_result) { Gitlab::MergeRequests::Mergeability::CheckResult.success }

    shared_examples 'checks are all executed' do
      context 'when all checks are set to be executed' do
        let(:execute_all) { true }

        specify do
          result = execute

          expect(result.success?).to eq(success?)
          expect(result.payload[:results].count).to eq(expected_count)
        end
      end
    end

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

      it_behaves_like 'checks are all executed' do
        let(:success?) { true }
        let(:expected_count) { 0 }
      end
    end

    context 'when a check is skipped' do
      before do
        checks.each do |check|
          allow_next_instance_of(check) do |service|
            allow(service).to receive(:skip?).and_return(false)
            allow(service).to receive(:execute).and_return(success_result)
          end
        end

        allow_next_instance_of(MergeRequests::Mergeability::CheckCiStatusService) do |service|
          allow(service).to receive(:skip?).and_return(true)
        end
      end

      it 'does not execute the check' do
        expect_next_instance_of(MergeRequests::Mergeability::CheckCiStatusService) do |service|
          expect(service).to receive(:skip?).and_return(true)
          expect(service).not_to receive(:execute)
        end

        expect(execute.success?).to eq(true)
      end

      it_behaves_like 'checks are all executed' do
        let(:success?) { true }
        let(:expected_count) { checks.count - 1 }
      end

      context 'when one check fails' do
        let(:failed_result) { Gitlab::MergeRequests::Mergeability::CheckResult.failed(payload: { identifier: 'failed' }) }

        before do
          allow_next_instance_of(MergeRequests::Mergeability::CheckOpenStatusService) do |service|
            allow(service).to receive(:skip?).and_return(false)
            allow(service).to receive(:execute).and_return(failed_result)
          end
        end

        it 'returns the failed check' do
          result = execute

          expect(result.success?).to eq(false)
          expect(execute.payload[:unsuccessful_check]).to eq(:failed)
        end

        it_behaves_like 'checks are all executed' do
          let(:success?) { false }
          let(:expected_count) { checks.count - 1 }
        end
      end

      context 'when one check is checking' do
        let(:checking_result) { Gitlab::MergeRequests::Mergeability::CheckResult.checking(payload: { identifier: 'checking' }) }

        before do
          allow_next_instance_of(MergeRequests::Mergeability::CheckOpenStatusService) do |service|
            allow(service).to receive(:skip?).and_return(false)
            allow(service).to receive(:execute).and_return(checking_result)
          end
        end

        it 'returns the checking check' do
          result = execute

          expect(result.success?).to eq(false)
          expect(execute.payload[:unsuccessful_check]).to eq(:checking)
        end

        it_behaves_like 'checks are all executed' do
          let(:success?) { false }
          let(:expected_count) { checks.count - 1 }
        end
      end

      context 'when one check is inactive' do
        let(:inactive_result) { Gitlab::MergeRequests::Mergeability::CheckResult.inactive }

        before do
          allow_next_instance_of(MergeRequests::Mergeability::CheckOpenStatusService) do |service|
            allow(service).to receive(:skip?).and_return(false)
            allow(service).to receive(:execute).and_return(inactive_result)
          end
        end

        it 'is still a success' do
          expect(execute.success?).to eq(true)
        end

        it_behaves_like 'checks are all executed' do
          let(:success?) { true }
          let(:expected_count) { checks.count - 1 }
        end
      end
    end

    context 'when a check is not skipped' do
      let(:cacheable) { true }
      let(:merge_check) { instance_double(MergeRequests::Mergeability::CheckCiStatusService) }

      before do
        checks.each do |check|
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
          before do
            expect_next_instance_of(Gitlab::MergeRequests::Mergeability::ResultsStore) do |service|
              expect(service).to receive(:read).with(merge_check: merge_check).and_return(success_result)
            end
          end

          it 'returns the cached result' do
            expect_next_instance_of(MergeRequests::Mergeability::Logger, merge_request: merge_request) do |logger|
              expect(logger).to receive(:instrument).with(mergeability_name: 'check_ci_status_service').and_call_original
              expect(logger).to receive(:commit)
            end

            expect(execute.success?).to eq(true)
          end

          it_behaves_like 'checks are all executed' do
            let(:success?) { true }
            let(:expected_count) { 1 }
          end
        end

        context 'when the check is not cached' do
          before do
            expect_next_instance_of(Gitlab::MergeRequests::Mergeability::ResultsStore) do |service|
              expect(service).to receive(:read).with(merge_check: merge_check).and_return(nil)
              expect(service).to receive(:write).with(merge_check: merge_check, result_hash: success_result.to_hash).and_return(true)
            end
          end

          it 'writes and returns the result' do
            expect_next_instance_of(MergeRequests::Mergeability::Logger, merge_request: merge_request) do |logger|
              expect(logger).to receive(:instrument).with(mergeability_name: 'check_ci_status_service').and_call_original
              expect(logger).to receive(:commit)
            end

            expect(execute.success?).to eq(true)
          end

          it_behaves_like 'checks are all executed' do
            let(:success?) { true }
            let(:expected_count) { 1 }
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
end
