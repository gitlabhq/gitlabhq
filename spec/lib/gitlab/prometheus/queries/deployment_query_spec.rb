require 'spec_helper'

describe Gitlab::Prometheus::Queries::DeploymentQuery do
  let(:environment) { create(:environment, slug: 'environment-slug') }
  let(:deployment) { create(:deployment, environment: environment) }

  let(:client) { double('prometheus_client') }
  subject { described_class.new(client) }

  around do |example|
    time_without_subsecond_values = Time.local(2008, 9, 1, 12, 0, 0)
    Timecop.freeze(time_without_subsecond_values) { example.run }
  end

  it 'sends appropriate queries to prometheus' do
    start_time = (deployment.created_at - 30.minutes).to_f
    stop_time = (deployment.created_at + 30.minutes).to_f
    created_at = deployment.created_at.to_f

    expect(client).to receive(:query_range).with('avg(container_memory_usage_bytes{container_name!="POD",environment="environment-slug"}) / 2^20',
                                                 start: start_time, stop: stop_time)
    expect(client).to receive(:query).with('avg(avg_over_time(container_memory_usage_bytes{container_name!="POD",environment="environment-slug"}[30m]))',
                                           time: created_at)
    expect(client).to receive(:query).with('avg(avg_over_time(container_memory_usage_bytes{container_name!="POD",environment="environment-slug"}[30m]))',
                                           time: stop_time)

    expect(client).to receive(:query_range).with('avg(rate(container_cpu_usage_seconds_total{container_name!="POD",environment="environment-slug"}[2m])) * 100',
                                                 start: start_time, stop: stop_time)
    expect(client).to receive(:query).with('avg(rate(container_cpu_usage_seconds_total{container_name!="POD",environment="environment-slug"}[30m])) * 100',
                                           time: created_at)
    expect(client).to receive(:query).with('avg(rate(container_cpu_usage_seconds_total{container_name!="POD",environment="environment-slug"}[30m])) * 100',
                                           time: stop_time)

    expect(subject.query(deployment.id)).to eq(memory_values: nil, memory_before: nil, memory_after: nil,
                                               cpu_values: nil, cpu_before: nil, cpu_after: nil)
  end
end
