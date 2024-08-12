# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::Host, feature_category: :database do
  let(:load_balancer) do
    Gitlab::Database::LoadBalancing::LoadBalancer
      .new(Gitlab::Database::LoadBalancing::Configuration.new(ActiveRecord::Base))
  end

  let(:host) do
    described_class.new('localhost', load_balancer)
  end

  before do
    allow(load_balancer).to receive(:create_replica_connection_pool) do
      ActiveRecord::Base.connection_pool
    end
  end

  def raise_and_wrap(wrapper, original)
    raise original
  rescue original.class
    raise wrapper, 'boom'
  end

  def wrapped_exception(wrapper, original)
    raise_and_wrap(wrapper, original.new)
  rescue wrapper => error
    error
  end

  describe '#connection' do
    it 'returns a connection from the pool' do
      expect(host.pool).to receive(:connection)

      host.connection
    end
  end

  describe '#disconnect!' do
    it 'disconnects the pool' do
      connection = double(:connection, in_use?: false)
      pool = double(:pool, connections: [connection])

      allow(host)
        .to receive(:pool)
        .and_return(pool)

      expect(host)
        .not_to receive(:sleep)

      expect(host.pool)
        .to receive(:disconnect!)

      host.disconnect!
    end

    it 'disconnects the pool when waiting for connections takes too long' do
      connection = double(:connection, in_use?: true)
      pool = double(:pool, connections: [connection])

      allow(host)
        .to receive(:pool)
        .and_return(pool)

      expect(host.pool)
        .to receive(:disconnect!)

      host.disconnect!(timeout: 1)
    end
  end

  describe '#release_connection' do
    it 'releases the current connection from the pool' do
      expect(host.pool).to receive(:release_connection)

      host.release_connection
    end
  end

  describe '#offline!' do
    it 'marks the host as offline' do
      expect(host.pool).to receive(:disconnect!)

      expect(Gitlab::Database::LoadBalancing::Logger).to receive(:warn)
        .with(hash_including(event: :host_offline))
        .and_call_original

      host.offline!
    end
  end

  describe '#online?' do
    context 'when the replica status is recent enough' do
      before do
        expect(host).to receive(:check_replica_status?).and_return(false)
      end

      it 'returns the latest status' do
        expect(host).not_to receive(:refresh_status)
        expect(Gitlab::Database::LoadBalancing::Logger).not_to receive(:info)
        expect(Gitlab::Database::LoadBalancing::Logger).not_to receive(:warn)

        expect(host).to be_online
      end

      it 'returns an offline status' do
        host.offline!

        expect(host).not_to receive(:refresh_status)
        expect(Gitlab::Database::LoadBalancing::Logger).not_to receive(:info)
        expect(Gitlab::Database::LoadBalancing::Logger).not_to receive(:warn)

        expect(host).not_to be_online
      end
    end

    context 'when the replica status is outdated' do
      before do
        expect(host)
          .to receive(:check_replica_status?)
          .and_return(true)
      end

      it 'refreshes the status' do
        expect(host).to be_online
      end

      context 'and the host was previously online' do
        # Hosts are online by default

        it 'does not log the online event' do
          expect(Gitlab::Database::LoadBalancing::Logger)
            .not_to receive(:info)
            .with(hash_including(event: :host_online))

          expect(host).to be_online
        end
      end

      context 'and the host was previously offline' do
        before do
          host.offline!
        end

        it 'logs the online event' do
          expect(Gitlab::Database::LoadBalancing::Logger)
            .to receive(:info)
            .with(hash_including(event: :host_online))
            .and_call_original

          expect(host).to be_online
        end
      end

      context 'and replica is not up to date' do
        before do
          expect(host).to receive(:replica_is_up_to_date?).and_return(false)
        end

        it 'marks the host offline' do
          expect(Gitlab::Database::LoadBalancing::Logger).to receive(:warn)
            .with(hash_including(event: :host_offline))
            .and_call_original

          expect(host).not_to be_online
        end
      end
    end

    context 'when the replica is not online' do
      it 'returns false when ActionView::Template::Error is raised' do
        wrapped_error = wrapped_exception(ActionView::Template::Error, StandardError)

        allow(host)
          .to receive(:check_replica_status?)
          .and_raise(wrapped_error)

        expect(host).not_to be_online
      end

      it 'returns false when ActiveRecord::StatementInvalid is raised' do
        allow(host)
          .to receive(:check_replica_status?)
          .and_raise(ActiveRecord::StatementInvalid.new('foo'))

        expect(host).not_to be_online
      end

      it 'returns false when PG::Error is raised' do
        allow(host)
          .to receive(:check_replica_status?)
          .and_raise(PG::Error)

        expect(host).not_to be_online
      end

      it 'returns false when ActiveRecord::ConnectionNotEstablished is raised' do
        allow(host)
          .to receive(:check_replica_status?)
          .and_raise(ActiveRecord::ConnectionNotEstablished)

        expect(host).not_to be_online
      end
    end
  end

  describe '#refresh_status' do
    it 'refreshes the status' do
      host.offline!

      expect(host)
        .to receive(:replica_is_up_to_date?)
        .and_call_original

      host.refresh_status

      expect(host).to be_online
    end

    it 'clears the cache for latest_lsn_query' do
      allow(host).to receive(:replica_is_up_to_date?).and_return(true)

      expect(host)
        .to receive(:query_and_release)
        .with(described_class::CAN_TRACK_LOGICAL_LSN_QUERY)
        .twice
        .and_return({ 'allowed' => 't' }, { 'allowed' => 'f' })

      # Should receive LATEST_LSN_WITH_LOGICAL_QUERY twice even though we only
      # return 't' once above
      expect(host)
        .to receive(:query_and_release)
        .with(a_string_including(described_class::LATEST_LSN_WITH_LOGICAL_QUERY))
        .twice
        .and_call_original

      host.replication_lag_size
      host.replication_lag_size

      # Clear the cache for latest_lsn_query
      host.refresh_status

      # Should recieve LATEST_LSN_WITHOUT_LOGICAL_QUERY since we received 'f'
      # after clearing the cache
      expect(host)
        .to receive(:query_and_release)
        .with(a_string_including(described_class::LATEST_LSN_WITHOUT_LOGICAL_QUERY))
        .once
        .and_call_original

      host.replication_lag_size
    end
  end

  describe '#check_replica_status?' do
    it 'returns true when we need to check the replica status' do
      allow(host)
        .to receive(:last_checked_at)
        .and_return(1.year.ago)

      expect(host.check_replica_status?).to eq(true)
    end

    it 'returns false when we do not need to check the replica status' do
      freeze_time do
        allow(host)
          .to receive(:last_checked_at)
          .and_return(Time.zone.now)

        expect(host.check_replica_status?).to eq(false)
      end
    end
  end

  describe '#replica_is_up_to_date?' do
    context 'when the lag time is below the threshold' do
      it 'returns true' do
        expect(host)
          .to receive(:replication_lag_below_threshold?)
          .and_return(true)

        expect(host.replica_is_up_to_date?).to eq(true)
      end
    end

    context 'when the lag time exceeds the threshold' do
      before do
        allow(host)
          .to receive(:replication_lag_below_threshold?)
          .and_return(false)
      end

      it 'returns true if the data is recent enough' do
        expect(host)
          .to receive(:data_is_recent_enough?)
          .and_return(true)

        expect(host.replica_is_up_to_date?).to eq(true)
      end

      it 'returns false when the data is not recent enough' do
        expect(host)
          .to receive(:data_is_recent_enough?)
          .and_return(false)

        expect(host.replica_is_up_to_date?).to eq(false)
      end
    end
  end

  describe '#replication_lag_below_threshold' do
    let(:load_balancer_double_replication_lag_time) { false }
    let(:load_balancer_ignore_replication_lag_time) { false }

    before do
      stub_feature_flags(load_balancer_double_replication_lag_time: load_balancer_double_replication_lag_time)
      stub_feature_flags(load_balancer_ignore_replication_lag_time: load_balancer_ignore_replication_lag_time)
    end

    it 'returns true when the lag time is below the threshold' do
      expect(host)
        .to receive(:replication_lag_time)
        .and_return(1)

      expect(host.replication_lag_below_threshold?).to eq(true)
    end

    it 'returns false when the lag time exceeds the threshold' do
      expect(host)
        .to receive(:replication_lag_time)
        .and_return(9000)

      expect(host.replication_lag_below_threshold?).to eq(false)
    end

    it 'returns false when no lag time could be calculated' do
      expect(host)
        .to receive(:replication_lag_time)
        .and_return(nil)

      expect(host.replication_lag_below_threshold?).to eq(false)
    end

    context 'with the load_balancer_double_replication_lag_time feature flag enabled' do
      let(:load_balancer_double_replication_lag_time) { true }

      it 'returns false when lag time is above the higher threshold' do
        expect(host)
          .to receive(:replication_lag_time)
          .and_return(121)

        expect(host.replication_lag_below_threshold?).to eq(false)
      end

      it 'returns true when lag time is below the higher threshold' do
        expect(host)
          .to receive(:replication_lag_time)
          .and_return(119)

        expect(host.replication_lag_below_threshold?).to eq(true)
      end
    end

    context 'with the load_balancer_ignore_replication_lag_time feature flag enabled' do
      let(:load_balancer_ignore_replication_lag_time) { true }

      it 'returns true no matter how high the lag time is' do
        expect(host)
         .to receive(:replication_lag_time)
         .and_return(3600)

        expect(host.replication_lag_below_threshold?).to eq(true)
      end
    end
  end

  describe '#data_is_recent_enough?' do
    it 'returns true when the data is recent enough' do
      expect(host.data_is_recent_enough?).to eq(true)
    end

    it 'returns false when the data is not recent enough' do
      diff = load_balancer.configuration.max_replication_difference * 2

      expect(host)
        .to receive(:query_and_release)
        .with(described_class::CAN_TRACK_LOGICAL_LSN_QUERY)
        .and_call_original

      expect(host)
        .to receive(:query_and_release)
        .and_return({ 'diff' => diff })

      expect(host.data_is_recent_enough?).to eq(false)
    end

    it 'returns false when no lag size could be calculated' do
      expect(host)
        .to receive(:replication_lag_size)
        .and_return(nil)

      expect(host.data_is_recent_enough?).to eq(false)
    end
  end

  describe '#replication_lag_time' do
    it 'returns the lag time as a Float' do
      expect(host.replication_lag_time).to be_an_instance_of(Float)
    end

    it 'returns nil when the database query returned no rows' do
      expect(host)
        .to receive(:query_and_release)
        .and_return({})

      expect(host.replication_lag_time).to be_nil
    end
  end

  describe '#replication_lag_size' do
    it 'returns the lag size as an Integer' do
      expect(host.replication_lag_size).to be_an_instance_of(Integer)
    end

    it 'returns nil when the database query returned no rows' do
      expect(host)
        .to receive(:query_and_release)
        .with(described_class::CAN_TRACK_LOGICAL_LSN_QUERY)
        .and_call_original

      expect(host)
        .to receive(:query_and_release)
        .and_return({})

      expect(host.replication_lag_size).to be_nil
    end

    it 'returns nil when the database connection fails' do
      wrapped_error = wrapped_exception(ActionView::Template::Error, StandardError)

      allow(host)
        .to receive(:connection)
        .and_raise(wrapped_error)

      expect(host.replication_lag_size).to be_nil
    end

    context 'when can_track_logical_lsn? is false' do
      before do
        allow(host).to receive(:can_track_logical_lsn?).and_return(false)
      end

      it 'uses LATEST_LSN_WITHOUT_LOGICAL_QUERY' do
        expect(host)
          .to receive(:query_and_release)
          .with(a_string_including(described_class::LATEST_LSN_WITHOUT_LOGICAL_QUERY))
          .and_call_original

        expect(host.replication_lag_size('0/00000000')).to be_an_instance_of(Integer)
      end
    end

    context 'when can_track_logical_lsn? is true' do
      before do
        allow(host).to receive(:can_track_logical_lsn?).and_return(true)
      end

      it 'uses LATEST_LSN_WITH_LOGICAL_QUERY' do
        expect(host)
          .to receive(:query_and_release)
          .with(a_string_including(described_class::LATEST_LSN_WITH_LOGICAL_QUERY))
          .and_call_original

        expect(host.replication_lag_size('0/00000000')).to be_an_instance_of(Integer)
      end
    end

    context 'when CAN_TRACK_LOGICAL_LSN_QUERY raises connection errors' do
      before do
        expect(host)
          .to receive(:query_and_release)
          .with(described_class::CAN_TRACK_LOGICAL_LSN_QUERY)
          .and_raise(ActiveRecord::ConnectionNotEstablished)
      end

      it 'uses LATEST_LSN_WITHOUT_LOGICAL_QUERY' do
        expect(host)
          .to receive(:query_and_release)
          .with(a_string_including(described_class::LATEST_LSN_WITHOUT_LOGICAL_QUERY))
          .and_call_original

        expect(host.replication_lag_size('0/00000000')).to be_an_instance_of(Integer)
      end
    end
  end

  describe '#primary_write_location' do
    it 'returns the write location of the primary' do
      expect(host.primary_write_location).to be_an_instance_of(String)
      expect(host.primary_write_location).not_to be_empty
    end
  end

  describe '#caught_up?' do
    let(:connection) { double(:connection) }

    before do
      allow(connection).to receive(:quote).and_return('foo')
    end

    it 'returns true when a host has caught up' do
      allow(host).to receive(:connection).and_return(connection)

      expect(connection)
        .to receive(:select_all)
        .with(described_class::CAN_TRACK_LOGICAL_LSN_QUERY)
        .and_return([{ 'has_table_privilege' => 't' }])

      expect(connection)
        .to receive(:select_all)
        .and_return([{ 'diff' => -1 }])

      expect(host.caught_up?('foo')).to eq(true)
    end

    it 'returns false when diff query returns nothing' do
      allow(host).to receive(:connection).and_return(connection)

      expect(connection)
        .to receive(:select_all)
        .with(described_class::CAN_TRACK_LOGICAL_LSN_QUERY)
        .and_return([{ 'has_table_privilege' => 't' }])

      expect(connection).to receive(:select_all).and_return([])

      expect(host.caught_up?('foo')).to eq(false)
    end

    it 'returns false when a host has not caught up' do
      allow(host).to receive(:connection).and_return(connection)

      expect(connection)
        .to receive(:select_all)
        .with(described_class::CAN_TRACK_LOGICAL_LSN_QUERY)
        .and_return([{ 'has_table_privilege' => 't' }])

      expect(connection).to receive(:select_all).and_return([{ 'diff' => 123 }])

      expect(host.caught_up?('foo')).to eq(false)
    end

    it 'returns false when the connection fails' do
      wrapped_error = wrapped_exception(ActionView::Template::Error, StandardError)

      allow(host)
        .to receive(:connection)
        .and_raise(wrapped_error)

      expect(host.caught_up?('foo')).to eq(false)
    end
  end

  describe '#database_replica_location' do
    let(:connection) { double(:connection) }

    it 'returns the write ahead location of the replica', :aggregate_failures do
      expect(host)
        .to receive(:query_and_release)
              .and_return({ 'location' => '0/D525E3A8' })

      expect(host.database_replica_location).to be_an_instance_of(String)
    end

    it 'returns nil when the database query returned no rows' do
      expect(host)
        .to receive(:query_and_release)
              .and_return({})

      expect(host.database_replica_location).to be_nil
    end

    it 'returns nil when the database connection fails' do
      wrapped_error = wrapped_exception(ActionView::Template::Error, StandardError)

      allow(host)
        .to receive(:connection)
              .and_raise(wrapped_error)

      expect(host.database_replica_location).to be_nil
    end
  end

  describe '#query_and_release' do
    it 'executes a SQL query' do
      results = host.query_and_release('SELECT 10 AS number')

      expect(results).to be_an_instance_of(Hash)
      expect(results['number'].to_i).to eq(10)
    end

    it 'releases the connection after running the query' do
      expect(host)
        .to receive(:release_connection)
        .once

      host.query_and_release('SELECT 10 AS number')
    end

    it 'returns an empty Hash in the event of an error' do
      expect(host.connection)
        .to receive(:select_all)
        .and_raise(RuntimeError, 'kittens')

      expect(host.query_and_release('SELECT 10 AS number')).to eq({})
    end
  end

  describe '#host' do
    it 'returns the hostname' do
      expect(host.host).to eq('localhost')
    end
  end
end
