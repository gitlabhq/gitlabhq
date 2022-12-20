# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ClientMetrics do
  let(:enqueued_jobs_metric) { double('enqueued jobs metric', increment: true) }

  shared_examples "a metrics middleware" do
    context "with mocked prometheus" do
      before do
        labels[:scheduling] = 'immediate'
        allow(Gitlab::Metrics).to receive(:counter).with(described_class::ENQUEUED, anything).and_return(enqueued_jobs_metric)
      end

      describe '#call' do
        it 'yields block' do
          expect { |b| subject.call(worker_class, job, :test, double, &b) }.to yield_control.once
        end

        it 'increments enqueued jobs metric with correct labels when worker is a string of the class' do
          expect(enqueued_jobs_metric).to receive(:increment).with(labels, 1)

          subject.call(worker_class.to_s, job, :test, double) { nil }
        end

        it 'increments enqueued jobs metric with correct labels' do
          expect(enqueued_jobs_metric).to receive(:increment).with(labels, 1)

          subject.call(worker_class, job, :test, double) { nil }
        end
      end
    end
  end

  it_behaves_like 'metrics middleware with worker attribution'

  context 'when mounted' do
    before do
      stub_const('TestWorker', Class.new)
      TestWorker.class_eval do
        include Sidekiq::Worker

        def perform(*args); end
      end

      allow(Gitlab::Metrics).to receive(:counter).and_return(Gitlab::Metrics::NullMetric.instance)
      allow(Gitlab::Metrics).to receive(:counter).with(described_class::ENQUEUED, anything).and_return(enqueued_jobs_metric)
    end

    context 'when scheduling jobs for immediate execution' do
      it 'increments enqueued jobs metric with scheduling label set to immediate' do
        expect(enqueued_jobs_metric).to receive(:increment).with(a_hash_including(scheduling: 'immediate'), 1)

        Sidekiq::Testing.inline! { TestWorker.perform_async }
      end
    end

    context 'when scheduling jobs for future execution' do
      it 'increments enqueued jobs metric with scheduling label set to delayed' do
        expect(enqueued_jobs_metric).to receive(:increment).with(a_hash_including(scheduling: 'delayed'), 1)

        Sidekiq::Testing.inline! { TestWorker.perform_in(1.second) }
      end

      it 'sets the scheduled_at field' do
        job = { 'at' => Time.current }

        subject.call('TestWorker', job, 'queue', nil) do
          expect(job[:scheduled_at]).to eq(job['at'])
        end
      end
    end

    context 'when the worker class cannot be found' do
      it 'increments enqueued jobs metric with the worker labels set to NilClass' do
        test_anonymous_worker = Class.new(TestWorker)

        expect(enqueued_jobs_metric).to receive(:increment).with(a_hash_including(worker: 'NilClass'), 1)

        # Sidekiq won't be able to create an instance of this class
        expect do
          Sidekiq::Testing.inline! { test_anonymous_worker.perform_async }
        end.to raise_error(NameError)
      end
    end
  end
end
