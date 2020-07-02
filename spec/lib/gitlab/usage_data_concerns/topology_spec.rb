# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataConcerns::Topology do
  include UsageDataHelpers

  describe '#topology_usage_data' do
    subject { Class.new.extend(described_class).topology_usage_data }

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
            receive_node_memory_query,
            receive_node_cpu_count_query,
            receive_node_service_memory_rss_query,
            receive_node_service_memory_uss_query,
            receive_node_service_memory_pss_query,
            receive_node_service_process_count_query
          )

          expect(subject[:topology]).to eq({
            duration_s: 0,
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
        it 'removes the respective entries' do
          expect_prometheus_api_to(
            receive_node_memory_query(result: []),
            receive_node_cpu_count_query,
            receive_node_service_memory_rss_query(result: []),
            receive_node_service_memory_uss_query(result: []),
            receive_node_service_memory_pss_query,
            receive_node_service_process_count_query
          )

          expect(subject[:topology]).to eq({
            duration_s: 0,
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

      context 'and no results are found' do
        it 'does not report anything' do
          expect_prometheus_api_to receive(:query).at_least(:once).and_return({})

          expect(subject[:topology]).to eq({
            duration_s: 0,
            nodes: []
          })
        end
      end

      context 'and a connection error is raised' do
        it 'does not report anything' do
          expect_prometheus_api_to receive(:query).and_raise('Connection failed')

          expect(subject[:topology]).to eq({ duration_s: 0 })
        end
      end
    end

    context 'when embedded Prometheus server is disabled' do
      it 'does not report anything' do
        expect(Gitlab::Prometheus::Internal).to receive(:prometheus_enabled?).and_return(false)

        expect(subject[:topology]).to eq({ duration_s: 0 })
      end
    end
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
