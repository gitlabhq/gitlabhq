require 'spec_helper'

describe Gitlab::Prometheus::Queries::AdditionalMetricsQuery, lib: true do
  include Prometheus::AdditionalMetricsQueryHelper

  let(:metric_group_class) { Gitlab::Prometheus::MetricGroup }
  let(:metric_class) { Gitlab::Prometheus::Metric }

  let(:client) { double('prometheus_client') }
  let(:environment) { create(:environment, slug: 'environment-slug') }

  subject(:query_result) { described_class.new(client).query(environment.id) }


  context 'with one group where two metrics is found' do
    before do
      allow(metric_group_class).to receive(:all).and_return([simple_metric_group])
      allow(client).to receive(:label_values).and_return(metric_names)
    end

    context 'some querie return results' do
      before do
        expect(client).to receive(:query_range).with('query_range_a', any_args).and_return(query_range_result)
        expect(client).to receive(:query_range).with('query_range_b', any_args).and_return(query_range_result)
        expect(client).to receive(:query_range).with('query_range_empty', any_args).and_return([])
      end

      it 'return results only for queries with results' do
        puts query_result
        expected = {
          group: 'name',
          priority: 1,
          metrics:
            [
              {
                title: 'title', weight: nil, y_label: 'Values', queries:
                [
                  { query_range: 'query_range_a', result: query_range_result },
                  { query_range: 'query_range_b', label: 'label', unit: 'unit', result: query_range_result }
                ]
              }
            ]
        }

        expect(query_result).to eq([expected])
      end
    end
  end
end
