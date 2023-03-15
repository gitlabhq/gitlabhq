# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::SyncDashboardsWorker, feature_category: :metrics do
  include MetricsDashboardHelpers
  subject(:worker) { described_class.new }

  let(:project) { project_with_dashboard(dashboard_path) }
  let(:dashboard_path) { '.gitlab/dashboards/test.yml' }

  describe ".perform" do
    context 'with valid dashboard hash' do
      it 'imports metrics' do
        expect { worker.perform(project.id) }.to change { PrometheusMetric.count }.by(3)
      end

      it 'is idempotent' do
        2.times do
          worker.perform(project.id)
        end

        expect(PrometheusMetric.count).to eq(3)
      end
    end

    context 'with invalid dashboard hash' do
      before do
        allow_next_instance_of(Gitlab::Metrics::Dashboard::Importer) do |instance|
          allow(instance).to receive(:dashboard_hash).and_return({})
        end
      end

      it 'does not import metrics' do
        expect { worker.perform(project.id) }.not_to change { PrometheusMetric.count }
      end

      it 'does not raise an error' do
        expect { worker.perform(project.id) }.not_to raise_error
      end
    end
  end
end
