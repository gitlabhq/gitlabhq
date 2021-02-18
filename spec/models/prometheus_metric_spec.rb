# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PrometheusMetric do
  using RSpec::Parameterized::TableSyntax

  subject { build(:prometheus_metric) }

  it_behaves_like 'having unique enum values'

  it { is_expected.to belong_to(:project) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:query) }
  it { is_expected.to validate_presence_of(:group) }
  it { is_expected.to validate_uniqueness_of(:identifier).scoped_to(:project_id).allow_nil }

  describe 'common metrics' do
    where(:common, :with_project, :result) do
      false | true | true
      false | false | false
      true  | true | false
      true  | false | true
    end

    with_them do
      before do
        subject.common = common
        subject.project = with_project ? build(:project) : nil
      end

      it { expect(subject.valid?).to eq(result) }
    end
  end

  describe '#query_series' do
    where(:legend, :type) do
      'Some other legend' | NilClass
      'Status Code'       | Array
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

    it_behaves_like 'group_title', :nginx_ingress_vts, 'Response metrics (NGINX Ingress VTS)'
    it_behaves_like 'group_title', :nginx_ingress, 'Response metrics (NGINX Ingress)'
    it_behaves_like 'group_title', :ha_proxy, 'Response metrics (HA Proxy)'
    it_behaves_like 'group_title', :aws_elb, 'Response metrics (AWS ELB)'
    it_behaves_like 'group_title', :nginx, 'Response metrics (NGINX)'
    it_behaves_like 'group_title', :kubernetes, 'System metrics (Kubernetes)'
    it_behaves_like 'group_title', :business, 'Business metrics (Custom)'
    it_behaves_like 'group_title', :response, 'Response metrics (Custom)'
    it_behaves_like 'group_title', :system, 'System metrics (Custom)'
    it_behaves_like 'group_title', :cluster_health, 'Cluster Health'
  end

  describe '#priority' do
    where(:group, :priority) do
      :nginx_ingress_vts | 10
      :nginx_ingress     | 10
      :ha_proxy          | 10
      :aws_elb           | 10
      :nginx             | 10
      :kubernetes        | 5
      :business          | 0
      :response          | -5
      :system            | -10
      :cluster_health    | 10
    end

    with_them do
      before do
        subject.group = group
      end

      it { expect(subject.priority).to eq(priority) }
    end
  end

  describe '#required_metrics' do
    where(:group, :required_metrics) do
      :nginx_ingress_vts | %w(nginx_upstream_responses_total nginx_upstream_response_msecs_avg)
      :nginx_ingress     | %w(nginx_ingress_controller_requests nginx_ingress_controller_ingress_upstream_latency_seconds_sum)
      :ha_proxy          | %w(haproxy_frontend_http_requests_total haproxy_frontend_http_responses_total)
      :aws_elb           | %w(aws_elb_request_count_sum aws_elb_latency_average aws_elb_httpcode_backend_5_xx_sum)
      :nginx             | %w(nginx_server_requests nginx_server_requestMsec)
      :kubernetes        | %w(container_memory_usage_bytes container_cpu_usage_seconds_total)
      :business          | %w()
      :response          | %w()
      :system            | %w()
      :cluster_health    | %w(container_memory_usage_bytes container_cpu_usage_seconds_total)
    end

    with_them do
      before do
        subject.group = group
      end

      it { expect(subject.required_metrics).to eq(required_metrics) }
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

  describe '#to_metric_hash' do
    it 'returns a hash suitable for inclusion on a metrics dashboard' do
      expected_output = {
        query_range: subject.query,
        unit: subject.unit,
        label: subject.legend,
        metric_id: subject.id
      }

      expect(subject.to_metric_hash).to eq(expected_output)
    end
  end
end
