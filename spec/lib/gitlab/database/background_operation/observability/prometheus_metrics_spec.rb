# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundOperation::Observability::PrometheusMetrics, :prometheus, feature_category: :database do
  describe '#track' do
    subject(:prometheus_metrics) { described_class.new }

    let(:metrics) { {} }
    let(:labels) { job.worker.prometheus_labels }
    let(:summary_labels) { labels.merge(operation: 'update_all') }
    let(:job) do
      build(
        :background_operation_job,
        :succeeded,
        started_at: '2026-01-22 19:05:00 UTC',
        finished_at: '2026-01-22 19:06:00 UTC',
        metrics: metrics
      )
    end

    it 'reports batch_size' do
      prometheus_metrics.track(job)

      expect(metric_for_job_by_name(:gauge_batch_size)).to eq(job.batch_size)
    end

    it 'reports sub_batch_size' do
      prometheus_metrics.track(job)

      expect(metric_for_job_by_name(:gauge_sub_batch_size)).to eq(job.sub_batch_size)
    end

    it 'reports interval' do
      prometheus_metrics.track(job)

      expect(metric_for_job_by_name(:gauge_interval)).to eq(job.worker.interval)
    end

    it 'reports the total tuple count for the migration' do
      prometheus_metrics.track(job)

      expect(metric_for_job_by_name(:gauge_total_tuple_count)).to eq(job.worker.total_tuple_count.to_i)
    end

    it 'reports job duration' do
      freeze_time do
        prometheus_metrics.track(job)

        expect(metric_for_job_by_name(:gauge_job_duration)).to eq(1.minute)
      end
    end

    it 'increments updated tuples (currently based on batch_size)' do
      expect(described_class.metrics[:counter_updated_tuples]).to(
        receive(:increment).with(labels, job.batch_size).twice.and_call_original
      )

      prometheus_metrics.track(job)

      expect(metric_for_job_by_name(:counter_updated_tuples)).to eq(job.batch_size)

      prometheus_metrics.track(job)

      expect(metric_for_job_by_name(:counter_updated_tuples)).to eq(job.batch_size * 2)
    end

    it 'reports migrated tuples' do
      expect(job.worker).to receive(:migrated_tuple_count).and_return(20)

      prometheus_metrics.track(job)

      expect(metric_for_job_by_name(:gauge_migrated_tuples)).to eq(20)
    end

    context 'when the tracking record has timing metrics' do
      let(:metrics) { { 'timings' => { 'update_all' => [0.05, 0.2, 0.4, 0.9, 4] } } }

      it 'reports summary of query timings' do
        job.metrics['timings']['update_all'].each do |timing|
          expect(described_class.metrics[:histogram_timings]).to(
            receive(:observe).with(summary_labels, timing).and_call_original
          )
        end

        prometheus_metrics.track(job)

        expect(metric_for_job_by_name(:histogram_timings, job_labels: summary_labels)).to(
          eq({ 0.1 => 1.0, 0.25 => 2.0, 0.5 => 3.0, 1 => 4.0, 5 => 5.0 })
        )
      end
    end

    context 'when the tracking record does not having timing metrics' do
      it 'does not attempt to report query timings' do
        expect(described_class.metrics[:histogram_timings]).not_to receive(:observe)

        prometheus_metrics.track(job)
      end
    end

    def metric_for_job_by_name(name, job_labels: labels)
      described_class.metrics[name].values[job_labels].get
    end
  end
end
