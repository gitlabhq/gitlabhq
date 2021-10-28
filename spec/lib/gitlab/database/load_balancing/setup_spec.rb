# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::Setup do
  describe '#setup' do
    it 'sets up the load balancer' do
      setup = described_class.new(ActiveRecord::Base)

      expect(setup).to receive(:configure_connection)
      expect(setup).to receive(:setup_load_balancer)
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

  describe '#setup_load_balancer' do
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

      setup.setup_load_balancer

      expect(model.connection.load_balancer).to eq(lb)
      expect(model.sticking)
        .to be_an_instance_of(Gitlab::Database::LoadBalancing::Sticking)
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
        lb = model.connection.load_balancer

        allow(setup.configuration)
          .to receive(:service_discovery_enabled?)
          .and_return(true)

        allow(Gitlab::Database::LoadBalancing::ServiceDiscovery)
          .to receive(:new)
          .with(lb, setup.configuration.service_discovery)
          .and_return(sv)

        expect(sv).to receive(:perform_service_discovery)
        expect(sv).not_to receive(:start)

        setup.setup_service_discovery
      end

      it 'starts service discovery if needed' do
        model = ActiveRecord::Base
        setup = described_class.new(model, start_service_discovery: true)
        sv = instance_spy(Gitlab::Database::LoadBalancing::ServiceDiscovery)
        lb = model.connection.load_balancer

        allow(setup.configuration)
          .to receive(:service_discovery_enabled?)
          .and_return(true)

        allow(Gitlab::Database::LoadBalancing::ServiceDiscovery)
          .to receive(:new)
          .with(lb, setup.configuration.service_discovery)
          .and_return(sv)

        expect(sv).to receive(:perform_service_discovery)
        expect(sv).to receive(:start)

        setup.setup_service_discovery
      end
    end
  end
end
