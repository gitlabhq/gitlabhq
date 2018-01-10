require 'spec_helper'

describe PrometheusMetric, type: :model do
  subject { build(:prometheus_metric) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:query) }
  it { is_expected.to validate_presence_of(:group) }

  describe '#group_text' do
    let!(:metric) { create(:prometheus_metric) }

    shared_examples 'group_text' do |group, text|
      subject { build(:prometheus_metric, group: group) }

      it "returns text #{text} for group #{group}" do
        expect(subject.group_text).to eq(text)
      end
    end

    it_behaves_like 'group_text', :business, 'Business metrics'
    it_behaves_like 'group_text', :response, 'Response metrics'
    it_behaves_like 'group_text', :system, 'System metrics'
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
