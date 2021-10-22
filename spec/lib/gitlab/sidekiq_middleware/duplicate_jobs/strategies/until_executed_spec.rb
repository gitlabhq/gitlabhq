# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies::UntilExecuted do
  it_behaves_like 'deduplicating jobs when scheduling', :until_executed do
    describe '#perform' do
      let(:proc) { -> {} }

      before do
        allow(fake_duplicate_job).to receive(:latest_wal_locations).and_return( {} )
        allow(fake_duplicate_job).to receive(:scheduled?) { false }
        allow(fake_duplicate_job).to receive(:options) { {} }
        allow(fake_duplicate_job).to receive(:should_reschedule?) { false }
      end

      it 'deletes the lock after executing' do
        expect(proc).to receive(:call).ordered
        expect(fake_duplicate_job).to receive(:delete!).ordered

        strategy.perform({}) do
          proc.call
        end
      end

      it 'does not reschedule the job even if deduplication happened' do
        expect(fake_duplicate_job).to receive(:delete!)
        expect(fake_duplicate_job).not_to receive(:reschedule)

        strategy.perform({}) do
          proc.call
        end
      end

      context 'when job is reschedulable' do
        it 'reschedules the job if deduplication happened' do
          allow(fake_duplicate_job).to receive(:should_reschedule?) { true }

          expect(fake_duplicate_job).to receive(:delete!)
          expect(fake_duplicate_job).to receive(:reschedule).once

          strategy.perform({}) do
            proc.call
          end
        end
      end
    end
  end
end
