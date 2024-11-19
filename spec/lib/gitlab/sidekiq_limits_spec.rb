# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqLimits, feature_category: :scalability do
  let(:worker_name) { 'Chaos::SleepWorker' }

  describe '.limits_for' do
    context 'when the worker name cannot be constantized' do
      let(:worker_name) { 'invalidworker' }

      it 'returns empty array' do
        expect(described_class.limits_for(worker_name)).to eq([])
      end
    end

    context 'when the worker does not extend ApplicationWorker' do
      let(:worker_name) { 'ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper' }

      it 'returns empty array' do
        expect(described_class.limits_for(worker_name)).to eq([])
      end
    end

    context 'when the worker matches a rule selector' do
      let(:worker_name) { 'PipelineProcessWorker' }

      it 'returns limits' do
        limits = described_class.limits_for(worker_name)
        expect(limits.map(&:name)).to include(:main_db_duration_limit_per_worker, :ci_db_duration_limit_per_worker)
        expect(limits.map(&:threshold).uniq).to eq([3000])
      end
    end

    context 'when the worker is a generic worker' do
      it 'returns catchall limits' do
        limits = described_class.limits_for(worker_name)
        expect(limits.map(&:name)).to include(:main_db_duration_limit_per_worker, :ci_db_duration_limit_per_worker)
        expect(limits.map(&:threshold).uniq).to eq([1000])
      end
    end

    context 'when the worker does not match any selectors' do
      let(:rule) do
        {
          main_db_duration_limit_per_worker: {
            resource_key: 'db_main_duration_s',
            metadata: {
              db_config_name: 'main'
            },
            scopes: [
              'worker_name'
            ],
            rules: [
              {
                selector: Gitlab::SidekiqConfig::WorkerMatcher.new("worker_name=TestWorker"),
                threshold: 3000,
                interval: 60
              }
            ]
          }
        }
      end

      before do
        stub_const("#{described_class}::DEFAULT_SIDEKIQ_LIMITS", rule)
      end

      it 'returns no limits' do
        expect(described_class.limits_for(worker_name)).to be_empty
      end
    end
  end
end
