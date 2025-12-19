# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::LoadBalancer, :request_store, feature_category: :database do
  let(:conflict_error) { Class.new(RuntimeError) }
  let(:model) { ActiveRecord::Base }
  let(:db_host) { model.connection_pool.db_config.host }
  let(:config) do
    Gitlab::Database::LoadBalancing::Configuration
      .new(model, [db_host, db_host])
  end

  let(:lb) { described_class.new(config) }
  let(:request_cache) { lb.send(:request_cache) }

  before do
    stub_const(
      'Gitlab::Database::LoadBalancing::LoadBalancer::PG::TRSerializationFailure',
      conflict_error
    )
  end

  after do |example|
    lb.disconnect!(timeout: 0) unless example.metadata[:skip_disconnect]
  end

  def raise_and_wrap(wrapper, original)
    raise original
  rescue original.class
    raise wrapper, 'boop'
  end

  def wrapped_exception(wrapper, original)
    raise_and_wrap(wrapper, original.new)
  rescue wrapper => error
    error
  end

  def twice_wrapped_exception(top, middle, original)
    begin
      raise_and_wrap(middle, original.new)
    rescue middle => middle_error
      raise_and_wrap(top, middle_error)
    end
  rescue top => top_error
    top_error
  end

  describe '#initialize' do
    it 'ignores the hosts when load balancing is disabled' do
      config = Gitlab::Database::LoadBalancing::Configuration
        .new(ActiveRecord::Base, [db_host])

      allow(config).to receive(:load_balancing_enabled?).and_return(false)

      lb = described_class.new(config)
      hosts = lb.host_list.hosts

      expect(hosts.length).to eq(1)
      expect(hosts.first)
        .to be_instance_of(Gitlab::Database::LoadBalancing::PrimaryHost)
    end

    it 'sets the name of the connection that is used' do
      config =
        Gitlab::Database::LoadBalancing::Configuration.new(ActiveRecord::Base)
      lb = described_class.new(config)

      expect(lb.name).to eq(:main)
    end
  end

  shared_examples 'logs service discovery thread interruption' do |lb_method|
    context 'with service discovery' do
      let(:service_discovery) do
        instance_double(
          Gitlab::Database::LoadBalancing::ServiceDiscovery,
          log_refresh_thread_interruption: true
        )
      end

      before do
        allow(lb).to receive(:service_discovery).and_return(service_discovery)
      end

      it 'calls logs service discovery thread interruption' do
        expect(service_discovery).to receive(:log_refresh_thread_interruption)

        lb.public_send(lb_method) {}
      end
    end
  end

  shared_examples 'restrict within concurrent ruby' do |lb_method|
    it 'raises an exception when running within a concurrent Ruby thread' do
      Thread.current[:restrict_within_concurrent_ruby] = true

      expect { |b| lb.public_send(lb_method, &b) }.to raise_error(Gitlab::Utils::ConcurrentRubyThreadIsUsedError,
        "Cannot run 'db' if running from `Concurrent::Promise`.")

      Thread.current[:restrict_within_concurrent_ruby] = nil
    end
  end

  describe '#read' do
    it_behaves_like 'logs service discovery thread interruption', :read
    it_behaves_like 'restrict within concurrent ruby', :read

    it 'yields a connection for a read' do
      connection = double(:connection)
      host = double(:host)

      allow(lb).to receive(:host).and_return(host)
      allow(host).to receive(:query_cache_enabled).and_return(true)

      expect(host).to receive(:connection).and_return(connection)

      expect { |b| lb.read(&b) }.to yield_with_args(connection)
    end

    it 'ensures that query cache is enabled' do
      connection = double(:connection)
      host = double(:host)

      allow(lb).to receive(:host).and_return(host)
      allow(Rails.application.executor).to receive(:active?).and_return(true)
      allow(host).to receive(:query_cache_enabled).and_return(false)
      allow(host).to receive(:connection).and_return(connection)

      expect(host).to receive(:enable_query_cache!).once

      lb.read { 10 }
    end

    it 'does not enable query cache when outside Rails executor context' do
      connection = double(:connection)
      host = double(:host)

      allow(lb).to receive(:host).and_return(host)
      allow(Rails.application.executor).to receive(:active?).and_return(false)
      allow(host).to receive(:query_cache_enabled).and_return(false)
      allow(host).to receive(:connection).and_return(connection)

      expect(host).not_to receive(:enable_query_cache!)

      lb.read { 10 }
    end

    it 'marks hosts that are offline' do
      allow(lb).to receive(:connection_error?).and_return(true)

      expect(lb.host_list.hosts[0]).to receive(:offline!)
      expect(lb).to receive(:release_host)

      raised = false

      returned = lb.read do
        unless raised
          raised = true
          raise
        end

        10
      end

      expect(returned).to eq(10)
    end

    it 'retries a query in the event of a serialization failure' do
      raised = false

      expect(lb).to receive(:release_host)

      returned = lb.read do
        unless raised
          raised = true
          raise conflict_error
        end

        10
      end

      expect(returned).to eq(10)
    end

    it 'retries every host at most 3 times when a query conflict is raised' do
      expect(lb).to receive(:release_host).exactly(6).times
      expect(lb).to receive(:read_write)

      lb.read { raise conflict_error }
    end

    context 'only primary is configured' do
      let(:lb) do
        config = Gitlab::Database::LoadBalancing::Configuration.new(ActiveRecord::Base)
        allow(config).to receive(:load_balancing_enabled?).and_return(false)

        described_class.new(config)
      end

      it 'does not retry a query on connection error if only the primary is configured' do
        host = double(:host, query_cache_enabled: true)

        allow(lb).to receive(:host).and_return(host)
        allow(host).to receive(:connection).and_raise(PG::UnableToSend)

        expect { lb.read }.to raise_error(PG::UnableToSend)
      end
    end

    it 'uses the primary if no secondaries are available' do
      allow(lb).to receive(:connection_error?).and_return(true)

      expect(lb.host_list.hosts).to all(receive(:online?).and_return(false))

      expect(lb).to receive(:read_write).and_call_original

      expect { |b| lb.read(&b) }
        .to yield_with_args(ActiveRecord::Base.retrieve_connection)
    end

    it 'uses the primary when load balancing is disabled' do
      config = Gitlab::Database::LoadBalancing::Configuration
        .new(ActiveRecord::Base)

      allow(config).to receive(:load_balancing_enabled?).and_return(false)

      lb = described_class.new(config)

      # When no hosts are configured, we don't want to produce any warnings, as
      # they aren't useful/too noisy.
      expect(Gitlab::Database::LoadBalancing::Logger).not_to receive(:warn)

      expect { |b| lb.read(&b) }
        .to yield_with_args(ActiveRecord::Base.retrieve_connection)
    end
  end

  describe '#read_write' do
    it_behaves_like 'logs service discovery thread interruption', :read_write
    it_behaves_like 'restrict within concurrent ruby', :read_write

    it 'yields a connection for a write' do
      connection = ActiveRecord::Base.connection_pool.connection

      expect { |b| lb.read_write(&b) }.to yield_with_args(connection)
    end

    it 'uses a retry with exponential backoffs' do
      expect(lb).to receive(:retry_with_backoff).and_yield(0)

      lb.read_write { 10 }
    end

    it 'does not raise NoMethodError error when primary_only?' do
      connection = ActiveRecord::Base.connection_pool.connection
      expected_error = Gitlab::Database::LoadBalancing::CONNECTION_ERRORS.first

      allow(lb).to receive(:primary_only?).and_return(true)

      expect do
        lb.read_write do
          connection.transaction do
            raise expected_error
          end
        end
      end.to raise_error(expected_error)
    end
  end

  describe '#host' do
    it 'returns the secondary host to use' do
      expect(lb.host).to be_an_instance_of(Gitlab::Database::LoadBalancing::Host)
    end

    it 'stores the host in a thread-local variable' do
      request_cache.delete(described_class::CACHE_KEY)

      expect(lb.host_list).to receive(:next).once.and_call_original

      lb.host
      lb.host
    end

    it 'does not create conflicts with other load balancers when caching hosts' do
      ci_config = Gitlab::Database::LoadBalancing::Configuration
        .new(Ci::ApplicationRecord, [db_host, db_host])

      lb1 = described_class.new(config)
      lb2 = described_class.new(ci_config)

      host1 = lb1.host
      host2 = lb2.host

      expect(lb1.send(:request_cache)[described_class::CACHE_KEY]).to eq(host1)
      expect(lb2.send(:request_cache)[described_class::CACHE_KEY]).to eq(host2)
    end
  end

  describe '#release_host' do
    it 'releases the host and its connection' do
      host = lb.host

      expect(host).to receive(:disable_query_cache!)

      lb.release_host

      expect(request_cache[described_class::CACHE_KEY]).to be_nil
    end
  end

  describe '#release_primary_connection' do
    it 'releases the connection to the primary' do
      expect(ActiveRecord::Base.connection_pool).to receive(:release_connection)

      lb.release_primary_connection
    end
  end

  describe '#primary_write_location' do
    it 'returns a String in the right format' do
      expect(lb.primary_write_location).to match(%r{[A-F0-9]{1,8}/[A-F0-9]{1,8}})
    end

    it 'raises an error if the write location could not be retrieved' do
      connection = double(:connection)

      allow(lb).to receive(:read_write).and_yield(connection)
      allow(connection).to receive(:select_all).and_return([])

      expect { lb.primary_write_location }.to raise_error(RuntimeError)
    end
  end

  describe '#retry_with_backoff' do
    it 'returns the value returned by the block' do
      value = lb.retry_with_backoff { 10 }

      expect(value).to eq(10)
    end

    it 're-raises errors not related to database connections' do
      expect(lb).not_to receive(:sleep) # to make sure we're not retrying

      expect { lb.retry_with_backoff { raise 'boop' } }
        .to raise_error(RuntimeError)
    end

    it 'retries the block when a connection error is raised' do
      allow(lb).to receive(:connection_error?).and_return(true)
      expect(lb).to receive(:sleep).with(2)
      expect(lb).to receive(:release_primary_connection)

      raised = false
      returned = lb.retry_with_backoff do
        unless raised
          raised = true
          raise
        end

        10
      end

      expect(returned).to eq(10)
    end

    it 're-raises the connection error if the retries did not succeed' do
      allow(lb).to receive(:connection_error?).and_return(true)
      expect(lb).to receive(:sleep).with(2).ordered
      expect(lb).to receive(:sleep).with(4).ordered
      expect(lb).to receive(:sleep).with(16).ordered

      expect(lb).to receive(:release_primary_connection).exactly(3).times

      expect { lb.retry_with_backoff { raise } }.to raise_error(RuntimeError)
    end

    it 'skips retries when only the primary is used' do
      allow(lb).to receive(:primary_only?).and_return(true)

      expect(lb).not_to receive(:sleep)

      expect { lb.retry_with_backoff { raise } }.to raise_error(RuntimeError)
    end

    it 'yields the current retry iteration' do
      allow(lb).to receive(:connection_error?).and_return(true)
      expect(lb).to receive(:release_primary_connection).exactly(3).times
      iterations = []

      # time: 0 so that we don't sleep and slow down the test
      # rubocop: disable Style/Semicolon
      expect { lb.retry_with_backoff(attempts: 3, time: 0) { |i| iterations << i; raise } }.to raise_error(RuntimeError)
      # rubocop: enable Style/Semicolon

      expect(iterations).to eq([1, 2, 3])
    end
  end

  describe '#connection_error?' do
    it 'returns true for a connection error' do
      error = ActiveRecord::ConnectionNotEstablished.new

      expect(lb.connection_error?(error)).to eq(true)
    end

    it 'returns false for a missing database error' do
      error = ActiveRecord::NoDatabaseError.new

      expect(lb.connection_error?(error)).to eq(false)
    end

    it 'returns true for a wrapped connection error' do
      wrapped = wrapped_exception(ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished)

      expect(lb.connection_error?(wrapped)).to eq(true)
    end

    it 'returns true for a wrapped connection error from a view' do
      wrapped = wrapped_exception(ActionView::Template::Error, ActiveRecord::ConnectionNotEstablished)

      expect(lb.connection_error?(wrapped)).to eq(true)
    end

    it 'returns true for deeply wrapped/nested errors' do
      top = twice_wrapped_exception(
        ActionView::Template::Error,
        ActiveRecord::StatementInvalid,
        ActiveRecord::ConnectionNotEstablished
      )

      expect(lb.connection_error?(top)).to eq(true)
    end

    it 'returns true for an invalid encoding error' do
      error = RuntimeError.new('invalid encoding name: unicode')

      expect(lb.connection_error?(error)).to eq(true)
    end

    it 'returns false for errors not related to database connections' do
      error = RuntimeError.new

      expect(lb.connection_error?(error)).to eq(false)
    end

    it 'returns false for ActiveRecord errors without a cause' do
      error = ActiveRecord::RecordNotUnique.new

      expect(lb.connection_error?(error)).to eq(false)
    end
  end

  describe '#serialization_failure?' do
    let(:conflict_error) { Class.new(RuntimeError) }

    before do
      stub_const(
        'Gitlab::Database::LoadBalancing::LoadBalancer::PG::TRSerializationFailure',
        conflict_error
      )
    end

    it 'returns for a serialization error' do
      expect(lb.serialization_failure?(conflict_error.new)).to eq(true)
    end

    it 'returns true for a wrapped error' do
      wrapped = wrapped_exception(ActionView::Template::Error, conflict_error)

      expect(lb.serialization_failure?(wrapped)).to eq(true)
    end
  end

  describe '#select_up_to_date_host' do
    let(:location) { 'AB/12345' }
    let(:hosts) { lb.host_list.hosts }
    let(:set_host) { request_cache[described_class::CACHE_KEY] }

    subject { lb.select_up_to_date_host(location) }

    context 'when none of the replicas are caught up' do
      before do
        expect(hosts[0]).to receive(:caught_up?).with(location).and_return(false)
        expect(hosts[1]).to receive(:caught_up?).with(location).and_return(false)
      end

      it 'returns NONE_CAUGHT_UP and does not update the host thread-local variable' do
        expect(subject).to eq(described_class::NONE_CAUGHT_UP)
        expect(set_host).to be_nil
      end

      it 'notifies caught_up_replica_pick.load_balancing with result false' do
        expect(ActiveSupport::Notifications).to receive(:instrument)
          .with('caught_up_replica_pick.load_balancing', { result: false })

        subject
      end
    end

    context 'when any replica is caught up' do
      before do
        expect(hosts[0]).to receive(:caught_up?).with(location).and_return(true)
        expect(hosts[1]).to receive(:caught_up?).with(location).and_return(false)
      end

      it 'returns ANY_CAUGHT_UP and sets host thread-local variable' do
        expect(subject).to eq(described_class::ANY_CAUGHT_UP)
        expect(set_host).to eq(hosts[0])
      end

      it 'notifies caught_up_replica_pick.load_balancing with result true' do
        expect(ActiveSupport::Notifications).to receive(:instrument)
          .with('caught_up_replica_pick.load_balancing', { result: true })

        subject
      end
    end

    context 'when all of the replicas is caught up' do
      before do
        expect(hosts[0]).to receive(:caught_up?).with(location).and_return(true)
        expect(hosts[1]).to receive(:caught_up?).with(location).and_return(true)
      end

      it 'returns ALL_CAUGHT_UP and sets host thread-local variable' do
        expect(subject).to eq(described_class::ALL_CAUGHT_UP)
        expect(set_host).to be_in([hosts[0], hosts[1]])
      end

      it 'notifies caught_up_replica_pick.load_balancing with result true' do
        expect(ActiveSupport::Notifications).to receive(:instrument)
          .with('caught_up_replica_pick.load_balancing', { result: true })

        subject
      end
    end
  end

  describe '#create_replica_connection_pool' do
    it 'creates a new connection pool with specific pool size and name' do
      with_replica_pool(5, 'other_host') do |replica_pool|
        expect(replica_pool)
          .to be_kind_of(ActiveRecord::ConnectionAdapters::ConnectionPool)

        expect(replica_pool.db_config.host).to eq('other_host')
        expect(replica_pool.db_config.pool).to eq(5)
        expect(replica_pool.db_config.name).to end_with("_replica")
      end
    end

    it 'allows setting of a custom hostname and port' do
      with_replica_pool(5, 'other_host', 5432) do |replica_pool|
        expect(replica_pool.db_config.host).to eq('other_host')
        expect(replica_pool.db_config.configuration_hash[:port]).to eq(5432)
      end
    end

    it 'does not modify connection class pool' do
      expect { with_replica_pool(5) {} }.not_to change { ActiveRecord::Base.connection_pool }
    end

    def with_replica_pool(*args)
      pool = lb.create_replica_connection_pool(*args)
      yield pool
    ensure
      pool&.disconnect!
    end
  end

  describe '#disconnect!' do
    it 'calls disconnect on all hosts with a timeout', :skip_disconnect do
      expect_next_instances_of(Gitlab::Database::LoadBalancing::Host, 2) do |host|
        expect(host).to receive(:disconnect!).with(timeout: 30)
      end

      lb.disconnect!(timeout: 30)
    end
  end

  describe '#get_write_location' do
    it 'returns a string' do
      expect(lb.send(:get_write_location, lb.pool.connection))
        .to be_a(String)
    end

    it 'returns nil if there are no results' do
      expect(lb.send(:get_write_location, double(select_all: []))).to be_nil
    end
  end

  describe '#wal_diff' do
    it 'returns the diff between two write locations' do
      loc1 = lb.send(:get_write_location, lb.pool.connection)

      create(:user) # This ensures we get a new WAL location

      loc2 = lb.send(:get_write_location, lb.pool.connection)
      diff = lb.wal_diff(loc2, loc1)

      expect(diff).to be_positive
    end
  end
end
