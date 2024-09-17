# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::ServiceDiscovery, feature_category: :database do
  let(:load_balancer) do
    configuration = Gitlab::Database::LoadBalancing::Configuration.new(ActiveRecord::Base)
    configuration.service_discovery[:record] = 'localhost'

    Gitlab::Database::LoadBalancing::LoadBalancer.new(configuration)
  end

  let(:service) do
    described_class.new(
      load_balancer,
      nameserver: 'localhost',
      port: 8600,
      record: 'foo',
      disconnect_timeout: 1 # Short disconnect timeout to keep tests fast
    )
  end

  before do
    resource = double(:resource, address: IPAddr.new('127.0.0.1'))
    packet = double(:packet, answer: [resource])

    service.instance_variable_set(:@nameserver_ttl, Gitlab::Database::LoadBalancing::Resolver::FAR_FUTURE_TTL)

    allow(Net::DNS::Resolver).to receive(:start)
                                   .with('localhost', Net::DNS::A)
                                   .and_return(packet)
  end

  describe '#initialize' do
    describe ':record_type' do
      subject do
        described_class.new(
          load_balancer,
          nameserver: 'localhost',
          port: 8600,
          record: 'foo',
          record_type: record_type
        )
      end

      context 'with a supported type' do
        let(:record_type) { 'SRV' }

        it { expect(subject.record_type).to eq Net::DNS::SRV }
      end

      context 'with an unsupported type' do
        let(:record_type) { 'AAAA' }

        it 'raises an argument error' do
          expect { subject }.to raise_error(ArgumentError, 'Unsupported record type: AAAA')
        end
      end
    end
  end

  describe '#start', :freeze_time do
    before do
      allow(service)
        .to receive(:loop)
              .and_yield
    end

    it 'starts service discovery in a new thread with proper assignments' do
      expect(Thread).to receive(:new).ordered.and_call_original # Thread starts

      expect(service).to receive(:perform_service_discovery).ordered.and_return(5)
      expect(service).to receive(:rand).ordered.and_return(2)
      expect(service).to receive(:sleep).ordered.with(7) # Sleep runs after thread starts

      service.start.join

      expect(service.refresh_thread_last_run).to eq(Time.current)
      expect(service.refresh_thread).to be_present
    end
  end

  describe '#perform_service_discovery' do
    context 'without any failures' do
      it 'runs once' do
        expect(service)
          .to receive(:refresh_if_necessary).once

        expect(service).not_to receive(:sleep)

        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        service.perform_service_discovery
      end
    end

    context 'with StandardError' do
      before do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
        allow(service).to receive(:sleep)
      end

      let(:valid_retry_sleep_duration) { satisfy { |val| described_class::RETRY_DELAY_RANGE.include?(val) } }

      it 'retries service discovery when under the retry limit' do
        error = StandardError.new

        expect(service)
          .to receive(:refresh_if_necessary)
                .and_raise(error).exactly(described_class::MAX_DISCOVERY_RETRIES - 1).times.ordered

        expect(service)
          .to receive(:sleep).with(valid_retry_sleep_duration)
                             .exactly(described_class::MAX_DISCOVERY_RETRIES - 1).times

        expect(service).to receive(:refresh_if_necessary).and_return(45).ordered

        expect(service.perform_service_discovery).to eq(45)
      end

      it 'does not retry service discovery after exceeding the limit' do
        error = StandardError.new

        expect(service)
          .to receive(:refresh_if_necessary)
                .and_raise(error).exactly(described_class::MAX_DISCOVERY_RETRIES).times

        expect(service)
          .to receive(:sleep).with(valid_retry_sleep_duration)
                             .exactly(described_class::MAX_DISCOVERY_RETRIES).times

        service.perform_service_discovery
      end

      it 'reports exceptions to Sentry' do
        error = StandardError.new

        expect(service)
          .to receive(:refresh_if_necessary)
                .and_raise(error).exactly(described_class::MAX_DISCOVERY_RETRIES).times

        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception)
                .with(error).exactly(described_class::MAX_DISCOVERY_RETRIES).times

        service.perform_service_discovery
      end
    end
  end

  describe '#refresh_if_necessary' do
    let(:address_foo) { described_class::Address.new('foo') }
    let(:address_bar) { described_class::Address.new('bar') }

    context 'when a refresh is necessary' do
      before do
        allow(service)
          .to receive(:addresses_from_load_balancer)
                .and_return(%w[localhost])

        allow(service)
          .to receive(:addresses_from_dns)
                .and_return([10, [address_foo, address_bar]])
      end

      it 'refreshes the load balancer hosts' do
        expect(service)
          .to receive(:replace_hosts)
                .with([address_foo, address_bar])

        expect(service.refresh_if_necessary).to eq(10)
      end
    end

    context 'when a refresh is not necessary' do
      before do
        allow(service)
          .to receive(:addresses_from_load_balancer)
                .and_return(%w[localhost])

        allow(service)
          .to receive(:addresses_from_dns)
                .and_return([10, %w[localhost]])
      end

      it 'does not refresh the load balancer hosts' do
        expect(service)
          .not_to receive(:replace_hosts)

        expect(service.refresh_if_necessary).to eq(10)
      end
    end
  end

  describe '#replace_hosts' do
    before do
      allow(service)
        .to receive(:load_balancer)
              .and_return(load_balancer)
    end

    let(:address_foo) { described_class::Address.new('foo') }
    let(:address_bar) { described_class::Address.new('bar') }

    let(:load_balancer) do
      Gitlab::Database::LoadBalancing::LoadBalancer.new(
        Gitlab::Database::LoadBalancing::Configuration
          .new(ActiveRecord::Base, [address_foo])
      )
    end

    it 'replaces the hosts of the load balancer' do
      service.replace_hosts([address_bar])

      expect(load_balancer.host_list.host_names_and_ports).to eq([['bar', nil]])
    end

    it 'disconnects the old connections gracefully if possible' do
      host = load_balancer.host_list.hosts.first

      allow(service)
        .to receive(:disconnect_timeout)
              .and_return(2)

      expect(host)
        .to receive(:try_disconnect).and_return(true)

      expect(host).not_to receive(:force_disconnect!)

      service.replace_hosts([address_bar])
    end

    it 'disconnects the old connections forcefully if necessary' do
      host = load_balancer.host_list.hosts.first

      allow(service)
        .to receive(:disconnect_timeout)
              .and_return(2)

      expect(host)
        .to receive(:try_disconnect).and_return(false)

      expect(host).to receive(:force_disconnect!)

      service.replace_hosts([address_bar])
    end

    context 'without old hosts' do
      before do
        allow(load_balancer.host_list).to receive(:hosts).and_return([])
      end

      it 'does not log any load balancing event' do
        expect(::Gitlab::Database::LoadBalancing::Logger).not_to receive(:info)

        service.replace_hosts([address_foo, address_bar])
      end
    end
  end

  describe '#addresses_from_dns' do
    let(:service) do
      described_class.new(
        load_balancer,
        nameserver: 'localhost',
        port: 8600,
        record: 'foo',
        record_type: record_type,
        max_replica_pools: max_replica_pools
      )
    end

    let(:max_replica_pools) { nil }

    let(:packet) { double(:packet, answer: [res1, res2]) }

    before do
      allow(service.resolver)
        .to receive(:search)
              .with('foo', described_class::RECORD_TYPES[record_type])
              .and_return(packet)
    end

    context 'with an A record' do
      let(:record_type) { 'A' }

      let(:res1) { double(:resource, address: IPAddr.new('255.255.255.0'), ttl: 90) }
      let(:res2) { double(:resource, address: IPAddr.new('127.0.0.1'), ttl: 90) }

      it 'returns a TTL and ordered list of IP addresses' do
        addresses = [
          described_class::Address.new('127.0.0.1'),
          described_class::Address.new('255.255.255.0')
        ]

        expect(service.addresses_from_dns).to eq([90, addresses])
      end
    end

    context 'with an SRV record' do
      let(:record_type) { 'SRV' }

      let(:res1) { double(:resource, host: 'foo1.service.consul.', port: 5432, weight: 1, priority: 1, ttl: 90) }
      let(:res2) { double(:resource, host: 'foo2.service.consul.', port: 5433, weight: 1, priority: 1, ttl: 90) }
      let(:res3) { double(:resource, host: 'foo3.service.consul.', port: 5434, weight: 1, priority: 1, ttl: 90) }
      let(:res4) { double(:resource, host: 'foo4.service.consul.', port: 5432, weight: 1, priority: 1, ttl: 90) }
      let(:packet) { double(:packet, answer: [res1, res2, res3, res4], additional: []) }

      before do
        expect_next_instance_of(Gitlab::Database::LoadBalancing::SrvResolver) do |resolver|
          allow(resolver).to receive(:address_for).with('foo1.service.consul.').and_return(IPAddr.new('255.255.255.0'))
          allow(resolver).to receive(:address_for).with('foo2.service.consul.').and_return(IPAddr.new('127.0.0.1'))
          allow(resolver).to receive(:address_for).with('foo3.service.consul.').and_return(nil)
          allow(resolver).to receive(:address_for).with('foo4.service.consul.').and_return("127.0.0.2")
        end
      end

      it 'returns a TTL and ordered list of hosts' do
        addresses = [
          described_class::Address.new('127.0.0.1', 5433),
          described_class::Address.new('127.0.0.2', 5432),
          described_class::Address.new('255.255.255.0', 5432)
        ]

        expect(service.addresses_from_dns).to eq([90, addresses])
      end

      context 'when max_replica_pools is set' do
        context 'when the number of addresses exceeds max_replica_pools' do
          let(:max_replica_pools) { 2 }

          it 'limits to max_replica_pools' do
            expect(service.addresses_from_dns[1].count).to eq(2)
          end
        end

        context 'when the number of addresses is less than max_replica_pools' do
          let(:max_replica_pools) { 5 }

          it 'returns all addresses' do
            addresses = [
              described_class::Address.new('127.0.0.1', 5433),
              described_class::Address.new('127.0.0.2', 5432),
              described_class::Address.new('255.255.255.0', 5432)
            ]

            expect(service.addresses_from_dns).to eq([90, addresses])
          end
        end
      end
    end

    context 'when the resolver returns an empty response' do
      let(:packet) { double(:packet, answer: []) }

      let(:record_type) { 'A' }

      it 'raises EmptyDnsResponse' do
        expect { service.addresses_from_dns }.to raise_error(Gitlab::Database::LoadBalancing::ServiceDiscovery::EmptyDnsResponse)
      end
    end
  end

  describe '#new_wait_time_for' do
    it 'returns the DNS TTL if greater than the default interval' do
      res = double(:resource, ttl: 90)

      expect(service.new_wait_time_for([res])).to eq(90)
    end

    it 'returns the default interval if greater than the DNS TTL' do
      res = double(:resource, ttl: 10)

      expect(service.new_wait_time_for([res])).to eq(60)
    end

    it 'returns the default interval if no resources are given' do
      expect(service.new_wait_time_for([])).to eq(60)
    end
  end

  describe '#addresses_from_load_balancer' do
    let(:load_balancer) do
      Gitlab::Database::LoadBalancing::LoadBalancer.new(
        Gitlab::Database::LoadBalancing::Configuration
          .new(ActiveRecord::Base, %w[b a])
      )
    end

    it 'returns the ordered host names of the load balancer' do
      addresses = [
        described_class::Address.new('a'),
        described_class::Address.new('b')
      ]

      expect(service.addresses_from_load_balancer).to eq(addresses)
    end
  end

  describe '#resolver', :freeze_time do
    context 'without predefined resolver' do
      it 'fetches a new resolver and assigns it to the instance variable' do
        expect(service.instance_variable_get(:@resolver)).not_to be_present

        service_resolver = service.resolver

        expect(service.instance_variable_get(:@resolver)).to be_present
        expect(service_resolver).to be_present
      end
    end

    context 'with predefined resolver' do
      let(:resolver) do
        Net::DNS::Resolver.new(
          nameservers: 'localhost',
          port: 8600
        )
      end

      before do
        service.instance_variable_set(:@resolver, resolver)
      end

      context "when nameserver's TTL is in the future" do
        it 'returns the existing resolver' do
          expect(service.resolver).to eq(resolver)
        end
      end

      context "when nameserver's TTL is in the past" do
        before do
          service.instance_variable_set(
            :@nameserver_ttl,
            1.minute.ago
          )
        end

        it 'fetches new resolver' do
          service_resolver = service.resolver

          expect(service_resolver).to be_present
          expect(service_resolver).not_to eq(resolver)
        end
      end
    end
  end

  describe '#log_refresh_thread_interruption' do
    before do
      service.refresh_thread = refresh_thread
      service.refresh_thread_last_run = last_run_timestamp
    end

    let(:refresh_thread) { nil }
    let(:last_run_timestamp) { nil }

    subject { service.log_refresh_thread_interruption }

    context 'without refresh thread timestamp' do
      it 'does not log any interruption' do
        expect(service.refresh_thread_last_run).to be_nil

        expect(Gitlab::Database::LoadBalancing::Logger).not_to receive(:error)

        subject
      end
    end

    context 'with refresh thread timestamp' do
      let(:last_run_timestamp) { Time.current }

      it 'does not log if last run time plus delta is in future' do
        expect(Gitlab::Database::LoadBalancing::Logger).not_to receive(:error)

        subject
      end

      context 'with way past last run timestamp' do
        let(:refresh_thread) { instance_double(Thread, status: :run, backtrace: %w[backtrace foo]) }
        let(:last_run_timestamp) { 20.minutes.before + described_class::DISCOVERY_THREAD_REFRESH_DELTA.minutes }

        it 'does not log if the interruption is already logged' do
          service.refresh_thread_interruption_logged = true

          expect(Gitlab::Database::LoadBalancing::Logger).not_to receive(:error)

          subject
        end

        it 'logs the error if the interruption was not logged before' do
          expect(service.refresh_thread_interruption_logged).not_to be_present

          expect(Gitlab::Database::LoadBalancing::Logger).to receive(:error).with(
            event: :service_discovery_refresh_thread_interrupt,
            refresh_thread_last_run: last_run_timestamp,
            thread_status: refresh_thread.status.to_s,
            thread_backtrace: 'backtrace\nfoo'
          )

          subject

          expect(service.refresh_thread_interruption_logged).to be_truthy
        end
      end
    end
  end

  context 'with service discovery connected to a real load balancer' do
    let(:database_address) do
      host, port = ApplicationRecord.connection_pool.db_config.configuration_hash.fetch(:host, :port)
      described_class::Address.new(host, port)
    end

    before do
      # set up the load balancer to point to the test postgres instance with three seperate conections
      allow(service).to receive(:addresses_from_dns)
                          .and_return([Gitlab::Database::LoadBalancing::Resolver::FAR_FUTURE_TTL,
                            [database_address, database_address, database_address]])
                          .once

      service.perform_service_discovery
    end

    it 'configures service discovery with three replicas' do
      expect(service.load_balancer.host_list.hosts.count).to eq(3)
    end

    it 'swaps the hosts out gracefully when not contended' do
      expect(service.load_balancer.host_list.hosts.count).to eq(3)

      host = service.load_balancer.host_list.next

      # Check out and use a connection from a host so that there is something to clean up
      host.pool.with_connection do |connection|
        expect { connection.execute('select 1') }.not_to raise_error
      end

      allow(service).to receive(:addresses_from_dns).and_return([Gitlab::Database::LoadBalancing::Resolver::FAR_FUTURE_TTL, []])

      service.load_balancer.host_list.hosts.each do |h|
        # Expect that the host gets gracefully disconnected
        expect(h).not_to receive(:force_disconnect!)
      end

      gentle_disconnected_hosts = service.load_balancer.host_list.hosts.map { |h| "#{h.host}:#{h.port}" }
      allow(::Gitlab::Database::LoadBalancing::Logger).to receive(:info).and_call_original
      expect(::Gitlab::Database::LoadBalancing::Logger).to receive(:info)
                                                             .with(hash_including(
                                                               event: :host_list_disconnection,
                                                               gentle_disconnected_hosts: gentle_disconnected_hosts,
                                                               force_disconnected_hosts: []
                                                             ))
      expect { service.perform_service_discovery }.to change { host.pool.stat[:connections] }.from(1).to(0)
    end

    it 'swaps the hosts out forcefully when contended', :unlimited_max_formatted_output_length do
      host = service.load_balancer.host_list.next

      # Check out a connection and leave it checked out (simulate a web request)
      connection = host.pool.checkout
      connection.execute('select 1')

      # Expect that the connection is forcefully checked in
      expect(host).to receive(:force_disconnect!).and_call_original
      expect(connection).to receive(:steal!).and_call_original

      allow(service).to receive(:addresses_from_dns).and_return([Gitlab::Database::LoadBalancing::Resolver::FAR_FUTURE_TTL, []])
      allow(::Gitlab::Database::LoadBalancing::Logger).to receive(:info).and_call_original
      expect(::Gitlab::Database::LoadBalancing::Logger).to receive(:info)
                                                             .with(hash_including(
                                                               event: :host_list_disconnection,
                                                               force_disconnected_hosts: ["#{host.host}:#{host.port}"]
                                                             ))
      service.perform_service_discovery
    end
  end
end
