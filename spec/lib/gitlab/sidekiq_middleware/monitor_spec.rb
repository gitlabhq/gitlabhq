# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::Monitor do
  let(:monitor) { described_class.new }

  describe '#call' do
    let(:worker) { double }
    let(:job) { { 'jid' => 'job-id' } }
    let(:queue) { 'my-queue' }

    it 'calls Gitlab::SidekiqDaemon::Monitor' do
      expect(Gitlab::SidekiqDaemon::Monitor.instance).to receive(:within_job)
        .with(anything, 'job-id', 'my-queue')
        .and_call_original

      expect { |blk| monitor.call(worker, job, queue, &blk) }.to yield_control
    end

    it 'passthroughs the return value' do
      result = monitor.call(worker, job, queue) do
        'value'
      end

      expect(result).to eq('value')
    end

    context 'when cancel happens' do
      subject do
        monitor.call(worker, job, queue) do
          raise Gitlab::SidekiqDaemon::Monitor::CancelledError
        end
      end

      it 'skips the job' do
        expect { subject }.to raise_error(Sidekiq::JobRetry::Skip)
      end

      it 'puts job in DeadSet' do
        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls { ::Sidekiq::DeadSet.new.clear }

        expect do
          subject
        rescue Sidekiq::JobRetry::Skip
          nil
        end.to change {
                 Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
                   ::Sidekiq::DeadSet.new.size
                 end
               }.by(1)
      end
    end
  end
end
