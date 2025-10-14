# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::Setup do
  describe '#setup' do
    it 'sets up the load balancer' do
      setup = described_class.new(ActiveRecord::Base)

      expect(setup).to receive(:configure_connection)
      expect(setup).to receive(:setup_connection_proxy)
      expect(setup).to receive(:setup_service_discovery)

      setup.setup
    end
  end

  describe '#configure_connection' do
    it 'configures pool, prepared statements and reconnects to the database' do
      config = double(
        :config,
        configuration_hash: { host: 'localhost', pool: 2, prepared_statements: true },
        env_name: 'test',
        name: 'main'
      )
      model = double(:model, connection_db_config: config)

      expect(ActiveRecord::DatabaseConfigurations::HashConfig)
        .to receive(:new)
        .with('test', 'main', {
          host: 'localhost',
          prepared_statements: false,
          pool: Gitlab::Database.default_pool_size
        })
        .and_call_original

      # HashConfig doesn't implement its own #==, so we can't directly compare
      # the expected value with a pre-defined one.
      expect(model)
        .to receive(:establish_connection)
        .with(an_instance_of(ActiveRecord::DatabaseConfigurations::HashConfig))

      described_class.new(model).configure_connection
    end
  end

  describe '#setup_connection_proxy' do
    it 'sets up the load balancer' do
      model = Class.new(ActiveRecord::Base)
      setup = described_class.new(model)
      config = Gitlab::Database::LoadBalancing::Configuration.new(model)
      lb = instance_spy(Gitlab::Database::LoadBalancing::LoadBalancer)

      allow(lb).to receive(:configuration).and_return(config)

      expect(Gitlab::Database::LoadBalancing::LoadBalancer)
        .to receive(:new)
        .with(setup.configuration)
        .and_return(lb)

      setup.setup_connection_proxy

      expect(model.connection).to be_an_instance_of(Gitlab::Database::LoadBalancing::ConnectionProxy)
      expect(model.load_balancer).to eq(lb)
      expect(model.sticking)
        .to be_an_instance_of(Gitlab::Database::LoadBalancing::Sticking)

      if Gitlab.next_rails?
        expect(model.lease_connection).to be_an_instance_of(Gitlab::Database::LoadBalancing::ConnectionProxy)
      end
    end
  end

  describe '#with_connection' do
    let(:model) { Class.new(ActiveRecord::Base) }

    before do
      skip 'Skipping Rails 7.2 only tests' unless Gitlab.next_rails?

      described_class.new(model).setup_connection_proxy
      model.load_balancer.release_connections
    end

    it 'does not release connections if connection was overridden' do
      allow(model).to receive(:connection).and_return(model.load_balancer.pool.lease_connection)

      expect(model.load_balancer).not_to receive(:release_connections)

      model.with_connection do |conn|
        conn.execute('SELECT 1')
      end
    end

    it 'does not release connections if a connection was already checked out' do
      expect(model.load_balancer).not_to receive(:release_connections)

      model.connection.execute('SELECT 1')

      model.with_connection do |conn|
        conn.execute('SELECT 1')
      end
    end

    it 'releases connections if a connection has not been checked out' do
      expect(model.load_balancer).to receive(:release_connections)

      model.with_connection do |conn|
        conn.execute('SELECT 1')
      end
    end
  end

  describe '#setup_service_discovery' do
    context 'when service discovery is disabled' do
      it 'does nothing' do
        expect(Gitlab::Database::LoadBalancing::ServiceDiscovery)
          .not_to receive(:new)

        described_class.new(ActiveRecord::Base).setup_service_discovery
      end
    end

    context 'when service discovery is enabled' do
      it 'immediately performs service discovery' do
        model = ActiveRecord::Base
        setup = described_class.new(model)
        sv = instance_spy(Gitlab::Database::LoadBalancing::ServiceDiscovery)

        allow(setup.configuration)
          .to receive(:service_discovery_enabled?)
          .and_return(true)

        allow(Gitlab::Database::LoadBalancing::ServiceDiscovery)
          .to receive(:new)
          .with(setup.load_balancer, setup.configuration.service_discovery)
          .and_return(sv)

        expect(sv).to receive(:perform_service_discovery)
        expect(sv).not_to receive(:start)

        setup.setup_service_discovery
      end

      it 'starts service discovery if needed' do
        model = ActiveRecord::Base
        setup = described_class.new(model, start_service_discovery: true)
        sv = instance_spy(Gitlab::Database::LoadBalancing::ServiceDiscovery)

        allow(setup.configuration)
          .to receive(:service_discovery_enabled?)
          .and_return(true)

        allow(Gitlab::Database::LoadBalancing::ServiceDiscovery)
          .to receive(:new)
          .with(setup.load_balancer, setup.configuration.service_discovery)
          .and_return(sv)

        expect(sv).to receive(:perform_service_discovery)
        expect(sv).to receive(:start)

        setup.setup_service_discovery
      end
    end
  end

  context 'uses correct base models', :reestablished_active_record_base do
    using RSpec::Parameterized::TableSyntax

    let(:main_class) do
      Class.new(ActiveRecord::Base) do
        def self.name
          'ApplicationRecordTemporary'
        end

        establish_connection ActiveRecord::DatabaseConfigurations::HashConfig.new(
          Rails.env,
          'main',
          ActiveRecord::Base.connection_db_config.configuration_hash
        )
      end
    end

    let(:ci_class) do
      Class.new(ActiveRecord::Base) do
        def self.name
          'Ci::ApplicationRecordTemporary'
        end

        establish_connection ActiveRecord::DatabaseConfigurations::HashConfig.new(
          Rails.env,
          'ci',
          ActiveRecord::Base.connection_db_config.configuration_hash
        )
      end
    end

    let(:models) do
      {
        main: main_class,
        ci: ci_class
      }
    end

    before do
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)

      allow_next_instance_of(described_class) do |setup|
        allow(setup).to receive(:configure_connection)
      end

      # Make load balancer to force init with a dedicated replicas connections
      models.each do |_, model|
        described_class.new(model).tap do |subject|
          subject.configuration.hosts = [subject.configuration.db_config.host]
          subject.setup
        end
      end
    end

    it 'results match expectations' do
      result = models.transform_values do |model|
        load_balancer = model.connection.instance_variable_get(:@load_balancer)

        {
          read: load_balancer.read { |connection| connection.pool.db_config.name },
          write: load_balancer.read_write { |connection| connection.pool.db_config.name }
        }
      end

      expect(result).to eq({
        main: { read: 'main_replica', write: 'main' },
        ci: { read: 'ci_replica', write: 'ci' }
      })
    end

    it 'does return load_balancer assigned to a given connection' do
      models.each do |name, model|
        expect(model.load_balancer.name).to eq(name)
        expect(model.sticking.instance_variable_get(:@load_balancer)).to eq(model.load_balancer)
      end
    end
  end
end
