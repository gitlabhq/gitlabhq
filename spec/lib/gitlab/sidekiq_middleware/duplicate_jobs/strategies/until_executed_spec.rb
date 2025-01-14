# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies::UntilExecuted do
  it_behaves_like 'deduplicating jobs when scheduling', :until_executed do
    before do
      allow(fake_duplicate_job).to receive(:strategy).and_return(:until_executed)
    end

    describe '#perform' do
      let(:proc) { -> {} }

      before do
        allow(fake_duplicate_job).to receive(:latest_wal_locations).and_return({})
        allow(fake_duplicate_job).to receive(:scheduled?) { false }
        allow(fake_duplicate_job).to receive(:options) { {} }
        allow(fake_duplicate_job).to receive(:idempotency_key).and_return('abc123')
        allow(fake_duplicate_job).to receive(:reschedulable?).and_return(false)
      end

      it 'deletes the lock after executing' do
        expect(proc).to receive(:call).ordered
        expect(fake_duplicate_job).to receive(:delete!).ordered

        strategy.perform({}) do
          proc.call
        end
      end

      it 'deletes the lock even if an error occurs' do
        expect(fake_duplicate_job).not_to receive(:scheduled?)
        expect(fake_duplicate_job).to receive(:delete!).once

        perform_strategy_with_error
      end

      it 'does not reschedule the job even if deduplication happened' do
        expect(fake_duplicate_job).to receive(:delete!).once
        expect(fake_duplicate_job).not_to receive(:reschedule)

        strategy.perform({}) do
          proc.call
        end
      end

      context 'when job is reschedulable' do
        before do
          allow(fake_duplicate_job).to receive(:reschedulable?).and_return(true)
          allow(fake_duplicate_job).to receive(:check_and_del_reschedule_signal).and_return(true)
        end

        it 'reschedules the job if deduplication happened' do
          expect(fake_duplicate_job).to receive(:delete!).once
          expect(fake_duplicate_job).to receive(:reschedule).once

          strategy.perform({}) do
            proc.call
          end
        end

        it 'does not reschedule the job if an error occurs' do
          expect(fake_duplicate_job).to receive(:delete!).once
          expect(fake_duplicate_job).not_to receive(:reschedule)

          perform_strategy_with_error
        end
      end

      def perform_strategy_with_error
        expect do
          strategy.perform({}) do
            raise 'expected error'
          end
        end.to raise_error(RuntimeError, 'expected error')
      end
    end
  end
end
