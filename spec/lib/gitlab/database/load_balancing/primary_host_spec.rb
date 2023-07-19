# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::PrimaryHost do
  let(:load_balancer) do
    Gitlab::Database::LoadBalancing::LoadBalancer.new(
      Gitlab::Database::LoadBalancing::Configuration.new(ActiveRecord::Base)
    )
  end

  let(:host) { described_class.new(load_balancer) }

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
    it 'logs the event but does nothing else' do
      expect(Gitlab::Database::LoadBalancing::Logger).to receive(:warn)
        .with(hash_including(event: :host_offline))
        .and_call_original

      expect(host.offline!).to be_nil
    end
  end

  describe '#online?' do
    it 'returns true' do
      expect(host.online?).to eq(true)
    end
  end

  describe '#primary_write_location' do
    it 'raises NotImplementedError' do
      expect { host.primary_write_location }.to raise_error(NotImplementedError)
    end
  end

  describe '#caught_up?' do
    it 'returns true' do
      expect(host.caught_up?('foo')).to eq(true)
    end
  end

  describe '#database_replica_location' do
    it 'raises NotImplementedError' do
      expect { host.database_replica_location }.to raise_error(NotImplementedError)
    end
  end
end
