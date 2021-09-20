# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::PrimaryHost do
  let(:load_balancer) do
    Gitlab::Database::LoadBalancing::LoadBalancer.new(
      Gitlab::Database::LoadBalancing::Configuration.new(ActiveRecord::Base)
    )
  end

  let(:host) { Gitlab::Database::LoadBalancing::PrimaryHost.new(load_balancer) }

  describe '#connection' do
    it 'returns a connection from the pool' do
      expect(load_balancer.pool).to receive(:connection)

      host.connection
    end
  end

  describe '#release_connection' do
    it 'does nothing' do
      expect(host.release_connection).to be_nil
    end
  end

  describe '#enable_query_cache!' do
    it 'does nothing' do
      expect(host.enable_query_cache!).to be_nil
    end
  end

  describe '#disable_query_cache!' do
    it 'does nothing' do
      expect(host.disable_query_cache!).to be_nil
    end
  end

  describe '#query_cache_enabled' do
    it 'delegates to the primary connection pool' do
      expect(host.query_cache_enabled)
        .to eq(load_balancer.pool.query_cache_enabled)
    end
  end

  describe '#disconnect!' do
    it 'does nothing' do
      expect(host.disconnect!).to be_nil
    end
  end

  describe '#offline!' do
    it 'does nothing' do
      expect(host.offline!).to be_nil
    end
  end

  describe '#online?' do
    it 'returns true' do
      expect(host.online?).to eq(true)
    end
  end

  describe '#primary_write_location' do
    it 'returns the write location of the primary' do
      expect(host.primary_write_location).to be_an_instance_of(String)
      expect(host.primary_write_location).not_to be_empty
    end
  end

  describe '#caught_up?' do
    it 'returns true' do
      expect(host.caught_up?('foo')).to eq(true)
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
      expect(host).to receive(:query_and_release).and_return({})

      expect(host.database_replica_location).to be_nil
    end

    it 'returns nil when the database connection fails' do
      allow(host).to receive(:connection).and_raise(PG::Error)

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
end
