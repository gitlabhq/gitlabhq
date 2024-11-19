# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing, :suppress_gitlab_schemas_validate_connection, feature_category: :cell do
  describe '.base_models' do
    it 'returns the models to apply load balancing to' do
      models = described_class.base_models

      expect(models).to include(ActiveRecord::Base)

      if Gitlab::Database.has_config?(:ci)
        expect(models).to include(Ci::ApplicationRecord)
      end
    end

    it 'returns the models as a frozen array' do
      expect(described_class.base_models).to be_frozen
    end
  end

  describe '.each_load_balancer' do
    it 'yields every load balancer to the supplied block' do
      lbs = []

      described_class.each_load_balancer do |lb|
        lbs << lb
      end

      expect(lbs.length).to eq(described_class.base_models.length)
    end

    it 'returns an Enumerator when no block is given' do
      res = described_class.each_load_balancer

      expect(res.next)
        .to be_an_instance_of(Gitlab::Database::LoadBalancing::LoadBalancer)
    end
  end

  describe '.primary_only?' do
    it 'returns true if all load balancers have no replicas' do
      described_class.each_load_balancer do |lb|
        allow(lb).to receive(:primary_only?).and_return(true)
      end

      expect(described_class.primary_only?).to eq(true)
    end

    it 'returns false if at least one has replicas' do
      described_class.each_load_balancer.with_index do |lb, index|
        allow(lb).to receive(:primary_only?).and_return(index != 0)
      end

      expect(described_class.primary_only?).to eq(false)
    end
  end

  describe '.release_hosts' do
    it 'releases the host of every load balancer' do
      described_class.each_load_balancer do |lb|
        expect(lb).to receive(:release_host)
      end

      described_class.release_hosts
    end
  end

  describe '.db_role_for_connection' do
    context 'when the NullPool is used for connection' do
      let(:pool) { ActiveRecord::ConnectionAdapters::NullPool.new }
      let(:connection) { double(:connection, pool: pool) }

      it 'returns unknown' do
        expect(described_class.db_role_for_connection(connection)).to eq(:unknown)
      end
    end

    context 'when the load balancing is configured' do
      let(:db_host) { ActiveRecord::Base.connection_pool.db_config.host }
      let(:config) do
        Gitlab::Database::LoadBalancing::Configuration
          .new(ActiveRecord::Base, [db_host])
      end

      let(:load_balancer) { described_class::LoadBalancer.new(config) }
      let(:proxy) { described_class::ConnectionProxy.new(load_balancer) }

      context 'when a proxy connection is used' do
        it 'returns :unknown' do
          expect(described_class.db_role_for_connection(proxy)).to eq(:unknown)
        end
      end

      context 'when an invalid connection is used' do
        it 'returns :unknown' do
          expect(described_class.db_role_for_connection(:invalid)).to eq(:unknown)
        end
      end

      context 'when a null connection is used' do
        it 'returns :unknown' do
          expect(described_class.db_role_for_connection(nil)).to eq(:unknown)
        end
      end

      context 'when a read connection is used' do
        it 'returns :replica' do
          load_balancer.read do |connection|
            expect(described_class.db_role_for_connection(connection)).to eq(:replica)
          end
        end
      end

      context 'when a read_write connection is used' do
        it 'returns :primary' do
          load_balancer.read_write do |connection|
            expect(described_class.db_role_for_connection(connection)).to eq(:primary)
          end
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
  describe 'LoadBalancing integration tests', :database_replica, :delete do
    before(:all) do
      ActiveRecord::Schema.define do
        create_table :_test_load_balancing_test, force: true do |t|
          t.string :name, null: true
        end
      end
    end

    after(:all) do
      ActiveRecord::Schema.define do
        drop_table :_test_load_balancing_test, force: true
      end
    end

    let(:model) do
      Class.new(ApplicationRecord) do
        self.table_name = "_test_load_balancing_test"
      end
    end

    def current_session
      ::Gitlab::Database::LoadBalancing::SessionMap.current(model.load_balancer)
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
            current_session.use_primary do
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
            current_session.use_primary!
            model.where(name: 'test1').to_a
          },
          false, [:replica, :primary]
        ],

        # use_replicas_for_read_queries does not affect read queries
        [
          -> {
            current_session.use_replicas_for_read_queries do
              model.where(name: 'test1').to_a
            end
          },
          false, [:replica]
        ],

        # use_replicas_for_read_queries does not affect write queries
        [
          -> {
            current_session.use_replicas_for_read_queries do
              model.create!(name: 'test1')
            end
          },
          false, [:primary]
        ],

        # use_replicas_for_read_queries does not affect ambiguous queries
        [
          -> {
            current_session.use_replicas_for_read_queries do
              model.connection.exec_query("SELECT 1")
            end
          },
          false, [:primary]
        ],

        # use_replicas_for_read_queries ignores use_primary! for read queries
        [
          -> {
            current_session.use_primary!
            current_session.use_replicas_for_read_queries do
              model.where(name: 'test1').to_a
            end
          },
          false, [:replica]
        ],

        # use_replicas_for_read_queries adheres use_primary! for write queries
        [
          -> {
            current_session.use_primary!
            current_session.use_replicas_for_read_queries do
              model.create!(name: 'test1')
            end
          },
          false, [:primary]
        ],

        # use_replicas_for_read_queries adheres use_primary! for ambiguous queries
        [
          -> {
            current_session.use_primary!
            current_session.use_replicas_for_read_queries do
              model.connection.exec_query('SELECT 1')
            end
          },
          false, [:primary]
        ],

        # use_replicas_for_read_queries ignores use_primary blocks
        [
          -> {
            current_session.use_primary do
              current_session.use_replicas_for_read_queries do
                model.where(name: 'test1').to_a
              end
            end
          },
          false, [:replica]
        ],

        # use_replicas_for_read_queries ignores a session already performed write
        [
          -> {
            current_session.write!
            current_session.use_replicas_for_read_queries do
              model.where(name: 'test1').to_a
            end
          },
          false, [:replica]
        ],

        # fallback_to_replicas_for_ambiguous_queries
        [
          -> {
            current_session.fallback_to_replicas_for_ambiguous_queries do
              model.first
              model.where(name: 'test1').to_a
            end
          },
          false, [:replica, :replica]
        ],

        # fallback_to_replicas_for_ambiguous_queries for read-only transaction
        [
          -> {
            current_session.fallback_to_replicas_for_ambiguous_queries do
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
            current_session.fallback_to_replicas_for_ambiguous_queries do
              model.connection.exec_query("SELECT 1")
            end
          },
          false, [:replica]
        ],

        # A custom read query inside a transaction fallback_to_replicas_for_ambiguous_queries
        [
          -> {
            current_session.fallback_to_replicas_for_ambiguous_queries do
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
            current_session.fallback_to_replicas_for_ambiguous_queries do
              model.connection.exec_query("SELECT 1")
            end
          },
          false, [:primary, :primary]
        ],

        # fallback_to_replicas_for_ambiguous_queries after use_primary!
        [
          -> {
            current_session.use_primary!
            current_session.fallback_to_replicas_for_ambiguous_queries do
              model.connection.exec_query("SELECT 1")
            end
          },
          false, [:primary]
        ],

        # fallback_to_replicas_for_ambiguous_queries inside use_primary
        [
          -> {
            current_session.use_primary do
              current_session.fallback_to_replicas_for_ambiguous_queries do
                model.connection.exec_query("SELECT 1")
              end
            end
          },
          false, [:primary]
        ],

        # use_primary inside fallback_to_replicas_for_ambiguous_queries
        [
          -> {
            current_session.fallback_to_replicas_for_ambiguous_queries do
              current_session.use_primary do
                model.connection.exec_query("SELECT 1")
              end
            end
          },
          false, [:primary]
        ],

        # A write query inside fallback_to_replicas_for_ambiguous_queries
        [
          -> {
            current_session.fallback_to_replicas_for_ambiguous_queries do
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
            current_session.use_replicas_for_read_queries do
              current_session.fallback_to_replicas_for_ambiguous_queries do
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
      it 'redirects queries to the right roles' do
        roles = []

        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |event|
          payload = event.payload

          assert =
            case payload[:name]
            when 'SCHEMA'
              false
            when 'SQL' # Custom query
              true
            else
              keywords = %w[_test_load_balancing_test]
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
          # replica even when the current session is stuck to the primary.
          [
            -> {
              current_session.use_primary!
              model.connection.clear_cache!
              model.connection.schema_cache.add('users')
              model.connection.pool.release_connection
            },
            :replica
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
        it 'redirects queries to the right roles' do
          roles = []

          # If we don't run any queries, the pool may be a NullPool. This can
          # result in some tests reporting a role as `:unknown`, even though the
          # tests themselves are correct.
          #
          # To prevent this from happening we simply run a simple query to
          # ensure the proper pool type is put in place. The exact query doesn't
          # matter, provided it actually runs a query and thus creates a proper
          # connection pool.
          model.count

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
      it 'raises an exception' do
        expect do
          ::Gitlab::Database::LoadBalancing::SessionMap
            .current(model.load_balancer)
            .fallback_to_replicas_for_ambiguous_queries do
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
