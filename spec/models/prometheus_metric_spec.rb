# frozen_string_literal: true

require 'spec_helper'

describe PrometheusMetric do
  subject { build(:prometheus_metric) }
  let(:other_project) { build(:project) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:query) }
  it { is_expected.to validate_presence_of(:group) }

  describe 'common metrics' do
    using RSpec::Parameterized::TableSyntax

    where(:common, :project, :result) do
      false | other_project | true
      false | nil           | false
      true  | other_project | false
      true  | nil           | true
    end

    with_them do
      before do
        subject.common = common
        subject.project = project
      end

      it { expect(subject.valid?).to eq(result) }
    end
  end

  describe '#query_series' do
    using RSpec::Parameterized::TableSyntax

    where(:legend, :type) do
      'Some other legend' | NilClass
      'Status Code'       | Hash
    end

    with_them do
      before do
        subject.legend = legend
      end

      it { expect(subject.query_series).to be_a(type) }
    end
  end

  describe '#group_title' do
    shared_examples 'group_title' do |group, title|
      subject { build(:prometheus_metric, group: group).group_title }

      it "returns text #{title} for group #{group}" do
        expect(subject).to eq(title)
      end
    end

    it_behaves_like 'group_title', :business, 'Business metrics (Custom)'
    it_behaves_like 'group_title', :response, 'Response metrics (Custom)'
    it_behaves_like 'group_title', :system, 'System metrics (Custom)'
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

    it 'queryable metrics has query description' do
      queries = [
        {
          query_range: subject.query,
          unit: subject.unit,
          label: subject.legend,
          series: nil
        }
      ]

      expect(subject.to_query_metric.queries).to eq(queries)
    end
  end
end
