# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::SyncDashboardsWorker do
  include MetricsDashboardHelpers
  subject(:worker) { described_class.new }

  let(:project) { project_with_dashboard(dashboard_path) }
  let(:dashboard_path) { '.gitlab/dashboards/test.yml' }

  describe ".perform" do
    it 'imports metrics' do
      expect { worker.perform(project.id) }.to change(PrometheusMetric, :count).by(3)
    end

    it 'is idempotent' do
      2.times do
        worker.perform(project.id)
      end

      expect(PrometheusMetric.count).to eq(3)
    end
  end
end
