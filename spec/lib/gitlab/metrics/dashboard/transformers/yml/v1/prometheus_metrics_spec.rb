# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Transformers::Yml::V1::PrometheusMetrics do
  include MetricsDashboardHelpers

  describe '#execute' do
    subject { described_class.new(dashboard_hash) }

    context 'valid dashboard' do
      let_it_be(:dashboard_hash) do
        {
          panel_groups: [{
            panels: [
              {
                title: 'Panel 1 title',
                y_label: 'Panel 1 y_label',
                metrics: [
                  {
                    query_range: 'Panel 1 metric 1 query_range',
                    unit: 'Panel 1 metric 1 unit',
                    label: 'Panel 1 metric 1 label',
                    id: 'Panel 1 metric 1 id'
                  },
                  {
                    query: 'Panel 1 metric 2 query',
                    unit: 'Panel 1 metric 2 unit',
                    label: 'Panel 1 metric 2 label',
                    id: 'Panel 1 metric 2 id'
                  }
                ]
              },
              {
                title: 'Panel 2 title',
                y_label: 'Panel 2 y_label',
                metrics: [{
                  query_range: 'Panel 2 metric 1 query_range',
                  unit: 'Panel 2 metric 1 unit',
                  label: 'Panel 2 metric 1 label',
                  id: 'Panel 2 metric 1 id'
                }]
              }
            ]
          }]
        }
      end

      let(:expected_metrics) do
        [
          {
            title: 'Panel 1 title',
            y_label: 'Panel 1 y_label',
            query: "Panel 1 metric 1 query_range",
            unit: 'Panel 1 metric 1 unit',
            legend: 'Panel 1 metric 1 label',
            identifier: 'Panel 1 metric 1 id',
            group: 3,
            common: false
          },
          {
            title: 'Panel 1 title',
            y_label: 'Panel 1 y_label',
            query: 'Panel 1 metric 2 query',
            unit: 'Panel 1 metric 2 unit',
            legend: 'Panel 1 metric 2 label',
            identifier: 'Panel 1 metric 2 id',
            group: 3,
            common: false
          },
          {
            title: 'Panel 2 title',
            y_label: 'Panel 2 y_label',
            query: 'Panel 2 metric 1 query_range',
            unit: 'Panel 2 metric 1 unit',
            legend: 'Panel 2 metric 1 label',
            identifier: 'Panel 2 metric 1 id',
            group: 3,
            common: false
          }
        ]
      end

      it 'returns collection of metrics with correct attributes' do
        expect(subject.execute).to match_array(expected_metrics)
      end
    end

    context 'invalid dashboard' do
      let(:dashboard_hash) { {} }

      it 'raises missing attribute error' do
        expect { subject.execute }.to raise_error(
          ::Gitlab::Metrics::Dashboard::Transformers::Errors::MissingAttribute, "Missing attribute: 'panel_groups'"
        )
      end
    end
  end
end
