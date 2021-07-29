# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing do
  include_context 'clear DB Load Balancing configuration'

  before do
    stub_env('ENABLE_LOAD_BALANCING_FOR_FOSS', 'true')
  end

  describe '.proxy' do
    context 'when configured' do
      before do
        allow(ActiveRecord::Base.singleton_class).to receive(:prepend)
        subject.configure_proxy
      end

      it 'returns the connection proxy' do
        expect(subject.proxy).to be_an_instance_of(subject::ConnectionProxy)
      end
    end

    context 'when not configured' do
      it 'returns nil' do
        expect(subject.proxy).to be_nil
      end

      it 'tracks an error to sentry' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          an_instance_of(subject::ProxyNotConfiguredError)
        )

        subject.proxy
      end
    end
  end

  describe '.configuration' do
    it 'returns a Hash' do
      lb_config = { 'hosts' => %w(foo) }

      original_db_config = Gitlab::Database.main.config
      modified_db_config = original_db_config.merge(load_balancing: lb_config)
      expect(Gitlab::Database.main).to receive(:config).and_return(modified_db_config)

      expect(described_class.configuration).to eq(lb_config)
    end
  end

  describe '.max_replication_difference' do
    context 'without an explicitly configured value' do
      it 'returns the default value' do
        allow(described_class)
          .to receive(:configuration)
          .and_return({})

        expect(described_class.max_replication_difference).to eq(8.megabytes)
      end
    end

    context 'with an explicitly configured value' do
      it 'returns the configured value' do
        allow(described_class)
          .to receive(:configuration)
          .and_return({ 'max_replication_difference' => 4 })

        expect(described_class.max_replication_difference).to eq(4)
      end
    end
  end

  describe '.max_replication_lag_time' do
    context 'without an explicitly configured value' do
      it 'returns the default value' do
        allow(described_class)
          .to receive(:configuration)
          .and_return({})

        expect(described_class.max_replication_lag_time).to eq(60)
      end
    end

    context 'with an explicitly configured value' do
      it 'returns the configured value' do
        allow(described_class)
          .to receive(:configuration)
          .and_return({ 'max_replication_lag_time' => 4 })

        expect(described_class.max_replication_lag_time).to eq(4)
      end
    end
  end

  describe '.replica_check_interval' do
    context 'without an explicitly configured value' do
      it 'returns the default value' do
        allow(described_class)
          .to receive(:configuration)
          .and_return({})

        expect(described_class.replica_check_interval).to eq(60)
      end
    end

    context 'with an explicitly configured value' do
      it 'returns the configured value' do
        allow(described_class)
          .to receive(:configuration)
          .and_return({ 'replica_check_interval' => 4 })

        expect(described_class.replica_check_interval).to eq(4)
      end
    end
  end

  describe '.hosts' do
    it 'returns a list of hosts' do
      allow(described_class)
        .to receive(:configuration)
        .and_return({ 'hosts' => %w(foo bar baz) })

      expect(described_class.hosts).to eq(%w(foo bar baz))
    end
  end

  describe '.pool_size' do
    it 'returns a Fixnum' do
      expect(described_class.pool_size).to be_a_kind_of(Integer)
    end
  end

  describe '.enable?' do
    before do
      clear_load_balancing_configuration
      allow(described_class).to receive(:hosts).and_return(%w(foo))
    end

    it 'returns false when no hosts are specified' do
      allow(described_class).to receive(:hosts).and_return([])

      expect(described_class.enable?).to eq(false)
    end

    it 'returns true when Sidekiq is being used' do
      allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)

      expect(described_class.enable?).to eq(true)
    end

    it 'returns false when running inside a Rake task' do
      allow(Gitlab::Runtime).to receive(:rake?).and_return(true)

      expect(described_class.enable?).to eq(false)
    end

    it 'returns true when load balancing should be enabled' do
      allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(false)

      expect(described_class.enable?).to eq(true)
    end

    it 'returns true when service discovery is enabled' do
      allow(described_class).to receive(:hosts).and_return([])
      allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(false)

      allow(described_class)
        .to receive(:service_discovery_enabled?)
        .and_return(true)

      expect(described_class.enable?).to eq(true)
    end
  end

  describe '.configured?' do
    before do
      clear_load_balancing_configuration
    end

    it 'returns true when Sidekiq is being used' do
      allow(described_class).to receive(:hosts).and_return(%w(foo))
      allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
      expect(described_class.configured?).to eq(true)
    end

    it 'returns true when service discovery is enabled in Sidekiq' do
      allow(described_class).to receive(:hosts).and_return([])
      allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)

      allow(described_class)
        .to receive(:service_discovery_enabled?)
        .and_return(true)

      expect(described_class.configured?).to eq(true)
    end

    it 'returns false when neither service discovery nor hosts are configured' do
      allow(described_class).to receive(:hosts).and_return([])

      allow(described_class)
        .to receive(:service_discovery_enabled?)
        .and_return(false)

      expect(described_class.configured?).to eq(false)
    end
  end

  describe '.configure_proxy' do
    it 'configures the connection proxy' do
      allow(ActiveRecord::Base.singleton_class).to receive(:prepend)

      described_class.configure_proxy

      expect(ActiveRecord::Base.singleton_class).to have_received(:prepend)
        .with(Gitlab::Database::LoadBalancing::ActiveRecordProxy)
    end
  end

  describe '.active_record_models' do
    it 'returns an Array' do
      expect(described_class.active_record_models).to be_an_instance_of(Array)
    end
  end

  describe '.service_discovery_enabled?' do
    it 'returns true if service discovery is enabled' do
      allow(described_class)
        .to receive(:configuration)
        .and_return('discover' => { 'record' => 'foo' })

      expect(described_class.service_discovery_enabled?).to eq(true)
    end

    it 'returns false if service discovery is disabled' do
      expect(described_class.service_discovery_enabled?).to eq(false)
    end
  end

  describe '.service_discovery_configuration' do
    context 'when no configuration is provided' do
      it 'returns a default configuration Hash' do
        expect(described_class.service_discovery_configuration).to eq(
          nameserver: 'localhost',
          port: 8600,
          record: nil,
          record_type: 'A',
          interval: 60,
          disconnect_timeout: 120,
          use_tcp: false
        )
      end
    end

    context 'when configuration is provided' do
      it 'returns a Hash including the custom configuration' do
        allow(described_class)
          .to receive(:configuration)
          .and_return('discover' => { 'record' => 'foo', 'record_type' => 'SRV' })

        expect(described_class.service_discovery_configuration).to eq(
          nameserver: 'localhost',
          port: 8600,
          record: 'foo',
          record_type: 'SRV',
          interval: 60,
          disconnect_timeout: 120,
          use_tcp: false
        )
      end
    end
  end

  describe '.start_service_discovery' do
    it 'does not start if service discovery is disabled' do
      expect(Gitlab::Database::LoadBalancing::ServiceDiscovery)
        .not_to receive(:new)

      described_class.start_service_discovery
    end

    it 'starts service discovery if enabled' do
      allow(described_class)
        .to receive(:service_discovery_enabled?)
        .and_return(true)

      instance = double(:instance)

      expect(Gitlab::Database::LoadBalancing::ServiceDiscovery)
        .to receive(:new)
        .with(an_instance_of(Hash))
        .and_return(instance)

      expect(instance)
        .to receive(:start)

      described_class.start_service_discovery
    end
  end

  describe '.db_role_for_connection' do
    let(:connection) { double(:conneciton) }

    context 'when the load balancing is not configured' do
      before do
        allow(described_class).to receive(:enable?).and_return(false)
      end

      it 'returns primary' do
        expect(described_class.db_role_for_connection(connection)).to be(:primary)
      end
    end

    context 'when the load balancing is configured' do
      let(:proxy) { described_class::ConnectionProxy.new(%w(foo)) }
      let(:load_balancer) { described_class::LoadBalancer.new(%w(foo)) }

      before do
        allow(ActiveRecord::Base.singleton_class).to receive(:prepend)

        allow(described_class).to receive(:enable?).and_return(true)
        allow(described_class).to receive(:proxy).and_return(proxy)
        allow(proxy).to receive(:load_balancer).and_return(load_balancer)

        subject.configure_proxy(proxy)
      end

      context 'when the load balancer returns :replica' do
        it 'returns :replica' do
          allow(load_balancer).to receive(:db_role_for_connection).and_return(:replica)

          expect(described_class.db_role_for_connection(connection)).to be(:replica)

          expect(load_balancer).to have_received(:db_role_for_connection).with(connection)
        end
      end

      context 'when the load balancer returns :primary' do
        it 'returns :primary' do
          allow(load_balancer).to receive(:db_role_for_connection).and_return(:primary)

          expect(described_class.db_role_for_connection(connection)).to be(:primary)

          expect(load_balancer).to have_received(:db_role_for_connection).with(connection)
        end
      end

      context 'when the load balancer returns nil' do
        it 'returns nil' do
          allow(load_balancer).to receive(:db_role_for_connection).and_return(nil)

          expect(described_class.db_role_for_connection(connection)).to be(nil)

          expect(load_balancer).to have_received(:db_role_for_connection).with(connection)
        end
      end
    end
  end

  # For such an important module like LoadBalancing, full mocking is not
  # enough. This section implements some integration tests to test a full flow
  # of the load balancer.
  # - A real model with a table backed behind is defined
  # - The load balancing module is set up for this module only, as to prevent
  # breaking other tests. The replica configuration is cloned from the test
  # configuraiton.
  # - In each test, we listen to the SQL queries (via sql.active_record
  # instrumentation) while triggering real queries from the defined model.
  # - We assert the desinations (replica/primary) of the queries in order.
  describe 'LoadBalancing integration tests', :delete do
    before(:all) do
      ActiveRecord::Schema.define do
        create_table :load_balancing_test, force: true do |t|
          t.string :name, null: true
        end
      end
    end

    after(:all) do
      ActiveRecord::Schema.define do
        drop_table :load_balancing_test, force: true
      end
    end

    shared_context 'LoadBalancing setup' do
      let(:development_db_config) { ActiveRecord::Base.configurations.configs_for(env_name: 'development').first.configuration_hash }
      let(:hosts) { [development_db_config[:host]] }
      let(:model) do
        Class.new(ApplicationRecord) do
          self.table_name = "load_balancing_test"
        end
      end

      before do
        # Preloading testing class
        model.singleton_class.prepend ::Gitlab::Database::LoadBalancing::ActiveRecordProxy

        # Setup load balancing
        clear_load_balancing_configuration
        allow(ActiveRecord::Base.singleton_class).to receive(:prepend)
        subject.configure_proxy(::Gitlab::Database::LoadBalancing::ConnectionProxy.new(hosts))

        original_db_config = Gitlab::Database.main.config
        modified_db_config = original_db_config.merge(load_balancing: { hosts: hosts })
        allow(Gitlab::Database.main).to receive(:config).and_return(modified_db_config)

        ::Gitlab::Database::LoadBalancing::Session.clear_session
      end
    end

    where(:queries, :include_transaction, :expected_results) do
      [
        # Read methods
        [-> { model.first }, false, [:replica]],
        [-> { model.find_by(id: 123) }, false, [:replica]],
        [-> { model.where(name: 'hello').to_a }, false, [:replica]],

        # Write methods
        [-> { model.create!(name: 'test1') }, false, [:primary]],
        [
          -> {
            instance = model.create!(name: 'test1')
            instance.update!(name: 'test2')
          },
          false, [:primary, :primary]
        ],
        [-> { model.update_all(name: 'test2') }, false, [:primary]],
        [
          -> {
            instance = model.create!(name: 'test1')
            instance.destroy!
          },
          false, [:primary, :primary]
        ],
        [-> { model.delete_all }, false, [:primary]],

        # Custom query
        [-> { model.connection.exec_query('SELECT 1').to_a }, false, [:primary]],

        # Reads after a write
        [
          -> {
            model.first
            model.create!(name: 'test1')
            model.first
            model.find_by(name: 'test1')
          },
          false, [:replica, :primary, :primary, :primary]
        ],

        # Inside a transaction
        [
          -> {
            model.transaction do
              model.find_by(name: 'test1')
              model.create!(name: 'test1')
              instance = model.find_by(name: 'test1')
              instance.update!(name: 'test2')
            end
            model.find_by(name: 'test1')
          },
          true, [:primary, :primary, :primary, :primary, :primary, :primary, :primary]
        ],

        # Nested transaction
        [
          -> {
            model.transaction do
              model.transaction do
                model.create!(name: 'test1')
              end
              model.update_all(name: 'test2')
            end
            model.find_by(name: 'test1')
          },
          true, [:primary, :primary, :primary, :primary, :primary]
        ],

        # Read-only transaction
        [
          -> {
            model.transaction do
              model.first
              model.where(name: 'test1').to_a
            end
          },
          true, [:primary, :primary, :primary, :primary]
        ],

        # use_primary
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.use_primary do
              model.first
              model.where(name: 'test1').to_a
            end
            model.first
          },
          false, [:primary, :primary, :replica]
        ],

        # use_primary!
        [
          -> {
            model.first
            ::Gitlab::Database::LoadBalancing::Session.current.use_primary!
            model.where(name: 'test1').to_a
          },
          false, [:replica, :primary]
        ],

        # use_replicas_for_read_queries does not affect read queries
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries do
              model.where(name: 'test1').to_a
            end
          },
          false, [:replica]
        ],

        # use_replicas_for_read_queries does not affect write queries
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries do
              model.create!(name: 'test1')
            end
          },
          false, [:primary]
        ],

        # use_replicas_for_read_queries does not affect ambiguous queries
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries do
              model.connection.exec_query("SELECT 1")
            end
          },
          false, [:primary]
        ],

        # use_replicas_for_read_queries ignores use_primary! for read queries
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.use_primary!
            ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries do
              model.where(name: 'test1').to_a
            end
          },
          false, [:replica]
        ],

        # use_replicas_for_read_queries adheres use_primary! for write queries
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.use_primary!
            ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries do
              model.create!(name: 'test1')
            end
          },
          false, [:primary]
        ],

        # use_replicas_for_read_queries adheres use_primary! for ambiguous queries
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.use_primary!
            ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries do
              model.connection.exec_query('SELECT 1')
            end
          },
          false, [:primary]
        ],

        # use_replicas_for_read_queries ignores use_primary blocks
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.use_primary do
              ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries do
                model.where(name: 'test1').to_a
              end
            end
          },
          false, [:replica]
        ],

        # use_replicas_for_read_queries ignores a session already performed write
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.write!
            ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries do
              model.where(name: 'test1').to_a
            end
          },
          false, [:replica]
        ],

        # fallback_to_replicas_for_ambiguous_queries
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.fallback_to_replicas_for_ambiguous_queries do
              model.first
              model.where(name: 'test1').to_a
            end
          },
          false, [:replica, :replica]
        ],

        # fallback_to_replicas_for_ambiguous_queries for read-only transaction
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.fallback_to_replicas_for_ambiguous_queries do
              model.transaction do
                model.first
                model.where(name: 'test1').to_a
              end
            end
          },
          false, [:replica, :replica]
        ],

        # A custom read query inside fallback_to_replicas_for_ambiguous_queries
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.fallback_to_replicas_for_ambiguous_queries do
              model.connection.exec_query("SELECT 1")
            end
          },
          false, [:replica]
        ],

        # A custom read query inside a transaction fallback_to_replicas_for_ambiguous_queries
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.fallback_to_replicas_for_ambiguous_queries do
              model.transaction do
                model.connection.exec_query("SET LOCAL statement_timeout = 5000")
                model.count
              end
            end
          },
          true, [:replica, :replica, :replica, :replica]
        ],

        # fallback_to_replicas_for_ambiguous_queries after a write
        [
          -> {
            model.create!(name: 'Test1')
            ::Gitlab::Database::LoadBalancing::Session.current.fallback_to_replicas_for_ambiguous_queries do
              model.connection.exec_query("SELECT 1")
            end
          },
          false, [:primary, :primary]
        ],

        # fallback_to_replicas_for_ambiguous_queries after use_primary!
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.use_primary!
            ::Gitlab::Database::LoadBalancing::Session.current.fallback_to_replicas_for_ambiguous_queries do
              model.connection.exec_query("SELECT 1")
            end
          },
          false, [:primary]
        ],

        # fallback_to_replicas_for_ambiguous_queries inside use_primary
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.use_primary do
              ::Gitlab::Database::LoadBalancing::Session.current.fallback_to_replicas_for_ambiguous_queries do
                model.connection.exec_query("SELECT 1")
              end
            end
          },
          false, [:primary]
        ],

        # use_primary inside fallback_to_replicas_for_ambiguous_queries
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.fallback_to_replicas_for_ambiguous_queries do
              ::Gitlab::Database::LoadBalancing::Session.current.use_primary do
                model.connection.exec_query("SELECT 1")
              end
            end
          },
          false, [:primary]
        ],

        # A write query inside fallback_to_replicas_for_ambiguous_queries
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.fallback_to_replicas_for_ambiguous_queries do
              model.connection.exec_query("SELECT 1")
              model.delete_all
              model.connection.exec_query("SELECT 1")
            end
          },
          false, [:replica, :primary, :primary]
        ],

        # use_replicas_for_read_queries incorporates with fallback_to_replicas_for_ambiguous_queries
        [
          -> {
            ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries do
              ::Gitlab::Database::LoadBalancing::Session.current.fallback_to_replicas_for_ambiguous_queries do
                model.connection.exec_query('SELECT 1')
                model.where(name: 'test1').to_a
              end
            end
          },
          false, [:replica, :replica]
        ]
      ]
    end

    with_them do
      include_context 'LoadBalancing setup'

      it 'redirects queries to the right roles' do
        roles = []

        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |event|
          payload = event.payload

          assert =
            if payload[:name] == 'SCHEMA'
              false
            elsif payload[:name] == 'SQL' # Custom query
              true
            else
              keywords = %w[load_balancing_test]
              keywords += %w[begin commit] if include_transaction
              keywords.any? { |keyword| payload[:sql].downcase.include?(keyword) }
            end

          if assert
            db_role = ::Gitlab::Database::LoadBalancing.db_role_for_connection(payload[:connection])
            roles << db_role
          end
        end

        self.instance_exec(&queries)

        expect(roles).to eql(expected_results)
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
      end
    end

    context 'custom connection handling' do
      where(:queries, :expected_role) do
        [
          # Reload cache. The schema loading queries should be handled by
          # primary.
          [
            -> {
              model.connection.clear_cache!
              model.connection.schema_cache.add('users')
              model.connection.pool.release_connection
            },
            :primary
          ],

          # Call model's connection method
          [
            -> {
              connection = model.connection
              connection.select_one('SELECT 1')
              connection.pool.release_connection
            },
            :replica
          ],

          # Retrieve connection via #retrieve_connection
          [
            -> {
              connection = model.retrieve_connection
              connection.select_one('SELECT 1')
              connection.pool.release_connection
            },
            :primary
          ]
        ]
      end

      with_them do
        include_context 'LoadBalancing setup'

        it 'redirects queries to the right roles' do
          roles = []

          subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |event|
            role = ::Gitlab::Database::LoadBalancing.db_role_for_connection(event.payload[:connection])
            roles << role if role.present?
          end

          self.instance_exec(&queries)

          expect(roles).to all(eql(expected_role))
        ensure
          ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
        end
      end
    end

    context 'a write inside a transaction inside fallback_to_replicas_for_ambiguous_queries block' do
      include_context 'LoadBalancing setup'

      it 'raises an exception' do
        expect do
          ::Gitlab::Database::LoadBalancing::Session.current.fallback_to_replicas_for_ambiguous_queries do
            model.transaction do
              model.first
              model.create!(name: 'hello')
            end
          end
        end.to raise_error(Gitlab::Database::LoadBalancing::ConnectionProxy::WriteInsideReadOnlyTransactionError)
      end
    end
  end
end
