require 'spec_helper'

describe Gitlab::Prometheus::Queries::AdditionalMetricsQuery, lib: true do
  include Prometheus::AdditionalMetricsQueryHelper
  include Prometheus::MetricBuilders

  let(:metric_group_class) { Gitlab::Prometheus::MetricGroup }
  let(:metric_class) { Gitlab::Prometheus::Metric }

  let(:client) { double('prometheus_client') }
  let(:environment) { create(:environment, slug: 'environment-slug') }

  subject(:query_result) { described_class.new(client).query(environment.id) }

  around do |example|
    Timecop.freeze { example.run }
  end

  context 'with one group where two metrics is found' do
    before do
      allow(metric_group_class).to receive(:all).and_return([simple_metric_group])
      allow(client).to receive(:label_values).and_return(metric_names)
    end

    context 'some queries return results' do
      before do
        allow(client).to receive(:query_range).with('query_range_a', any_args).and_return(query_range_result)
        allow(client).to receive(:query_range).with('query_range_b', any_args).and_return(query_range_result)
        allow(client).to receive(:query_range).with('query_range_empty', any_args).and_return([])
      end

      it 'return group data only for queries with results' do
        expected = [
          {
            group: 'name',
            priority: 1,
            metrics: [
              {
                title: 'title', weight: nil, y_label: 'Values', queries: [
                { query_range: 'query_range_a', result: query_range_result },
                { query_range: 'query_range_b', label: 'label', unit: 'unit', result: query_range_result }
              ]
              }
            ]
          }
        ]

        expect(query_result).to eq(expected)
      end
    end
  end

  context 'with two groups with one metric each' do
    let(:metrics) { [simple_metric(queries: [simple_query])] }
    before do
      allow(metric_group_class).to receive(:all).and_return(
        [
          simple_metric_group('group_a', [simple_metric(queries: [simple_query])]),
          simple_metric_group('group_b', [simple_metric(title: 'title_b', queries: [simple_query('b')])])
        ])
      allow(client).to receive(:label_values).and_return(metric_names)
    end

    context 'both queries return results' do
      before do
        allow(client).to receive(:query_range).with('query_range_a', any_args).and_return(query_range_result)
        allow(client).to receive(:query_range).with('query_range_b', any_args).and_return(query_range_result)
      end

      it 'return group data both queries' do
        expected = [
          {
            group: 'group_a',
            priority: 1,
            metrics: [
              {
                title: 'title',
                weight: nil,
                y_label: 'Values',
                queries: [
                  {
                    query_range: 'query_range_a',
                    result: [
                      {
                        metric: {},
                        values: [[1488758662.506, '0.00002996364761904785'], [1488758722.506, '0.00003090239047619091']] }
                    ]
                  }
                ]
              }
            ]
          },
          {
            group: 'group_b',
            priority: 1,
            metrics: [
              {
                title: 'title_b',
                weight: nil,
                y_label: 'Values',
                queries: [
                  {
                    query_range: 'query_range_b', result: [
                    {
                      metric: {},
                      values: [[1488758662.506, '0.00002996364761904785'], [1488758722.506, '0.00003090239047619091']]
                    }
                  ]
                  }
                ]
              }
            ]
          }
        ]

        expect(query_result).to eq(expected)
      end
    end

    context 'one query returns result' do
      before do
        allow(client).to receive(:query_range).with('query_range_a', any_args).and_return(query_range_result)
        allow(client).to receive(:query_range).with('query_range_b', any_args).and_return([])
      end

      it 'queries using specific time' do
        expect(client).to receive(:query_range).with(anything, start: 8.hours.ago.to_f, stop: Time.now.to_f)

        expect(query_result).not_to be_nil
      end

      it 'return group data only for query with results' do
        expected = [
          {
            group: 'group_a',
            priority: 1,
            metrics: [
              {
                title: 'title',
                weight: nil,
                y_label: 'Values',
                queries: [
                  {
                    query_range: 'query_range_a',
                    result: query_range_result
                  }
                ]
              }
            ]
          }
        ]

        expect(query_result).to eq(expected)
      end
    end
  end
end
