# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Importers::PrometheusMetrics do
  include MetricsDashboardHelpers

  describe '#execute' do
    let(:project) { create(:project) }
    let(:dashboard_path) { 'path/to/dashboard.yml' }
    let(:prometheus_adapter) { double('adapter', clear_prometheus_reactive_cache!: nil) }

    subject { described_class.new(dashboard_hash, project: project, dashboard_path: dashboard_path) }

    before do
      allow_next_instance_of(::Clusters::Applications::ScheduleUpdateService) do |update_service|
        allow(update_service).to receive(:execute)
      end
    end

    context 'valid dashboard' do
      let(:dashboard_hash) { load_sample_dashboard }

      context 'with all new metrics' do
        it 'creates PrometheusMetrics' do
          expect { subject.execute }.to change { PrometheusMetric.count }.by(3)
        end
      end

      context 'with existing metrics' do
        let(:existing_metric_attributes) do
          {
            project:        project,
            identifier:     'metric_b',
            title:          'overwrite',
            y_label:        'overwrite',
            query:          'overwrite',
            unit:           'overwrite',
            legend:         'overwrite',
            dashboard_path: dashboard_path
          }
        end

        let!(:existing_metric) do
          create(:prometheus_metric, existing_metric_attributes)
        end

        let!(:existing_alert) do
          alert = create(:prometheus_alert, project: project, prometheus_metric: existing_metric)
          existing_metric.prometheus_alerts << alert

          alert
        end

        it 'updates existing PrometheusMetrics' do
          subject.execute

          expect(existing_metric.reload.attributes.with_indifferent_access).to include({
            title:   'Super Chart B',
            y_label: 'y_label',
            query:   'query',
            unit:    'unit',
            legend:  'Legend Label'
          })
        end

        it 'creates new PrometheusMetrics' do
          expect { subject.execute }.to change { PrometheusMetric.count }.by(2)
        end

        it 'updates affected environments' do
          expect(::Clusters::Applications::ScheduleUpdateService).to receive(:new).with(
            existing_alert.environment.cluster_prometheus_adapter,
            project
          ).and_return(double('ScheduleUpdateService', execute: true))

          subject.execute
        end

        context 'with stale metrics' do
          let!(:stale_metric) do
            create(:prometheus_metric,
              project: project,
              identifier: 'stale_metric',
              dashboard_path: dashboard_path,
              group: 3
            )
          end

          let!(:stale_alert) do
            alert = create(:prometheus_alert, project: project, prometheus_metric: stale_metric)
            stale_metric.prometheus_alerts << alert

            alert
          end

          it 'updates existing PrometheusMetrics' do
            subject.execute

            expect(existing_metric.reload.attributes.with_indifferent_access).to include({
              title:   'Super Chart B',
              y_label: 'y_label',
              query:   'query',
              unit:    'unit',
              legend:  'Legend Label'
            })
          end

          it 'deletes stale metrics' do
            subject.execute

            expect { stale_metric.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end

          it 'deletes stale alert' do
            subject.execute

            expect { stale_alert.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end

          it 'updates affected environments' do
            expect(::Clusters::Applications::ScheduleUpdateService).to receive(:new).with(
              existing_alert.environment.cluster_prometheus_adapter,
              project
            ).and_return(double('ScheduleUpdateService', execute: true))

            subject.execute
          end
        end
      end
    end

    context 'invalid dashboard' do
      let(:dashboard_hash) { {} }

      it 'returns false' do
        expect(subject.execute).to eq(false)
      end
    end
  end
end
