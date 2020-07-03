# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageData::Topology do
  include UsageDataHelpers

  describe '#topology_usage_data' do
    subject { described_class.new.topology_usage_data }

    before do
      # this pins down time shifts when benchmarking durations
      allow(Process).to receive(:clock_gettime).and_return(0)
    end

    context 'when embedded Prometheus server is enabled' do
      before do
        expect(Gitlab::Prometheus::Internal).to receive(:prometheus_enabled?).and_return(true)
        expect(Gitlab::Prometheus::Internal).to receive(:uri).and_return('http://prom:9090')
      end

      context 'tracking node metrics' do
        it 'contains node level metrics for each instance' do
          expect_prometheus_api_to(
            receive_app_request_volume_query,
            receive_node_memory_query,
            receive_node_cpu_count_query,
            receive_node_service_memory_rss_query,
            receive_node_service_memory_uss_query,
            receive_node_service_memory_pss_query,
            receive_node_service_process_count_query
          )

          expect(subject[:topology]).to eq({
            duration_s: 0,
            application_requests_per_hour: 36,
            failures: [],
            nodes: [
              {
                node_memory_total_bytes: 512,
                node_cpus: 8,
                node_services: [
                  {
                    name: 'web',
                    process_count: 10,
                    process_memory_rss: 300,
                    process_memory_uss: 301,
                    process_memory_pss: 302
                  },
                  {
                    name: 'sidekiq',
                    process_count: 5,
                    process_memory_rss: 303
                  }
                ]
              },
              {
                node_memory_total_bytes: 1024,
                node_cpus: 16,
                node_services: [
                  {
                    name: 'sidekiq',
                    process_count: 15,
                    process_memory_rss: 400,
                    process_memory_pss: 401
                  },
                  {
                    name: 'redis',
                    process_count: 1,
                    process_memory_rss: 402
                  }
                ]
              }
            ]
          })
        end
      end

      context 'and some node memory metrics are missing' do
        it 'removes the respective entries and includes the failures' do
          expect_prometheus_api_to(
            receive_app_request_volume_query(result: []),
            receive_node_memory_query(result: []),
            receive_node_cpu_count_query,
            receive_node_service_memory_rss_query(result: []),
            receive_node_service_memory_uss_query(result: []),
            receive_node_service_memory_pss_query,
            receive_node_service_process_count_query
          )

          expect(subject[:topology]).to eq({
            duration_s: 0,
            failures: [
              { 'app_requests' => 'empty_result' },
              { 'node_memory' => 'empty_result' },
              { 'service_rss' => 'empty_result' },
              { 'service_uss' => 'empty_result' }
            ],
            nodes: [
              {
                node_cpus: 16,
                node_services: [
                  {
                    name: 'sidekiq',
                    process_count: 15,
                    process_memory_pss: 401
                  },
                  {
                    name: 'redis',
                    process_count: 1
                  }
                ]
              },
              {
                node_cpus: 8,
                node_services: [
                  {
                    name: 'web',
                    process_count: 10,
                    process_memory_pss: 302
                  },
                  {
                    name: 'sidekiq',
                    process_count: 5
                  }
                ]
              }
            ]
          })
        end
      end

      context 'and an error is raised when querying Prometheus' do
        it 'returns empty result with failures' do
          expect_prometheus_api_to receive(:query)
            .at_least(:once)
            .and_raise(Gitlab::PrometheusClient::ConnectionError)

          expect(subject[:topology]).to eq({
            duration_s: 0,
            failures: [
              { 'app_requests' => 'Gitlab::PrometheusClient::ConnectionError' },
              { 'node_memory' => 'Gitlab::PrometheusClient::ConnectionError' },
              { 'node_cpus' => 'Gitlab::PrometheusClient::ConnectionError' },
              { 'service_rss' => 'Gitlab::PrometheusClient::ConnectionError' },
              { 'service_uss' => 'Gitlab::PrometheusClient::ConnectionError' },
              { 'service_pss' => 'Gitlab::PrometheusClient::ConnectionError' },
              { 'service_process_count' => 'Gitlab::PrometheusClient::ConnectionError' }
            ],
            nodes: []
          })
        end
      end
    end

    context 'when embedded Prometheus server is disabled' do
      it 'returns empty result with no failures' do
        expect(Gitlab::Prometheus::Internal).to receive(:prometheus_enabled?).and_return(false)

        expect(subject[:topology]).to eq({
          duration_s: 0,
          failures: []
        })
      end
    end

    context 'when top-level function raises error' do
      it 'returns empty result with generic failure' do
        allow(Gitlab::Prometheus::Internal).to receive(:prometheus_enabled?).and_raise(RuntimeError)

        expect(subject[:topology]).to eq({
          duration_s: 0,
          failures: [
            { 'other' => 'RuntimeError' }
          ]
        })
      end
    end
  end

  def receive_app_request_volume_query(result: nil)
    receive(:query)
      .with(/gitlab_usage_ping:ops:rate/)
      .and_return(result || [
        {
          'metric' => { 'component' => 'http_requests', 'service' => 'workhorse' },
          'value' => [1000, '0.01']
        }
      ])
  end

  def receive_node_memory_query(result: nil)
    receive(:query)
      .with(/node_memory_total_bytes/, an_instance_of(Hash))
      .and_return(result || [
        {
          'metric' => { 'instance' => 'instance1:8080' },
          'value' => [1000, '512']
        },
        {
          'metric' => { 'instance' => 'instance2:8090' },
          'value' => [1000, '1024']
        }
      ])
  end

  def receive_node_cpu_count_query(result: nil)
    receive(:query)
      .with(/node_cpus/, an_instance_of(Hash))
      .and_return(result || [
        {
          'metric' => { 'instance' => 'instance2:8090' },
          'value' => [1000, '16']
        },
        {
          'metric' => { 'instance' => 'instance1:8080' },
          'value' => [1000, '8']
        }
      ])
  end

  def receive_node_service_memory_rss_query(result: nil)
    receive(:query)
      .with(/process_resident_memory_bytes/, an_instance_of(Hash))
      .and_return(result || [
        {
          'metric' => { 'instance' => 'instance1:8080', 'job' => 'gitlab-rails' },
          'value' =>  [1000, '300']
        },
        {
          'metric' => { 'instance' => 'instance1:8090', 'job' => 'gitlab-sidekiq' },
          'value' => [1000, '303']
        },
        # instance 2: runs a dedicated Sidekiq + Redis (which uses a different metric name)
        {
          'metric' => { 'instance' => 'instance2:8090', 'job' => 'gitlab-sidekiq' },
          'value' => [1000, '400']
        },
        {
          'metric' => { 'instance' => 'instance2:9121', 'job' => 'redis' },
          'value' => [1000, '402']
        }
      ])
  end

  def receive_node_service_memory_uss_query(result: nil)
    receive(:query)
      .with(/process_unique_memory_bytes/, an_instance_of(Hash))
      .and_return(result || [
        {
          'metric' => { 'instance' => 'instance1:8080', 'job' => 'gitlab-rails' },
          'value' => [1000, '301']
        }
      ])
  end

  def receive_node_service_memory_pss_query(result: nil)
    receive(:query)
      .with(/process_proportional_memory_bytes/, an_instance_of(Hash))
      .and_return(result || [
        {
          'metric' => { 'instance' => 'instance1:8080', 'job' => 'gitlab-rails' },
          'value' => [1000, '302']
        },
        {
          'metric' => { 'instance' => 'instance2:8090', 'job' => 'gitlab-sidekiq' },
          'value' => [1000, '401']
        }
      ])
  end

  def receive_node_service_process_count_query(result: nil)
    receive(:query)
      .with(/service_process:count/, an_instance_of(Hash))
      .and_return(result || [
        # instance 1
        {
          'metric' => { 'instance' => 'instance1:8080', 'job' => 'gitlab-rails' },
          'value' => [1000, '10']
        },
        {
          'metric' => { 'instance' => 'instance1:8090', 'job' => 'gitlab-sidekiq' },
          'value' => [1000, '5']
        },
        # instance 2
        {
          'metric' => { 'instance' => 'instance2:8090', 'job' => 'gitlab-sidekiq' },
          'value' => [1000, '15']
        },
        {
          'metric' => { 'instance' => 'instance2:9121', 'job' => 'redis' },
          'value' => [1000, '1']
        },
        # unknown service => should be stripped out
        {
          'metric' => { 'instance' => 'instance2:9000', 'job' => 'not-a-gitlab-service' },
          'value' => [1000, '42']
        }
      ])
  end
end
