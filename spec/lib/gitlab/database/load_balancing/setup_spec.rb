# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::Setup do
  describe '#setup' do
    it 'sets up the load balancer' do
      setup = described_class.new(ActiveRecord::Base)

      expect(setup).to receive(:configure_connection)
      expect(setup).to receive(:setup_connection_proxy)
      expect(setup).to receive(:setup_service_discovery)
      expect(setup).to receive(:setup_feature_flag_to_model_load_balancing)

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

      expect(model.load_balancer).to eq(lb)
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

  describe '#setup_feature_flag_to_model_load_balancing', :reestablished_active_record_base do
    using RSpec::Parameterized::TableSyntax

    where do
      {
        "with model LB enabled it picks a dedicated CI connection" => {
          env_GITLAB_USE_MODEL_LOAD_BALANCING: 'true',
          env_GITLAB_LOAD_BALANCING_REUSE_PRIMARY_ci: nil,
          request_store_active: false,
          ff_use_model_load_balancing: nil,
          ff_force_no_sharing_primary_model: false,
          expectations: {
            main: { read: 'main_replica', write: 'main' },
            ci: { read: 'ci_replica', write: 'ci' }
          }
        },
        "with model LB enabled and re-use of primary connection it uses CI connection for reads" => {
          env_GITLAB_USE_MODEL_LOAD_BALANCING: 'true',
          env_GITLAB_LOAD_BALANCING_REUSE_PRIMARY_ci: 'main',
          request_store_active: false,
          ff_use_model_load_balancing: nil,
          ff_force_no_sharing_primary_model: false,
          expectations: {
            main: { read: 'main_replica', write: 'main' },
            ci: { read: 'ci_replica', write: 'main' }
          }
        },
        "with model LB disabled it fallbacks to use main" => {
          env_GITLAB_USE_MODEL_LOAD_BALANCING: 'false',
          env_GITLAB_LOAD_BALANCING_REUSE_PRIMARY_ci: nil,
          request_store_active: false,
          ff_use_model_load_balancing: nil,
          ff_force_no_sharing_primary_model: false,
          expectations: {
            main: { read: 'main_replica', write: 'main' },
            ci: { read: 'main_replica', write: 'main' }
          }
        },
        "with model LB disabled, but re-use configured it fallbacks to use main" => {
          env_GITLAB_USE_MODEL_LOAD_BALANCING: 'false',
          env_GITLAB_LOAD_BALANCING_REUSE_PRIMARY_ci: 'main',
          request_store_active: false,
          ff_use_model_load_balancing: nil,
          ff_force_no_sharing_primary_model: false,
          expectations: {
            main: { read: 'main_replica', write: 'main' },
            ci: { read: 'main_replica', write: 'main' }
          }
        },
        "with FF use_model_load_balancing disabled without RequestStore it uses main" => {
          env_GITLAB_USE_MODEL_LOAD_BALANCING: nil,
          env_GITLAB_LOAD_BALANCING_REUSE_PRIMARY_ci: nil,
          request_store_active: false,
          ff_use_model_load_balancing: false,
          ff_force_no_sharing_primary_model: false,
          expectations: {
            main: { read: 'main_replica', write: 'main' },
            ci: { read: 'main_replica', write: 'main' }
          }
        },
        "with FF use_model_load_balancing enabled without RequestStore sticking of FF does not work, so it fallbacks to use main" => {
          env_GITLAB_USE_MODEL_LOAD_BALANCING: nil,
          env_GITLAB_LOAD_BALANCING_REUSE_PRIMARY_ci: nil,
          request_store_active: false,
          ff_use_model_load_balancing: true,
          ff_force_no_sharing_primary_model: false,
          expectations: {
            main: { read: 'main_replica', write: 'main' },
            ci: { read: 'main_replica', write: 'main' }
          }
        },
        "with FF use_model_load_balancing disabled with RequestStore it uses main" => {
          env_GITLAB_USE_MODEL_LOAD_BALANCING: nil,
          env_GITLAB_LOAD_BALANCING_REUSE_PRIMARY_ci: nil,
          request_store_active: true,
          ff_use_model_load_balancing: false,
          ff_force_no_sharing_primary_model: false,
          expectations: {
            main: { read: 'main_replica', write: 'main' },
            ci: { read: 'main_replica', write: 'main' }
          }
        },
        "with FF use_model_load_balancing enabled with RequestStore it sticks FF and uses CI connection" => {
          env_GITLAB_USE_MODEL_LOAD_BALANCING: nil,
          env_GITLAB_LOAD_BALANCING_REUSE_PRIMARY_ci: nil,
          request_store_active: true,
          ff_use_model_load_balancing: true,
          ff_force_no_sharing_primary_model: false,
          expectations: {
            main: { read: 'main_replica', write: 'main' },
            ci: { read: 'ci_replica', write: 'ci' }
          }
        },
        "with re-use and ff_use_model_load_balancing enabled and FF force_no_sharing_primary_model disabled with RequestStore it sticks FF and uses CI connection for reads" => {
          env_GITLAB_USE_MODEL_LOAD_BALANCING: nil,
          env_GITLAB_LOAD_BALANCING_REUSE_PRIMARY_ci: 'main',
          request_store_active: true,
          ff_use_model_load_balancing: true,
          ff_force_no_sharing_primary_model: false,
          expectations: {
            main: { read: 'main_replica', write: 'main' },
            ci: { read: 'ci_replica', write: 'main' }
          }
        },
        "with re-use and ff_use_model_load_balancing enabled and FF force_no_sharing_primary_model enabled with RequestStore it sticks FF and uses CI connection for reads" => {
          env_GITLAB_USE_MODEL_LOAD_BALANCING: nil,
          env_GITLAB_LOAD_BALANCING_REUSE_PRIMARY_ci: 'main',
          request_store_active: true,
          ff_use_model_load_balancing: true,
          ff_force_no_sharing_primary_model: true,
          expectations: {
            main: { read: 'main_replica', write: 'main' },
            ci: { read: 'ci_replica', write: 'ci' }
          }
        }
      }
    end

    with_them do
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
          main: ActiveRecord::Base,
          ci: ci_class
        }
      end

      around do |example|
        if request_store_active
          Gitlab::WithRequestStore.with_request_store do
            stub_feature_flags(force_no_sharing_primary_model: ff_force_no_sharing_primary_model)
            RequestStore.clear!

            example.run
          end
        else
          example.run
        end
      end

      before do
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)

        # Rewrite `class_attribute` to use rspec mocking and prevent modifying the objects
        allow_next_instance_of(described_class) do |setup|
          allow(setup).to receive(:configure_connection)

          allow(setup).to receive(:setup_class_attribute) do |attribute, value|
            allow(setup.model).to receive(attribute) { value }
          end
        end

        stub_env('GITLAB_USE_MODEL_LOAD_BALANCING', env_GITLAB_USE_MODEL_LOAD_BALANCING)
        stub_env('GITLAB_LOAD_BALANCING_REUSE_PRIMARY_ci', env_GITLAB_LOAD_BALANCING_REUSE_PRIMARY_ci)
        stub_feature_flags(use_model_load_balancing: ff_use_model_load_balancing)

        # Make load balancer to force init with a dedicated replicas connections
        models.each do |_, model|
          described_class.new(model).tap do |subject|
            subject.configuration.hosts = [subject.configuration.replica_db_config.host]
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

        expect(result).to eq(expectations)
      end

      it 'does return load_balancer assigned to a given connection' do
        models.each do |name, model|
          expect(model.load_balancer.name).to eq(name)
          expect(model.sticking.instance_variable_get(:@load_balancer)).to eq(model.load_balancer)
        end
      end
    end
  end
end
