require 'spec_helper'

describe PrometheusMetric, type: :model do
  subject { build(:prometheus_metric) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:query) }
  it { is_expected.to validate_presence_of(:group) }

  describe '.to_grouped_query_metrics' do
    let!(:metric) { create(:prometheus_metric) }

    it 'Converts group id to group name' do
      group_name, = described_class.to_grouped_query_metrics[0]
      expect(group_name).to eq('Business metrics')
    end

    it 'Pairs group name with queryable metric objects' do
      _, metrics = described_class.to_grouped_query_metrics[0]
      expect(metrics.first).to be_instance_of(Gitlab::Prometheus::Metric)
    end
  end

  describe '#to_query_metric' do
    it 'converts to queryable metric object' do
      expect(subject.to_query_metric).to be_instance_of(Gitlab::Prometheus::Metric)
    end

    it 'queryable metric object has title' do
      expect(subject.to_query_metric.title).to eq(subject.title)
    end

    it 'queryable metric object has y_label' do
      expect(subject.to_query_metric.y_label).to eq(subject.y_label)
    end

    it 'queryable metric has no required_metric' do
      expect(subject.to_query_metric.required_metrics).to eq([])
    end

    it 'queryable metric has weight 0' do
      expect(subject.to_query_metric.weight).to eq(0)
    end

    it 'queryable metric has weight 0' do
      expect(subject.to_query_metric.weight).to eq(0)
    end

    it 'queryable metrics has query description' do
      queries = [
        {
          query_range: subject.query,
          unit: subject.unit,
          label: subject.legend
        }
      ]

      expect(subject.to_query_metric.queries).to eq(queries)
    end
  end
end
