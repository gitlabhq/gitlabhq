# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PrometheusMetrics::ObserveHistogramsService do
  let_it_be(:project) { create(:project) }

  let(:params) { {} }

  subject(:execute) { described_class.new(project, params).execute }

  before do
    Gitlab::Metrics.reset_registry!
  end

  context 'with empty data' do
    it 'does not raise errors' do
      is_expected.to be_success
    end
  end

  context 'observes metrics successfully' do
    let(:params) do
      {
        histograms: [
          { name: 'pipeline_graph_link_calculation_duration_seconds', value: '1' },
          { name: 'pipeline_graph_links_per_job_ratio', value: '0.9' }
        ]
      }
    end

    it 'increments the metrics' do
      execute

      expect(histogram_data).to match(a_hash_including({ 0.8 => 0.0, 1 => 1.0, 2 => 1.0 }))

      expect(histogram_data(:pipeline_graph_links_per_job_ratio))
        .to match(a_hash_including({ 0.8 => 0.0, 0.9 => 1.0, 1 => 1.0 }))
    end

    it 'returns an empty body and status code' do
      is_expected.to be_success
      expect(subject.http_status).to eq(:created)
      expect(subject.payload).to eq({})
    end
  end

  context 'with unknown histograms' do
    let(:params) do
      { histograms: [{ name: 'chunky_bacon', value: '4' }] }
    end

    it 'raises ActiveRecord::RecordNotFound error' do
      expect { subject }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  def histogram_data(name = :pipeline_graph_link_calculation_duration_seconds)
    Gitlab::Metrics.registry.get(name)&.get({})
  end
end
