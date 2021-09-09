# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::Configuration do
  describe '.for_model' do
    let(:model) do
      config = ActiveRecord::DatabaseConfigurations::HashConfig
        .new('main', 'test', configuration_hash)

      double(:model, connection_db_config: config)
    end

    context 'when load balancing is not configured' do
      let(:configuration_hash) { {} }

      it 'uses the default settings' do
        config = described_class.for_model(model)

        expect(config.hosts).to eq([])
        expect(config.max_replication_difference).to eq(8.megabytes)
        expect(config.max_replication_lag_time).to eq(60.0)
        expect(config.replica_check_interval).to eq(60.0)
        expect(config.service_discovery).to eq(
          nameserver: 'localhost',
          port: 8600,
          record: nil,
          record_type: 'A',
          interval: 60,
          disconnect_timeout: 120,
          use_tcp: false
        )
        expect(config.pool_size).to eq(Gitlab::Database.default_pool_size)
      end
    end

    context 'when load balancing is configured' do
      let(:configuration_hash) do
        {
          pool: 4,
          load_balancing: {
            max_replication_difference: 1,
            max_replication_lag_time: 2,
            replica_check_interval: 3,
            hosts: %w[foo bar],
            discover: {
              'record' => 'foo.example.com'
            }
          }
        }
      end

      it 'uses the custom configuration settings' do
        config = described_class.for_model(model)

        expect(config.hosts).to eq(%w[foo bar])
        expect(config.max_replication_difference).to eq(1)
        expect(config.max_replication_lag_time).to eq(2.0)
        expect(config.replica_check_interval).to eq(3.0)
        expect(config.service_discovery).to eq(
          nameserver: 'localhost',
          port: 8600,
          record: 'foo.example.com',
          record_type: 'A',
          interval: 60,
          disconnect_timeout: 120,
          use_tcp: false
        )
        expect(config.pool_size).to eq(4)
      end
    end

    context 'when the load balancing configuration uses strings as the keys' do
      let(:configuration_hash) do
        {
          pool: 4,
          load_balancing: {
            'max_replication_difference' => 1,
            'max_replication_lag_time' => 2,
            'replica_check_interval' => 3,
            'hosts' => %w[foo bar],
            'discover' => {
              'record' => 'foo.example.com'
            }
          }
        }
      end

      it 'uses the custom configuration settings' do
        config = described_class.for_model(model)

        expect(config.hosts).to eq(%w[foo bar])
        expect(config.max_replication_difference).to eq(1)
        expect(config.max_replication_lag_time).to eq(2.0)
        expect(config.replica_check_interval).to eq(3.0)
        expect(config.service_discovery).to eq(
          nameserver: 'localhost',
          port: 8600,
          record: 'foo.example.com',
          record_type: 'A',
          interval: 60,
          disconnect_timeout: 120,
          use_tcp: false
        )
        expect(config.pool_size).to eq(4)
      end
    end
  end

  describe '#load_balancing_enabled?' do
    it 'returns true when hosts are configured' do
      config = described_class.new(ActiveRecord::Base, %w[foo bar])

      expect(config.load_balancing_enabled?).to eq(true)
    end

    it 'returns true when a service discovery record is configured' do
      config = described_class.new(ActiveRecord::Base)
      config.service_discovery[:record] = 'foo'

      expect(config.load_balancing_enabled?).to eq(true)
    end

    it 'returns false when no hosts are configured and service discovery is disabled' do
      config = described_class.new(ActiveRecord::Base)

      expect(config.load_balancing_enabled?).to eq(false)
    end
  end

  describe '#service_discovery_enabled?' do
    it 'returns true when a record is configured' do
      config = described_class.new(ActiveRecord::Base)
      config.service_discovery[:record] = 'foo'

      expect(config.service_discovery_enabled?).to eq(true)
    end

    it 'returns false when no record is configured' do
      config = described_class.new(ActiveRecord::Base)

      expect(config.service_discovery_enabled?).to eq(false)
    end
  end
end
