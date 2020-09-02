# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Importer do
  include MetricsDashboardHelpers

  let_it_be(:dashboard_path) { '.gitlab/dashboards/sample_dashboard.yml' }
  let_it_be(:project) { create(:project) }

  before do
    allow(subject).to receive(:dashboard_hash).and_return(dashboard_hash)
  end

  subject { described_class.new(dashboard_path, project) }

  describe '.execute' do
    context 'valid dashboard hash' do
      let(:dashboard_hash) { load_sample_dashboard }

      it 'imports metrics to database' do
        expect { subject.execute }
          .to change { PrometheusMetric.count }.from(0).to(3)
      end
    end

    context 'invalid dashboard hash' do
      let(:dashboard_hash) { {} }

      it 'returns false' do
        expect(subject.execute).to be(false)
      end
    end
  end

  describe '.execute!' do
    context 'valid dashboard hash' do
      let(:dashboard_hash) { load_sample_dashboard }

      it 'imports metrics to database' do
        expect { subject.execute }
          .to change { PrometheusMetric.count }.from(0).to(3)
      end
    end

    context 'invalid dashboard hash' do
      let(:dashboard_hash) { {} }

      it 'raises error' do
        expect { subject.execute! }.to raise_error(Gitlab::Metrics::Dashboard::Validator::Errors::SchemaValidationError,
          'root is missing required keys: dashboard, panel_groups')
      end
    end
  end
end
