# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::HostList do
  let(:db_host) { ActiveRecord::Base.connection_pool.db_config.host }
  let(:load_balancer) do
    Gitlab::Database::LoadBalancing::LoadBalancer.new(
      Gitlab::Database::LoadBalancing::Configuration.new(ActiveRecord::Base)
    )
  end

  let(:host_count) { 2 }
  let(:hosts) { Array.new(host_count) { Gitlab::Database::LoadBalancing::Host.new(db_host, load_balancer, port: 5432) } }
  let(:host_list) { described_class.new(hosts) }

  before do
    # each call generate a new replica pool
    allow(load_balancer).to receive(:create_replica_connection_pool) do
      double(:replica_connection_pool)
    end
  end

  describe '#initialize' do
    it 'sets metrics for current number of hosts and current index' do
      host_list

      expect_metrics(2)
    end
  end

  describe '#length' do
    it 'returns the number of hosts in the list' do
      expect(host_list.length).to eq(2)
    end
  end

  describe '#host_names_and_ports' do
    context 'with ports' do
      it 'returns the host names of all hosts' do
        hosts = [
          [db_host, 5432],
          [db_host, 5432]
        ]

        expect(host_list.host_names_and_ports).to eq(hosts)
      end
    end

    context 'without ports' do
      let(:hosts) { Array.new(2) { Gitlab::Database::LoadBalancing::Host.new(db_host, load_balancer) } }

      it 'returns the host names of all hosts' do
        hosts = [
          [db_host, nil],
          [db_host, nil]
        ]

        expect(host_list.host_names_and_ports).to eq(hosts)
      end
    end
  end

  describe '#hosts' do
    it 'returns a copy of the host' do
      first = host_list.hosts

      expect(host_list.hosts).to eq(first)
      expect(host_list.hosts.object_id).not_to eq(first.object_id)
    end
  end

  describe '#hosts=' do
    it 'updates the list of hosts to use' do
      host_list.hosts = [
        Gitlab::Database::LoadBalancing::Host.new('foo', load_balancer)
      ]

      expect(host_list.length).to eq(1)
      expect(host_list.hosts[0].host).to eq('foo')
      expect_metrics(1)
    end
  end

  describe '#next' do
    it 'returns a host' do
      expect(host_list.next)
        .to be_an_instance_of(Gitlab::Database::LoadBalancing::Host)
    end

    it 'cycles through all available hosts' do
      expect(host_list.next).to eq(host_list.hosts[0])
      expect_metrics(2)

      expect(host_list.next).to eq(host_list.hosts[1])
      expect_metrics(2)

      expect(host_list.next).to eq(host_list.hosts[0])
      expect_metrics(2)
    end

    it 'skips hosts that are offline' do
      allow(host_list.hosts[0]).to receive(:online?).and_return(false)

      expect(host_list.next).to eq(host_list.hosts[1])
      expect_metrics(2)
    end

    it 'returns nil if no hosts are online' do
      host_list.hosts.each do |host|
        allow(host).to receive(:online?).and_return(false)
      end

      expect(host_list.next).to be_nil
      expect_metrics(2)
    end

    it 'returns nil if no hosts are available' do
      expect(described_class.new.next).to be_nil
    end
  end

  describe '#shuffle' do
    let(:host_count) { 3 }

    it 'randomizes the list' do
      2.times do
        all_hosts = host_list.hosts

        host_list.shuffle

        expect(host_list.length).to eq(host_count)
        expect(host_list.hosts).to contain_exactly(*all_hosts)
      end
    end
  end

  def expect_metrics(hosts)
    expect(Gitlab::Metrics.registry.get(:db_load_balancing_hosts).get({})).to eq(hosts)
  end
end
