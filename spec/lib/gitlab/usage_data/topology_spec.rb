# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageData::Topology do
  include UsageDataHelpers

  describe '#topology_usage_data' do
    subject { topology.topology_usage_data }

    let(:topology) { described_class.new }
    let(:prometheus_client) { Gitlab::PrometheusClient.new('http://localhost:9090') }
    let(:fallback) { {} }

    before do
      # this pins down time shifts when benchmarking durations
      allow(Process).to receive(:clock_gettime).and_return(0)
    end

    shared_examples 'query topology data from Prometheus' do
      context 'tracking node metrics' do
        it 'contains node level metrics for each instance' do
          expect_prometheus_client_to(
            receive_app_request_volume_query,
            receive_query_apdex_ratio_query,
            receive_node_memory_query,
            receive_node_memory_utilization_query,
            receive_node_cpu_count_query,
            receive_node_cpu_utilization_query,
            receive_node_uname_info_query,
            receive_node_service_memory_rss_query,
            receive_node_service_memory_uss_query,
            receive_node_service_memory_pss_query,
            receive_node_service_process_count_query,
            receive_node_service_app_server_workers_query
          )

          expect(subject[:topology]).to eq({
            duration_s: 0,
            application_requests_per_hour: 36,
            query_apdex_weekly_average: 0.996,
            failures: [],
            nodes: [
              {
                node_memory_total_bytes: 512,
                node_memory_utilization: 0.45,
                node_cpus: 8,
                node_cpu_utilization: 0.1,
                node_uname_info: {
                  machine: 'x86_64',
                  sysname: 'Linux',
                  release: '4.19.76-linuxkit'
                },
                node_services: [
                  {
                    name: 'web',
                    process_count: 10,
                    process_memory_rss: 300,
                    process_memory_uss: 301,
                    process_memory_pss: 302,
                    server: 'puma'
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
                node_memory_utilization: 0.25,
                node_cpus: 16,
                node_cpu_utilization: 0.2,
                node_uname_info: {
                  machine: 'x86_64',
                  sysname: 'Linux',
                  release: '4.15.0-101-generic'
                },
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
                  },
                  {
                    name: 'registry',
                    process_count: 1
                  },
                  {
                    name: 'web',
                    server: 'puma'
                  }
                ]
              }
            ]
          })
        end
      end

      context 'and some node memory metrics are missing' do
        it 'removes the respective entries and includes the failures' do
          expect_prometheus_client_to(
            receive_app_request_volume_query(result: []),
            receive_query_apdex_ratio_query(result: []),
            receive_node_memory_query(result: []),
            receive_node_memory_utilization_query(result: []),
            receive_node_cpu_count_query,
            receive_node_cpu_utilization_query,
            receive_node_uname_info_query,
            receive_node_service_memory_rss_query(result: []),
            receive_node_service_memory_uss_query(result: []),
            receive_node_service_memory_pss_query,
            receive_node_service_process_count_query,
            receive_node_service_app_server_workers_query(result: [])
          )

          expect(subject[:topology]).to eq({
            duration_s: 0,
            failures: [
              { 'app_requests' => 'empty_result' },
              { 'query_apdex' => 'empty_result' },
              { 'node_memory' => 'empty_result' },
              { 'node_memory_utilization' => 'empty_result' },
              { 'service_rss' => 'empty_result' },
              { 'service_uss' => 'empty_result' },
              { 'service_workers' => 'empty_result' }
            ],
            nodes: [
              {
                node_cpus: 16,
                node_cpu_utilization: 0.2,
                node_uname_info: {
                  machine: 'x86_64',
                  release: '4.15.0-101-generic',
                  sysname: 'Linux'
                },
                node_services: [
                  {
                    name: 'sidekiq',
                    process_count: 15,
                    process_memory_pss: 401
                  },
                  {
                    name: 'redis',
                    process_count: 1
                  },
                  {
                    name: 'registry',
                    process_count: 1
                  }
                ]
              },
              {
                node_cpus: 8,
                node_cpu_utilization: 0.1,
                node_uname_info: {
                  machine: 'x86_64',
                  release: '4.19.76-linuxkit',
                  sysname: 'Linux'
                },
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

      context 'and services run on the same node but report different instance values' do
        let(:node_memory_response) do
          [
            {
              'metric' => { 'instance' => 'localhost:9100' },
              'value' => [1000, '512']
            }
          ]
        end

        let(:node_memory_utilization_response) do
          [
            {
              'metric' => { 'instance' => 'localhost:9100' },
              'value' => [1000, '0.35']
            }
          ]
        end

        let(:node_uname_info_response) do
          [
            {
              "metric" => {
                "__name__" => "node_uname_info",
                "domainname" => "(none)",
                "instance" => "127.0.0.1:9100",
                "job" => "node_exporter",
                "machine" => "x86_64",
                "nodename" => "127.0.0.1",
                "release" => "4.19.76-linuxkit",
                "sysname" => "Linux"
              },
              "value" => [1592463033.359, "1"]
            }
          ]
        end
        # The services in this response should all be mapped to localhost i.e. the same node

        let(:service_memory_response) do
          [
            {
              'metric' => { 'instance' => 'localhost:8080', 'job' => 'gitlab-rails' },
              'value' => [1000, '10']
            },
            {
              'metric' => { 'instance' => '127.0.0.1:8090', 'job' => 'gitlab-sidekiq' },
              'value' => [1000, '11']
            },
            {
              'metric' => { 'instance' => '0.0.0.0:9090', 'job' => 'prometheus' },
              'value' => [1000, '12']
            },
            {
              'metric' => { 'instance' => '[::1]:1234', 'job' => 'redis' },
              'value' => [1000, '13']
            },
            {
              'metric' => { 'instance' => '[::]:1234', 'job' => 'postgres' },
              'value' => [1000, '14']
            }
          ]
        end

        it 'normalizes equivalent instance values and maps them to the same node' do
          expect_prometheus_client_to(
            receive_app_request_volume_query(result: []),
            receive_query_apdex_ratio_query(result: []),
            receive_node_memory_query(result: node_memory_response),
            receive_node_memory_utilization_query(result: node_memory_utilization_response),
            receive_node_cpu_count_query(result: []),
            receive_node_cpu_utilization_query(result: []),
            receive_node_uname_info_query(result: node_uname_info_response),
            receive_node_service_memory_rss_query(result: service_memory_response),
            receive_node_service_memory_uss_query(result: []),
            receive_node_service_memory_pss_query(result: []),
            receive_node_service_process_count_query(result: []),
            receive_node_service_app_server_workers_query(result: [])
          )

          expect(subject[:topology]).to eq({
            duration_s: 0,
            failures: [
              { 'app_requests' => 'empty_result' },
              { 'query_apdex' => 'empty_result' },
              { 'node_cpus' => 'empty_result' },
              { 'node_cpu_utilization' => 'empty_result' },
              { 'service_uss' => 'empty_result' },
              { 'service_pss' => 'empty_result' },
              { 'service_process_count' => 'empty_result' },
              { 'service_workers' => 'empty_result' }
            ],
            nodes: [
              {
                node_memory_total_bytes: 512,
                node_memory_utilization: 0.35,
                node_uname_info: {
                  machine: 'x86_64',
                  sysname: 'Linux',
                  release: '4.19.76-linuxkit'
                },
                node_services: [
                  {
                    name: 'web',
                    process_memory_rss: 10
                  },
                  {
                    name: 'sidekiq',
                    process_memory_rss: 11
                  },
                  {
                    name: 'prometheus',
                    process_memory_rss: 12
                  },
                  {
                    name: 'redis',
                    process_memory_rss: 13
                  },
                  {
                    name: 'postgres',
                    process_memory_rss: 14
                  }
                ]
              }
            ]
          })
        end
      end

      context 'and node metrics are missing but service metrics exist' do
        it 'still reports service metrics' do
          expect_prometheus_client_to(
            receive_app_request_volume_query(result: []),
            receive_query_apdex_ratio_query(result: []),
            receive_node_memory_query(result: []),
            receive_node_memory_utilization_query(result: []),
            receive_node_cpu_count_query(result: []),
            receive_node_cpu_utilization_query(result: []),
            receive_node_uname_info_query(result: []),
            receive_node_service_memory_rss_query,
            receive_node_service_memory_uss_query(result: []),
            receive_node_service_memory_pss_query(result: []),
            receive_node_service_process_count_query(result: []),
            receive_node_service_app_server_workers_query(result: [])
          )

          expect(subject[:topology]).to eq({
            duration_s: 0,
            failures: [
              { 'app_requests' => 'empty_result' },
              { 'query_apdex' => 'empty_result' },
              { 'node_memory' => 'empty_result' },
              { 'node_memory_utilization' => 'empty_result' },
              { 'node_cpus' => 'empty_result' },
              { 'node_cpu_utilization' => 'empty_result' },
              { 'node_uname_info' => 'empty_result' },
              { 'service_uss' => 'empty_result' },
              { 'service_pss' => 'empty_result' },
              { 'service_process_count' => 'empty_result' },
              { 'service_workers' => 'empty_result' }
            ],
            nodes: [
              {
                node_services: [
                  {
                    name: 'web',
                    process_memory_rss: 300
                  },
                  {
                    name: 'sidekiq',
                    process_memory_rss: 303
                  }
                ]
              },
              {
                node_services: [
                  {
                    name: 'sidekiq',
                    process_memory_rss: 400
                  },
                  {
                    name: 'redis',
                    process_memory_rss: 402
                  }
                ]
              }
            ]
          })
        end
      end

      context 'and unknown services are encountered' do
        let(:unknown_service_process_count_response) do
          [
            {
              'metric' => { 'instance' => 'instance2:9000', 'job' => 'unknown-service-A' },
              'value' => [1000, '42']
            },
            {
              'metric' => { 'instance' => 'instance2:9001', 'job' => 'unknown-service-B' },
              'value' => [1000, '42']
            }
          ]
        end

        it 'filters out unknown service data and reports the unknown services as a failure' do
          expect_prometheus_client_to(
            receive_app_request_volume_query(result: []),
            receive_query_apdex_ratio_query(result: []),
            receive_node_memory_query(result: []),
            receive_node_memory_utilization_query(result: []),
            receive_node_cpu_count_query(result: []),
            receive_node_cpu_utilization_query(result: []),
            receive_node_uname_info_query(result: []),
            receive_node_service_memory_rss_query(result: []),
            receive_node_service_memory_uss_query(result: []),
            receive_node_service_memory_pss_query(result: []),
            receive_node_service_process_count_query(result: unknown_service_process_count_response),
            receive_node_service_app_server_workers_query(result: [])
          )

          expect(subject.dig(:topology, :failures)).to include(
            { 'service_unknown' => 'unknown-service-A' },
            { 'service_unknown' => 'unknown-service-B' }
          )
        end
      end

      context 'and an error is raised when querying Prometheus' do
        context 'without timeout failures' do
          it 'returns empty result and executes subsequent queries as usual' do
            expect_prometheus_client_to(
              receive(:query).at_least(:once).and_raise(Gitlab::PrometheusClient::UnexpectedResponseError)
            )

            expect(subject[:topology]).to eq({
              duration_s: 0,
              failures: [
                { 'app_requests' => 'Gitlab::PrometheusClient::UnexpectedResponseError' },
                { 'query_apdex' => 'Gitlab::PrometheusClient::UnexpectedResponseError' },
                { 'node_memory' => 'Gitlab::PrometheusClient::UnexpectedResponseError' },
                { 'node_memory_utilization' => 'Gitlab::PrometheusClient::UnexpectedResponseError' },
                { 'node_cpus' => 'Gitlab::PrometheusClient::UnexpectedResponseError' },
                { 'node_cpu_utilization' => 'Gitlab::PrometheusClient::UnexpectedResponseError' },
                { 'node_uname_info' => 'Gitlab::PrometheusClient::UnexpectedResponseError' },
                { 'service_rss' => 'Gitlab::PrometheusClient::UnexpectedResponseError' },
                { 'service_uss' => 'Gitlab::PrometheusClient::UnexpectedResponseError' },
                { 'service_pss' => 'Gitlab::PrometheusClient::UnexpectedResponseError' },
                { 'service_process_count' => 'Gitlab::PrometheusClient::UnexpectedResponseError' },
                { 'service_workers' => 'Gitlab::PrometheusClient::UnexpectedResponseError' }
              ],
              nodes: []
            })
          end
        end

        context 'with timeout failures' do
          where(:exception) do
            described_class::TIMEOUT_ERRORS
          end

          with_them do
            it 'returns empty result and cancelled subsequent queries' do
              expect_prometheus_client_to(
                receive(:query).and_raise(exception)
              )

              expect(subject[:topology]).to eq({
                duration_s: 0,
                failures: [
                  { 'app_requests' => exception.to_s },
                  { 'query_apdex' => 'timeout_cancellation' },
                  { 'node_memory' => 'timeout_cancellation' },
                  { 'node_memory_utilization' => 'timeout_cancellation' },
                  { 'node_cpus' => 'timeout_cancellation' },
                  { 'node_cpu_utilization' => 'timeout_cancellation' },
                  { 'node_uname_info' => 'timeout_cancellation' },
                  { 'service_rss' => 'timeout_cancellation' },
                  { 'service_uss' => 'timeout_cancellation' },
                  { 'service_pss' => 'timeout_cancellation' },
                  { 'service_process_count' => 'timeout_cancellation' },
                  { 'service_workers' => 'timeout_cancellation' }
                ],
                nodes: []
              })
            end
          end
        end
      end
    end

    shared_examples 'returns empty result with no failures' do
      it do
        expect(subject[:topology]).to eq({
          duration_s: 0,
          failures: []
        })
      end
    end

    context 'can reach a ready Prometheus client' do
      before do
        expect(topology).to receive(:with_prometheus_client).and_yield(prometheus_client)
      end

      it_behaves_like 'query topology data from Prometheus'
    end

    context 'can not reach a ready Prometheus client' do
      before do
        expect(topology).to receive(:with_prometheus_client).and_return(fallback)
      end

      it_behaves_like 'returns empty result with no failures'
    end

    context 'when top-level function raises error' do
      it 'returns empty result with generic failure' do
        expect(topology).to receive(:with_prometheus_client).and_raise(RuntimeError)

        expect(subject[:topology]).to eq({
          duration_s: 0,
          failures: [
            { 'other' => 'RuntimeError' }
          ]
        })
      end
    end
  end

  def receive_ready_check_query(result: nil, raise_error: nil)
    if raise_error.nil?
      receive(:ready?).and_return(result.nil? ? true : result)
    else
      receive(:ready?).and_raise(raise_error)
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

  def receive_query_apdex_ratio_query(result: nil)
    receive(:query)
      .with(/gitlab_usage_ping:sql_duration_apdex:ratio_rate5m/)
      .and_return(result || [
        {
          'metric' => {},
          'value' => [1000, '0.996']
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

  def receive_node_memory_utilization_query(result: nil)
    receive(:query)
      .with(/node_memory_utilization/, an_instance_of(Hash))
      .and_return(result || [
        {
          'metric' => { 'instance' => 'instance1:8080' },
          'value' => [1000, '0.45']
        },
                    {
                      'metric' => { 'instance' => 'instance2:8090' },
                      'value' => [1000, '0.25']
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

  def receive_node_cpu_utilization_query(result: nil)
    receive(:query)
      .with(/node_cpu_utilization/, an_instance_of(Hash))
      .and_return(result || [
        {
          'metric' => { 'instance' => 'instance2:8090' },
          'value' => [1000, '0.2']
        },
                    {
                      'metric' => { 'instance' => 'instance1:8080' },
                      'value' => [1000, '0.1']
                    }
      ])
  end

  def receive_node_uname_info_query(result: nil)
    receive(:query)
      .with('node_uname_info')
      .and_return(result || [
        {
          "metric" => {
            "__name__" => "node_uname_info",
            "domainname" => "(none)",
            "instance" => "instance1:9100",
            "job" => "node_exporter",
            "machine" => "x86_64",
            "nodename" => "instance1",
            "release" => "4.19.76-linuxkit",
            "sysname" => "Linux"
          },
          "value" => [1592463033.359, "1"]
        },
                    {
                      "metric" => {
                        "__name__" => "node_uname_info",
                        "domainname" => "(none)",
                        "instance" => "instance2:9100",
                        "job" => "node_exporter",
                        "machine" => "x86_64",
                        "nodename" => "instance2",
                        "release" => "4.15.0-101-generic",
                        "sysname" => "Linux"
                      },
                      "value" => [1592463033.359, "1"]
                    }
      ])
  end

  def receive_node_service_memory_rss_query(result: nil)
    receive(:query)
      .with(/process_resident_memory_bytes/, an_instance_of(Hash))
      .and_return(result || [
        {
          'metric' => { 'instance' => 'instance1:8080', 'job' => 'gitlab-rails' },
          'value' => [1000, '300']
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
                    {
                      'metric' => { 'instance' => 'instance2:8080', 'job' => 'registry' },
                      'value' => [1000, '1']
                    }
      ])
  end

  def receive_node_service_app_server_workers_query(result: nil)
    receive(:query)
      .with(/app_server_workers/, an_instance_of(Hash))
      .and_return(result || [
        # instance 1
        {
          'metric' => { 'instance' => 'instance1:8080', 'job' => 'gitlab-rails', 'server' => 'puma' },
          'value' => [1000, '2']
        },
                    # instance 2
                    {
                      'metric' => { 'instance' => 'instance2:8080', 'job' => 'gitlab-rails', 'server' => 'puma' },
                      'value' => [1000, '1']
                    }
      ])
  end
end
