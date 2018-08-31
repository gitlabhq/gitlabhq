require 'rails_helper'

describe Gitlab::Prometheus::MetricGroup do
  describe '.common_metrics' do
    set(:project_metric) { create(:prometheus_metric) }
    set(:common_metric_group_a) { create(:prometheus_metric, :common, group: :aws_elb) }
    set(:common_metric_group_b_q1) { create(:prometheus_metric, :common, group: :kubernetes) }
    set(:common_metric_group_b_q2) { create(:prometheus_metric, :common, group: :kubernetes) }

    subject { described_class.common_metrics }

    it 'returns exactly two groups' do
      expect(subject.map(&:name)).to contain_exactly('Response metrics (AWS ELB)', 'System metrics (Kubernetes)')
    end

    it 'returns exactly three metric queries' do
      expect(subject.map(&:metrics).flatten.map(&:queries)).to contain_exactly(
        common_metric_group_a.queries, common_metric_group_b_q1.queries,
        common_metric_group_b_q2.queries)
    end
  end
end
