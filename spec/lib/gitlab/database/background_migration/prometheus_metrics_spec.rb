# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::PrometheusMetrics, :prometheus do
  describe '#track' do
    let(:job_record) do
      build(
        :batched_background_migration_job,
        :succeeded,
        started_at: Time.current - 2.minutes,
        finished_at: Time.current - 1.minute,
        updated_at: Time.current,
        metrics: { 'timings' => { 'update_all' => [0.05, 0.2, 0.4, 0.9, 4] } }
      )
    end

    let(:labels) { job_record.batched_migration.prometheus_labels }

    subject(:track_job_record_metrics) { described_class.new.track(job_record) }

    it 'reports batch_size' do
      track_job_record_metrics

      expect(metric_for_job_by_name(:gauge_batch_size)).to eq(job_record.batch_size)
    end

    it 'reports sub_batch_size' do
      track_job_record_metrics

      expect(metric_for_job_by_name(:gauge_sub_batch_size)).to eq(job_record.sub_batch_size)
    end

    it 'reports interval' do
      track_job_record_metrics

      expect(metric_for_job_by_name(:gauge_interval)).to eq(job_record.batched_migration.interval)
    end

    it 'reports job duration' do
      freeze_time do
        track_job_record_metrics

        expect(metric_for_job_by_name(:gauge_job_duration)).to eq(1.minute)
      end
    end

    it 'increments updated tuples (currently based on batch_size)' do
      expect(described_class.metrics[:counter_updated_tuples]).to receive(:increment)
        .with(labels, job_record.batch_size)
        .twice
        .and_call_original

      track_job_record_metrics

      expect(metric_for_job_by_name(:counter_updated_tuples)).to eq(job_record.batch_size)

      described_class.new.track(job_record)

      expect(metric_for_job_by_name(:counter_updated_tuples)).to eq(job_record.batch_size * 2)
    end

    it 'reports migrated tuples' do
      expect(job_record.batched_migration).to receive(:migrated_tuple_count).and_return(20)

      track_job_record_metrics

      expect(metric_for_job_by_name(:gauge_migrated_tuples)).to eq(20)
    end

    it 'reports the total tuple count for the migration' do
      track_job_record_metrics

      expect(metric_for_job_by_name(:gauge_total_tuple_count)).to eq(job_record.batched_migration.total_tuple_count)
    end

    it 'reports last updated at timestamp' do
      freeze_time do
        track_job_record_metrics

        expect(metric_for_job_by_name(:gauge_last_update_time)).to eq(Time.current.to_i)
      end
    end

    it 'reports summary of query timings' do
      summary_labels = labels.merge(operation: 'update_all')

      job_record.metrics['timings']['update_all'].each do |timing|
        expect(described_class.metrics[:histogram_timings]).to receive(:observe)
          .with(summary_labels, timing)
          .and_call_original
      end

      track_job_record_metrics

      expect(metric_for_job_by_name(:histogram_timings, job_labels: summary_labels))
        .to eq({ 0.1 => 1.0, 0.25 => 2.0, 0.5 => 3.0, 1 => 4.0, 5 => 5.0 })
    end

    context 'when the tracking record does not having timing metrics' do
      before do
        job_record.metrics = {}
      end

      it 'does not attempt to report query timings' do
        summary_labels = labels.merge(operation: 'update_all')

        expect(described_class.metrics[:histogram_timings]).not_to receive(:observe)

        track_job_record_metrics

        expect(metric_for_job_by_name(:histogram_timings, job_labels: summary_labels))
          .to eq({ 0.1 => 0.0, 0.25 => 0.0, 0.5 => 0.0, 1 => 0.0, 5 => 0.0 })
      end
    end

    def metric_for_job_by_name(name, job_labels: labels)
      described_class.metrics[name].values[job_labels].get
    end
  end
end
