# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::RunChecksService do
  subject(:run_checks) { described_class.new(merge_request: merge_request, params: {}) }

  let_it_be(:merge_request) { create(:merge_request) }

  describe '#CHECKS' do
    it 'contains every subclass of the base checks service', :eager_load do
      expect(described_class::CHECKS).to contain_exactly(*MergeRequests::Mergeability::CheckBaseService.subclasses)
    end
  end

  describe '#execute' do
    subject(:execute) { run_checks.execute }

    let(:params) { {} }
    let(:success_result) { Gitlab::MergeRequests::Mergeability::CheckResult.success }

    context 'when every check is skipped', :eager_load do
      before do
        MergeRequests::Mergeability::CheckBaseService.subclasses.each do |subclass|
          expect_next_instance_of(subclass) do |service|
            expect(service).to receive(:skip?).and_return(true)
          end
        end
      end

      it 'is still a success' do
        expect(execute.all?(&:success?)).to eq(true)
      end
    end

    context 'when a check is skipped' do
      it 'does not execute the check' do
        described_class::CHECKS.each do |check|
          allow_next_instance_of(check) do |service|
            allow(service).to receive(:skip?).and_return(false)
            allow(service).to receive(:execute).and_return(success_result)
          end
        end

        expect_next_instance_of(MergeRequests::Mergeability::CheckCiStatusService) do |service|
          expect(service).to receive(:skip?).and_return(true)
          expect(service).not_to receive(:execute)
        end

        expect(execute).to match_array([success_result, success_result, success_result, success_result])
      end
    end

    context 'when a check is not skipped' do
      let(:cacheable) { true }
      let(:merge_check) { instance_double(MergeRequests::Mergeability::CheckCiStatusService) }

      before do
        described_class::CHECKS.each do |check|
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

            expect(execute).to match_array([success_result])
          end
        end

        context 'when the check is not cached' do
          it 'writes and returns the result' do
            expect_next_instance_of(Gitlab::MergeRequests::Mergeability::ResultsStore) do |service|
              expect(service).to receive(:read).with(merge_check: merge_check).and_return(nil)
              expect(service).to receive(:write).with(merge_check: merge_check, result_hash: success_result.to_hash).and_return(true)
            end

            expect(execute).to match_array([success_result])
          end
        end
      end

      context 'when check is not cacheable' do
        let(:cacheable) { false }

        it 'does not call the results store' do
          expect(Gitlab::MergeRequests::Mergeability::ResultsStore).not_to receive(:new)

          expect(execute).to match_array([success_result])
        end
      end

      context 'when mergeability_caching is turned off' do
        before do
          stub_feature_flags(mergeability_caching: false)
        end

        it 'does not call the results store' do
          expect(Gitlab::MergeRequests::Mergeability::ResultsStore).not_to receive(:new)

          expect(execute).to match_array([success_result])
        end
      end
    end
  end
end
