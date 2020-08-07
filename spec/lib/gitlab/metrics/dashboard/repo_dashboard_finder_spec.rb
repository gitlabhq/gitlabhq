# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::RepoDashboardFinder do
  include MetricsDashboardHelpers

  let_it_be(:project) { create(:project) }

  describe '.list_dashboards' do
    it 'deletes dashboard cache entries' do
      cache = instance_double(Gitlab::Metrics::Dashboard::Cache)
      allow(Gitlab::Metrics::Dashboard::Cache).to receive(:for).and_return(cache)

      expect(cache).to receive(:delete_all!)

      described_class.list_dashboards(project)
    end

    it 'returns empty array when there are no dashboards' do
      expect(described_class.list_dashboards(project)).to eq([])
    end

    context 'when there are project dashboards available' do
      let_it_be(:dashboard_path) { '.gitlab/dashboards/test.yml' }
      let_it_be(:project) { project_with_dashboard(dashboard_path) }

      it 'returns the dashboard list' do
        expect(described_class.list_dashboards(project)).to contain_exactly(dashboard_path)
      end
    end
  end

  describe '.read_dashboard' do
    it 'raises error when dashboard does not exist' do
      dashboard_path = '.gitlab/dashboards/test.yml'

      expect { described_class.read_dashboard(project, dashboard_path) }.to raise_error(
        Gitlab::Metrics::Dashboard::Errors::NOT_FOUND_ERROR
      )
    end

    context 'when there are project dashboards available' do
      let_it_be(:dashboard_path) { '.gitlab/dashboards/test.yml' }
      let_it_be(:project) { project_with_dashboard(dashboard_path) }

      it 'reads dashboard' do
        expect(described_class.read_dashboard(project, dashboard_path)).to eq(
          fixture_file('lib/gitlab/metrics/dashboard/sample_dashboard.yml')
        )
      end
    end
  end
end
