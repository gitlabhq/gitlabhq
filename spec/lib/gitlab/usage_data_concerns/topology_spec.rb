# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageDataConcerns::Topology do
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

      it 'contains a topology element' do
        allow_prometheus_queries

        expect(subject).to have_key(:topology)
      end

      context 'tracking node metrics' do
        it 'contains node level metrics for each instance' do
          expect_prometheus_api_to(
            receive_node_memory_query,
            receive_node_cpu_count_query,
            receive_node_service_memory_query,
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
                    name: 'gitlab_rails',
                    process_count: 10,
                    process_memory_rss: 300,
                    process_memory_uss: 301,
                    process_memory_pss: 302
                  },
                  {
                    name: 'gitlab_sidekiq',
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
                    name: 'gitlab_sidekiq',
                    process_count: 15,
                    process_memory_rss: 400,
                    process_memory_pss: 401
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
            receive_node_service_memory_query,
            receive_node_service_process_count_query
          )

          keys = subject[:topology][:nodes].flat_map(&:keys)
          expect(keys).not_to include(:node_memory_total_bytes)
          expect(keys).to include(:node_cpus, :node_services)
        end
      end

      context 'and no results are found' do
        it 'does not report anything' do
          expect_prometheus_api_to receive(:aggregate).at_least(:once).and_return({})

          expect(subject[:topology]).to eq({
            duration_s: 0,
            nodes: []
          })
        end
      end

      context 'and a connection error is raised' do
        it 'does not report anything' do
          expect_prometheus_api_to receive(:aggregate).and_raise('Connection failed')

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
      .with('avg (node_memory_MemTotal_bytes) by (instance)', an_instance_of(Hash))
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
      .with('count (node_cpu_seconds_total{mode="idle"}) by (instance)', an_instance_of(Hash))
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

  def receive_node_service_memory_query(result: nil)
    receive(:query)
      .with('avg ({__name__=~"ruby_process_(resident|unique|proportional)_memory_bytes"}) by (instance, job, __name__)', an_instance_of(Hash))
      .and_return(result || [
        # instance 1: runs Puma + a small Sidekiq
        {
          'metric' => { 'instance' => 'instance1:8080', 'job' => 'gitlab-rails', '__name__' => 'ruby_process_resident_memory_bytes' },
          'value' =>  [1000, '300']
        },
        {
          'metric' => { 'instance' => 'instance1:8080', 'job' => 'gitlab-rails', '__name__' => 'ruby_process_unique_memory_bytes' },
          'value' => [1000, '301']
        },
        {
          'metric' => { 'instance' => 'instance1:8080', 'job' => 'gitlab-rails', '__name__' => 'ruby_process_proportional_memory_bytes' },
          'value' => [1000, '302']
        },
        {
          'metric' => { 'instance' => 'instance1:8090', 'job' => 'gitlab-sidekiq', '__name__' => 'ruby_process_resident_memory_bytes' },
          'value' => [1000, '303']
        },
        # instance 2: runs a dedicated Sidekiq
        {
          'metric' => { 'instance' => 'instance2:8090', 'job' => 'gitlab-sidekiq', '__name__' => 'ruby_process_resident_memory_bytes' },
          'value' => [1000, '400']
        },
        {
          'metric' => { 'instance' => 'instance2:8090', 'job' => 'gitlab-sidekiq', '__name__' => 'ruby_process_proportional_memory_bytes' },
          'value' => [1000, '401']
        }
      ])
  end

  def receive_node_service_process_count_query(result: nil)
    receive(:query)
      .with('count (ruby_process_start_time_seconds) by (instance, job)', an_instance_of(Hash))
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
        }
      ])
  end
end
