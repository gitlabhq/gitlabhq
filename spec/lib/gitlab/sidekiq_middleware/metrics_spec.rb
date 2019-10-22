# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqMiddleware::Metrics do
  let(:middleware) { described_class.new }

  let(:concurrency_metric) { double('concurrency metric') }
  let(:completion_seconds_metric) { double('completion seconds metric') }
  let(:user_execution_seconds_metric) { double('user execution seconds metric') }
  let(:failed_total_metric) { double('failed total metric') }
  let(:retried_total_metric) { double('retried total metric') }
  let(:running_jobs_metric) { double('running jobs metric') }

  before do
    allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_jobs_completion_seconds, anything, anything, anything).and_return(completion_seconds_metric)
    allow(Gitlab::Metrics).to receive(:histogram).with(:sidekiq_jobs_cpu_seconds, anything, anything, anything).and_return(user_execution_seconds_metric)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_jobs_failed_total, anything).and_return(failed_total_metric)
    allow(Gitlab::Metrics).to receive(:counter).with(:sidekiq_jobs_retried_total, anything).and_return(retried_total_metric)
    allow(Gitlab::Metrics).to receive(:gauge).with(:sidekiq_running_jobs, anything, {}, :all).and_return(running_jobs_metric)
    allow(Gitlab::Metrics).to receive(:gauge).with(:sidekiq_concurrency, anything, {}, :all).and_return(concurrency_metric)

    allow(running_jobs_metric).to receive(:increment)
    allow(concurrency_metric).to receive(:set)
  end

  describe '#initialize' do
    it 'sets general metrics' do
      expect(concurrency_metric).to receive(:set).with({}, Sidekiq.options[:concurrency].to_i)

      middleware
    end
  end

  describe '#call' do
    let(:worker) { double(:worker) }

    it 'yields block' do
      allow(completion_seconds_metric).to receive(:observe)
      allow(user_execution_seconds_metric).to receive(:observe)

      expect { |b| middleware.call(worker, {}, :test, &b) }.to yield_control.once
    end

    it 'sets queue specific metrics' do
      labels = { queue: :test }
      allow(middleware).to receive(:get_thread_cputime).and_return(1, 3)

      expect(user_execution_seconds_metric).to receive(:observe).with(labels, 2)
      expect(running_jobs_metric).to receive(:increment).with(labels, 1)
      expect(running_jobs_metric).to receive(:increment).with(labels, -1)
      expect(completion_seconds_metric).to receive(:observe).with(labels, kind_of(Numeric))

      middleware.call(worker, {}, :test) { nil }
    end

    it 'ignore user execution when measured 0' do
      allow(completion_seconds_metric).to receive(:observe)
      allow(middleware).to receive(:get_thread_cputime).and_return(0, 0)

      expect(user_execution_seconds_metric).not_to receive(:observe)
    end

    context 'when job is retried' do
      it 'sets sidekiq_jobs_retried_total metric' do
        allow(completion_seconds_metric).to receive(:observe)
        expect(user_execution_seconds_metric).to receive(:observe)

        expect(retried_total_metric).to receive(:increment)

        middleware.call(worker, { 'retry_count' => 1 }, :test) { nil }
      end
    end

    context 'when error is raised' do
      it 'sets sidekiq_jobs_failed_total and reraises' do
        expect(failed_total_metric).to receive(:increment)
        expect { middleware.call(worker, {}, :test) { raise } }.to raise_error
      end
    end
  end
end
