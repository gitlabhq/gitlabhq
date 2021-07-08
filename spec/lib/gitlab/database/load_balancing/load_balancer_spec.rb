# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::LoadBalancer, :request_store do
  let(:pool) { Gitlab::Database.create_connection_pool(2) }
  let(:conflict_error) { Class.new(RuntimeError) }

  let(:lb) { described_class.new(%w(localhost localhost)) }

  before do
    allow(Gitlab::Database).to receive(:create_connection_pool)
      .and_return(pool)
    stub_const(
      'Gitlab::Database::LoadBalancing::LoadBalancer::PG::TRSerializationFailure',
      conflict_error
    )
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

  describe '#read' do
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
      allow(host).to receive(:query_cache_enabled).and_return(false)
      allow(host).to receive(:connection).and_return(connection)

      expect(host).to receive(:enable_query_cache!).once

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

    it 'uses the primary if no secondaries are available' do
      allow(lb).to receive(:connection_error?).and_return(true)

      expect(lb.host_list.hosts).to all(receive(:online?).and_return(false))

      expect(lb).to receive(:read_write).and_call_original

      expect { |b| lb.read(&b) }
        .to yield_with_args(ActiveRecord::Base.retrieve_connection)
    end
  end

  describe '#read_write' do
    it 'yields a connection for a write' do
      expect { |b| lb.read_write(&b) }
        .to yield_with_args(ActiveRecord::Base.retrieve_connection)
    end

    it 'uses a retry with exponential backoffs' do
      expect(lb).to receive(:retry_with_backoff).and_yield

      lb.read_write { 10 }
    end
  end

  describe '#db_role_for_connection' do
    context 'when the load balancer creates the connection with #read' do
      it 'returns :replica' do
        role = nil
        lb.read do |connection|
          role = lb.db_role_for_connection(connection)
        end

        expect(role).to be(:replica)
      end
    end

    context 'when the load balancer uses nested #read' do
      it 'returns :replica' do
        roles = []
        lb.read do |connection_1|
          lb.read do |connection_2|
            roles << lb.db_role_for_connection(connection_2)
          end
          roles << lb.db_role_for_connection(connection_1)
        end

        expect(roles).to eq([:replica, :replica])
      end
    end

    context 'when the load balancer creates the connection with #read_write' do
      it 'returns :primary' do
        role = nil
        lb.read_write do |connection|
          role = lb.db_role_for_connection(connection)
        end

        expect(role).to be(:primary)
      end
    end

    context 'when the load balancer uses nested #read_write' do
      it 'returns :primary' do
        roles = []
        lb.read_write do |connection_1|
          lb.read_write do |connection_2|
            roles << lb.db_role_for_connection(connection_2)
          end
          roles << lb.db_role_for_connection(connection_1)
        end

        expect(roles).to eq([:primary, :primary])
      end
    end

    context 'when the load balancer falls back the connection creation to primary' do
      it 'returns :primary' do
        allow(lb).to receive(:serialization_failure?).and_return(true)

        role = nil
        raised = 7 # 2 hosts = 6 retries

        lb.read do |connection|
          if raised > 0
            raised -= 1
            raise
          end

          role = lb.db_role_for_connection(connection)
        end

        expect(role).to be(:primary)
      end
    end

    context 'when the load balancer uses replica after recovery from a failure' do
      it 'returns :replica' do
        allow(lb).to receive(:connection_error?).and_return(true)

        role = nil
        raised = false

        lb.read do |connection|
          unless raised
            raised = true
            raise
          end

          role = lb.db_role_for_connection(connection)
        end

        expect(role).to be(:replica)
      end
    end

    context 'when the connection comes from a pool managed by the host list' do
      it 'returns :replica' do
        connection = double(:connection)
        allow(connection).to receive(:pool).and_return(lb.host_list.hosts.first.pool)

        expect(lb.db_role_for_connection(connection)).to be(:replica)
      end
    end

    context 'when the connection comes from the primary pool' do
      it 'returns :primary' do
        connection = double(:connection)
        allow(connection).to receive(:pool).and_return(ActiveRecord::Base.connection_pool)

        expect(lb.db_role_for_connection(connection)).to be(:primary)
      end
    end

    context 'when the connection does not come from any known pool' do
      it 'returns nil' do
        connection = double(:connection)
        pool = double(:connection_pool)
        allow(connection).to receive(:pool).and_return(pool)

        expect(lb.db_role_for_connection(connection)).to be(nil)
      end
    end
  end

  describe '#host' do
    it 'returns the secondary host to use' do
      expect(lb.host).to be_an_instance_of(Gitlab::Database::LoadBalancing::Host)
    end

    it 'stores the host in a thread-local variable' do
      RequestStore.delete(described_class::CACHE_KEY)
      RequestStore.delete(described_class::VALID_HOSTS_CACHE_KEY)

      expect(lb.host_list).to receive(:next).once.and_call_original

      lb.host
      lb.host
    end
  end

  describe '#release_host' do
    it 'releases the host and its connection' do
      host = lb.host

      expect(host).to receive(:disable_query_cache!)

      lb.release_host

      expect(RequestStore[described_class::CACHE_KEY]).to be_nil
      expect(RequestStore[described_class::VALID_HOSTS_CACHE_KEY]).to be_nil
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
  end

  describe '#connection_error?' do
    before do
      stub_const('Gitlab::Database::LoadBalancing::LoadBalancer::CONNECTION_ERRORS',
                 [NotImplementedError])
    end

    it 'returns true for a connection error' do
      error = NotImplementedError.new

      expect(lb.connection_error?(error)).to eq(true)
    end

    it 'returns true for a wrapped connection error' do
      wrapped = wrapped_exception(ActiveRecord::StatementInvalid, NotImplementedError)

      expect(lb.connection_error?(wrapped)).to eq(true)
    end

    it 'returns true for a wrapped connection error from a view' do
      wrapped = wrapped_exception(ActionView::Template::Error, NotImplementedError)

      expect(lb.connection_error?(wrapped)).to eq(true)
    end

    it 'returns true for deeply wrapped/nested errors' do
      top = twice_wrapped_exception(ActionView::Template::Error, ActiveRecord::StatementInvalid, NotImplementedError)

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

  describe '#select_caught_up_hosts' do
    let(:location) { 'AB/12345'}
    let(:hosts) { lb.host_list.hosts }
    let(:valid_host_list) { RequestStore[described_class::VALID_HOSTS_CACHE_KEY] }
    let(:valid_hosts) { valid_host_list.hosts }

    subject { lb.select_caught_up_hosts(location) }

    context 'when all replicas are caught up' do
      before do
        expect(hosts).to all(receive(:caught_up?).with(location).and_return(true))
      end

      it 'returns true and sets all hosts to valid' do
        expect(subject).to be true
        expect(valid_host_list).to be_a(Gitlab::Database::LoadBalancing::HostList)
        expect(valid_hosts).to contain_exactly(*hosts)
      end
    end

    context 'when none of the replicas are caught up' do
      before do
        expect(hosts).to all(receive(:caught_up?).with(location).and_return(false))
      end

      it 'returns false and does not set the valid hosts' do
        expect(subject).to be false
        expect(valid_host_list).to be_nil
      end
    end

    context 'when one of the replicas is caught up' do
      before do
        expect(hosts[0]).to receive(:caught_up?).with(location).and_return(false)
        expect(hosts[1]).to receive(:caught_up?).with(location).and_return(true)
      end

      it 'returns true and sets one host to valid' do
        expect(subject).to be true
        expect(valid_host_list).to be_a(Gitlab::Database::LoadBalancing::HostList)
        expect(valid_hosts).to contain_exactly(hosts[1])
      end

      it 'host always returns the caught-up replica' do
        subject

        3.times do
          expect(lb.host).to eq(hosts[1])
          RequestStore.delete(described_class::CACHE_KEY)
        end
      end
    end
  end

  describe '#select_up_to_date_host' do
    let(:location) { 'AB/12345'}
    let(:hosts) { lb.host_list.hosts }
    let(:set_host) { RequestStore[described_class::CACHE_KEY] }

    subject { lb.select_up_to_date_host(location) }

    context 'when none of the replicas are caught up' do
      before do
        expect(hosts).to all(receive(:caught_up?).with(location).and_return(false))
      end

      it 'returns false and does not update the host thread-local variable' do
        expect(subject).to be false
        expect(set_host).to be_nil
      end
    end

    context 'when any of the replicas is caught up' do
      before do
        # `allow` for non-caught up host, because we may not even check it, if will find the caught up one earlier
        allow(hosts[0]).to receive(:caught_up?).with(location).and_return(false)
        expect(hosts[1]).to receive(:caught_up?).with(location).and_return(true)
      end

      it 'returns true and sets host thread-local variable' do
        expect(subject).to be true
        expect(set_host).to eq(hosts[1])
      end
    end
  end
end
