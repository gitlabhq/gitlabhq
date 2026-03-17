# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqLogging::ConcurrencyLimitLogger, feature_category: :application_instrumentation do
  describe '#deferred_log' do
    let(:job) do
      {
        'class' => 'TestWorker',
        'args' => [1234, 'hello'],
        'jid' => 'da883554ee4fe414012f5f42',
        'correlation_id' => 'cid'
      }
    end

    it 'logs a deferred message to the sidekiq logger' do
      expected_payload = {
        'job_status' => 'concurrency_limit',
        'message' => "#{job['class']} JID-#{job['jid']}: concurrency_limit: paused"
      }
      expect(Sidekiq.logger).to receive(:info).with(a_hash_including(expected_payload)).and_call_original

      described_class.instance.deferred_log(job)
    end

    it 'does not modify the job' do
      expect { described_class.instance.deferred_log(job) }
        .not_to change { job }
    end
  end

  describe '#resumed_log' do
    let(:worker_name) { 'TestWorker' }
    let(:args) { [[1, 2], [3, 4]] }

    it 'logs a resumed message to the sidekiq logger' do
      expected_payload = {
        'job_status' => 'resumed',
        'class' => worker_name
      }
      expect(Sidekiq.logger).to receive(:info).with(a_hash_including(expected_payload)).and_call_original

      described_class.instance.resumed_log(worker_name, args)
    end
  end

  describe '#batch_resumed_log' do
    let(:worker_name) { 'TestWorker' }
    let(:job_count) { 5 }

    it 'logs a batch resumed message with job count' do
      expected_payload = {
        'job_status' => 'resumed',
        'resumed_job_count' => job_count,
        'class' => worker_name
      }
      expect(Sidekiq.logger).to receive(:info).with(a_hash_including(expected_payload)).and_call_original

      described_class.instance.batch_resumed_log(worker_name, job_count)
    end

    it 'logs correctly with different job counts' do
      [1, 10, 100, 1000].each do |count|
        expected_payload = {
          'job_status' => 'resumed',
          'resumed_job_count' => count,
          'class' => worker_name
        }
        expect(Sidekiq.logger).to receive(:info).with(a_hash_including(expected_payload)).and_call_original

        described_class.instance.batch_resumed_log(worker_name, count)
      end
    end
  end

  describe '#worker_stats_log' do
    let(:worker_name) { 'TestWorker' }
    let(:limit) { 10 }
    let(:queue_size) { 5 }
    let(:current) { 3 }

    it 'logs worker statistics' do
      expected_payload = {
        'concurrency_limit' => limit,
        'concurrency_limit_queue_size' => queue_size,
        'current_concurrency' => current
      }
      expect(Sidekiq.logger).to receive(:info).with(a_hash_including(expected_payload)).and_call_original

      described_class.instance.worker_stats_log(worker_name, limit, queue_size, current)
    end
  end
end
