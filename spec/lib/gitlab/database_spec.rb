# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database, feature_category: :database do
  before do
    stub_const('MigrationTest', Class.new { include Gitlab::Database })
  end

  describe 'EXTRA_SCHEMAS' do
    it 'contains only schemas starting with gitlab_ prefix' do
      described_class::EXTRA_SCHEMAS.each do |schema|
        expect(schema.to_s).to start_with('gitlab_')
      end
    end
  end

  describe '.all_database_connections' do
    it 'the first entry is always main' do
      expect(described_class.all_database_connections.keys).to start_with('main')
    end

    it 'contains as many entries as YAML files' do
      expect(described_class.all_database_connections.values.map(&:file_path))
        .to contain_exactly(*described_class.all_database_connection_files)
    end
  end

  describe '.database_base_models' do
    subject { described_class.database_base_models }

    it 'contains "main"' do
      is_expected.to include("main" => ActiveRecord::Base)
    end

    it 'does not contain "ci" when not running CI database' do
      skip_if_multiple_databases_are_setup(:ci)

      is_expected.not_to include("ci")
    end

    it 'contains "ci" pointing to Ci::ApplicationRecord when running CI database' do
      skip_if_multiple_databases_not_setup(:ci)

      is_expected.to include("ci" => Ci::ApplicationRecord)
    end
  end

  describe '.all_gitlab_schemas' do
    it 'contains as many entries as YAML files' do
      expect(described_class.all_gitlab_schemas.values.map(&:file_path))
        .to contain_exactly(*described_class.all_gitlab_schema_files)
    end
  end

  describe '.schemas_to_base_models' do
    subject { described_class.schemas_to_base_models }

    it 'contains gitlab_main' do
      is_expected.to include(gitlab_main: [ActiveRecord::Base])
    end

    it 'contains gitlab_shared' do
      is_expected.to include(gitlab_main: include(ActiveRecord::Base))
    end

    it 'contains gitlab_ci pointing to ActiveRecord::Base when not running CI database' do
      skip_if_multiple_databases_are_setup(:ci)

      is_expected.to include(gitlab_ci: [ActiveRecord::Base])
    end

    it 'contains gitlab_ci pointing to Ci::ApplicationRecord when running CI database' do
      skip_if_multiple_databases_not_setup(:ci)

      is_expected.to include(gitlab_ci: [Ci::ApplicationRecord])
    end
  end

  describe '.default_pool_size' do
    before do
      allow(Gitlab::Runtime).to receive(:max_threads).and_return(7)
    end

    it 'returns the max thread size plus a fixed headroom of 10' do
      expect(described_class.default_pool_size).to eq(17)
    end

    it 'returns the max thread size plus a DB_POOL_HEADROOM if this env var is present' do
      stub_env('DB_POOL_HEADROOM', '7')

      expect(described_class.default_pool_size).to eq(14)
    end
  end

  describe '.has_config?' do
    context 'three tier database config' do
      it 'returns true for main' do
        expect(described_class.has_config?(:main)).to eq(true)
      end

      context 'ci' do
        before do
          # CI config might not be configured
          allow(ActiveRecord::Base.configurations).to receive(:configs_for)
            .with(env_name: 'test', name: 'ci', include_hidden: true)
            .and_return(ci_db_config)
        end

        let(:ci_db_config) { instance_double('ActiveRecord::DatabaseConfigurations::HashConfig') }

        it 'returns true for ci' do
          expect(described_class.has_config?(:ci)).to eq(true)
        end

        context 'ci database.yml not configured' do
          let(:ci_db_config) { nil }

          it 'returns false for ci' do
            expect(described_class.has_config?(:ci)).to eq(false)
          end
        end
      end

      it 'returns false for non-existent' do
        expect(described_class.has_config?(:nonexistent)).to eq(false)
      end
    end
  end

  describe '.has_database?' do
    context 'three tier database config' do
      it 'returns true for main' do
        expect(described_class.has_database?(:main)).to eq(true)
      end

      it 'returns false for shared database' do
        skip_if_multiple_databases_not_setup(:ci)
        skip_if_database_exists(:ci)

        expect(described_class.has_database?(:ci)).to eq(false)
      end

      it 'returns false for non-existent' do
        expect(described_class.has_database?(:nonexistent)).to eq(false)
      end
    end
  end

  describe '.database_mode' do
    context 'three tier database config' do
      it 'returns single-database if ci is not configured' do
        skip_if_multiple_databases_are_setup(:ci)

        expect(described_class.database_mode).to eq(::Gitlab::Database::MODE_SINGLE_DATABASE)
      end

      it 'returns single-database-ci-connection if ci is shared with main database' do
        skip_if_multiple_databases_not_setup(:ci)
        skip_if_database_exists(:ci)

        expect(described_class.database_mode).to eq(::Gitlab::Database::MODE_SINGLE_DATABASE_CI_CONNECTION)
      end

      it 'returns multiple-database if ci has its own database' do
        skip_if_shared_database(:ci)

        expect(described_class.database_mode).to eq(::Gitlab::Database::MODE_MULTIPLE_DATABASES)
      end
    end
  end

  describe '.check_for_non_superuser' do
    subject { described_class.check_for_non_superuser }

    let(:non_superuser) { Gitlab::Database::PgUser.new(usename: 'foo', usesuper: false) }
    let(:superuser) { Gitlab::Database::PgUser.new(usename: 'bar', usesuper: true) }

    it 'prints user details if not superuser' do
      allow(Gitlab::Database::PgUser).to receive(:find_by).with('usename = CURRENT_USER').and_return(non_superuser)

      expect(Gitlab::AppLogger).to receive(:info).with("Account details: User: \"foo\", UseSuper: (false)")

      subject
    end

    it 'raises an exception if superuser' do
      allow(Gitlab::Database::PgUser).to receive(:find_by).with('usename = CURRENT_USER').and_return(superuser)

      expect(Gitlab::AppLogger).to receive(:info).with("Account details: User: \"bar\", UseSuper: (true)")
      expect { subject }.to raise_error('Error: detected superuser')
    end

    it 'catches exception if find_by fails' do
      allow(Gitlab::Database::PgUser).to receive(:find_by).with('usename = CURRENT_USER').and_raise(ActiveRecord::StatementInvalid)

      expect { subject }.to raise_error('User CURRENT_USER not found')
    end
  end

  describe '.db_config_for_connection' do
    context 'when the regular connection is used' do
      it 'returns db_config' do
        connection = ApplicationRecord.retrieve_connection

        expect(described_class.db_config_for_connection(connection)).to eq(connection.pool.db_config)
      end
    end

    context 'when the connection is LoadBalancing::ConnectionProxy', :database_replica do
      it 'returns primary db config even if ambiguous queries default to replica' do
        Gitlab::Database.database_base_models_using_load_balancing.each_value do |database_base_model|
          connection = database_base_model.connection
          Gitlab::Database::LoadBalancing::SessionMap.with_sessions([::ApplicationRecord, ::Ci::ApplicationRecord]).use_primary!
          primary_config = described_class.db_config_for_connection(connection)

          Gitlab::Database::LoadBalancing::SessionMap.clear_session
          Gitlab::Database::LoadBalancing::SessionMap.with_sessions([::ApplicationRecord, ::Ci::ApplicationRecord]).fallback_to_replicas_for_ambiguous_queries do
            expect(described_class.db_config_for_connection(connection)).to eq(primary_config)
          end
        end
      end
    end

    context 'when the pool is a NullPool' do
      it 'returns nil' do
        connection = double(:active_record_connection, pool: ActiveRecord::ConnectionAdapters::NullPool.new)

        expect(described_class.db_config_for_connection(connection)).to be_nil
      end
    end
  end

  describe '.db_config_name' do
    it 'returns the db_config name for the connection' do
      model = ActiveRecord::Base

      # This is a ConnectionProxy
      expect(described_class.db_config_name(model.connection))
        .to eq('main')

      # This is an actual connection
      expect(described_class.db_config_name(model.retrieve_connection))
        .to eq('main')
    end

    context 'when replicas are configured', :database_replica do
      it 'returns the main_replica for a main database replica' do
        replica = ApplicationRecord.load_balancer.host
        expect(described_class.db_config_name(replica)).to eq('main_replica')
      end

      it 'returns the ci_replica for a ci database replica' do
        skip_if_multiple_databases_not_setup(:ci)
        replica = Ci::ApplicationRecord.load_balancer.host
        expect(described_class.db_config_name(replica)).to eq('ci_replica')
      end
    end
  end

  describe '.db_config_database' do
    let(:model) { ActiveRecord::Base }

    it 'returns the db_config database for the connection' do
      # This is a ConnectionProxy
      expect(described_class.db_config_database(model.connection)).to eq('gitlabhq_test')

      # This is an actual connection
      expect(described_class.db_config_database(model.retrieve_connection)).to eq('gitlabhq_test')
    end

    it 'returns unknown if .database returns nil' do
      expect(described_class.db_config_database(nil)).to eq('unknown')
    end
  end

  describe '.db_config_names' do
    using RSpec::Parameterized::TableSyntax

    where(:configs_for, :gitlab_schema, :expected_main, :expected_main_ci) do
      %i[main] | :gitlab_shared | %i[main] | %i[main]
      %i[main ci] | :gitlab_shared | %i[main] | %i[main ci]
      %i[main ci] | :gitlab_ci | %i[main] | %i[ci]
    end

    with_them do
      before do
        hash_configs = configs_for.map do |x|
          instance_double(ActiveRecord::DatabaseConfigurations::HashConfig, name: x)
        end
        allow(::ActiveRecord::Base).to receive(:configurations).and_return(
          instance_double(ActiveRecord::DatabaseConfigurations, configs_for: hash_configs)
        )
      end

      if ::Gitlab::Database.has_config?(:ci)
        it 'when main and CI database are configured' do
          expect(described_class.db_config_names(with_schema: gitlab_schema))
            .to eq(expected_main_ci)
        end
      else
        it 'when only main database is configured' do
          expect(described_class.db_config_names(with_schema: gitlab_schema))
            .to eq(expected_main)
        end
      end
    end
  end

  describe '.db_config_share_with' do
    using RSpec::Parameterized::TableSyntax

    where(:db_config_name, :db_config_attributes, :expected_db_config_share_with) do
      'main'             | { database_tasks: true }  | nil
      'main'             | { database_tasks: false } | nil
      'ci'               | { database_tasks: true }  | nil
      'ci'               | { database_tasks: false } | 'main'
      'main_clusterwide' | { database_tasks: true }  | nil
      'main_clusterwide' | { database_tasks: false } | 'main'
      '_test_unknown'    | { database_tasks: true }  | nil
      '_test_unknown'    | { database_tasks: false } | 'main'
    end

    with_them do
      it 'returns the expected result' do
        db_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
          Rails.env,
          db_config_name,
          db_config_attributes
        )

        expect(described_class.db_config_share_with(db_config)).to eq(expected_db_config_share_with)
      end
    end
  end

  describe '.gitlab_schemas_for_connection' do
    it 'does return a valid schema depending on a base model used', :request_store do
      expect(described_class.gitlab_schemas_for_connection(Project.connection)).to include(:gitlab_main, :gitlab_shared)
      expect(described_class.gitlab_schemas_for_connection(Ci::Build.connection)).to include(:gitlab_ci, :gitlab_shared)
    end

    # rubocop:disable Database/MultipleDatabases
    it 'does return gitlab_ci when a ActiveRecord::Base is using CI connection' do
      with_reestablished_active_record_base do
        reconfigure_db_connection(model: ActiveRecord::Base, config_model: Ci::Build)

        expect(
          described_class.gitlab_schemas_for_connection(ActiveRecord::Base.connection)
        ).to include(:gitlab_ci, :gitlab_shared)
      end
    end
    # rubocop:enable Database/MultipleDatabases

    it 'does return a valid schema for a replica connection' do
      with_replica_pool_for(ActiveRecord::Base) do |main_replica_pool|
        expect(described_class.gitlab_schemas_for_connection(main_replica_pool.connection)).to include(:gitlab_main, :gitlab_shared)
      end

      with_replica_pool_for(Ci::ApplicationRecord) do |ci_replica_pool|
        expect(described_class.gitlab_schemas_for_connection(ci_replica_pool.connection)).to include(:gitlab_ci, :gitlab_shared)
      end
    end

    def with_replica_pool_for(base_model)
      config = Gitlab::Database::LoadBalancing::Configuration.new(base_model, [base_model.connection_pool.db_config.host])
      lb = Gitlab::Database::LoadBalancing::LoadBalancer.new(config)
      pool = lb.create_replica_connection_pool(1)

      yield pool
    ensure
      pool&.disconnect!
    end

    context "when there's CI connection" do
      before do
        skip_if_multiple_databases_not_setup(:ci)
      end

      context 'when CI uses database_tasks: false does indicate that ci: is subset of main:' do
        before do
          allow(Ci::ApplicationRecord.connection_db_config).to receive(:database_tasks?).and_return(false)
        end

        it 'does return gitlab_ci when accessing via main: connection' do
          expect(described_class.gitlab_schemas_for_connection(Project.connection)).to include(:gitlab_ci, :gitlab_main, :gitlab_shared)
        end

        it 'does not return gitlab_main when accessing via ci: connection' do
          expect(described_class.gitlab_schemas_for_connection(Ci::Build.connection)).to include(:gitlab_ci, :gitlab_shared)
          expect(described_class.gitlab_schemas_for_connection(Ci::Build.connection)).not_to include(:gitlab_main)
        end
      end

      context 'when CI uses database_tasks: true does indicate that ci: has own database' do
        before do
          allow(Ci::ApplicationRecord.connection_db_config).to receive(:database_tasks?).and_return(true)
        end

        it 'does not return gitlab_ci when accessing via main: connection' do
          expect(described_class.gitlab_schemas_for_connection(Project.connection)).to include(:gitlab_main, :gitlab_shared)
          expect(described_class.gitlab_schemas_for_connection(Project.connection)).not_to include(:gitlab_ci)
        end

        it 'does not return gitlab_main when accessing via ci: connection' do
          expect(described_class.gitlab_schemas_for_connection(Ci::Build.connection)).to include(:gitlab_ci, :gitlab_shared)
          expect(described_class.gitlab_schemas_for_connection(Ci::Build.connection)).not_to include(:gitlab_main)
        end
      end
    end

    it 'does return empty for non-adopted connections' do
      new_connection = ActiveRecord::Base.postgresql_connection(
        ActiveRecord::Base.connection_db_config.configuration_hash # rubocop:disable Database/MultipleDatabases
      )

      expect(described_class.gitlab_schemas_for_connection(new_connection)).to be_nil
    ensure
      new_connection&.disconnect!
    end

    it 'returns nil when database model does not exist' do
      connection = Project.connection
      db_config = double(name: 'unknown')

      expect(described_class).to receive(:db_config_for_connection).with(connection).and_return(db_config)
      expect(described_class.gitlab_schemas_for_connection(connection)).to be_nil
    end
  end

  describe '.database_base_models_with_gitlab_shared' do
    before do
      described_class.instance_variable_set(:@database_base_models_with_gitlab_shared, nil)
    end

    it 'memoizes the models' do
      expect { described_class.database_base_models_with_gitlab_shared }.to change { Gitlab::Database.instance_variable_get(:@database_base_models_with_gitlab_shared) }.from(nil)
    end
  end

  describe '.database_base_models_using_load_balancing' do
    before do
      described_class.instance_variable_set(:@database_base_models_using_load_balancing, nil)
    end

    it 'memoizes the models' do
      expect { described_class.database_base_models_using_load_balancing }.to change { Gitlab::Database.instance_variable_get(:@database_base_models_using_load_balancing) }.from(nil)
    end
  end

  describe '.application_record_for_connection' do
    it 'returns ApplicationRecord for main database connection' do
      connection = ApplicationRecord.retrieve_connection
      expect(described_class.application_record_for_connection(connection)).to eq(ApplicationRecord)
    end

    it 'returns Ci::ApplicationRecord for ci database connection' do
      skip_if_multiple_databases_not_setup(:ci)

      connection = Ci::ApplicationRecord.retrieve_connection
      expect(described_class.application_record_for_connection(connection)).to eq(Ci::ApplicationRecord)
    end
  end

  describe '#true_value' do
    it 'returns correct value' do
      expect(described_class.true_value).to eq "'t'"
    end
  end

  describe '#false_value' do
    it 'returns correct value' do
      expect(described_class.false_value).to eq "'f'"
    end
  end

  describe '#sanitize_timestamp' do
    let(:max_timestamp) { Time.at((1 << 31) - 1) }

    subject { described_class.sanitize_timestamp(timestamp) }

    context 'with a timestamp smaller than MAX_TIMESTAMP_VALUE' do
      let(:timestamp) { max_timestamp - 10.years }

      it 'returns the given timestamp' do
        expect(subject).to eq(timestamp)
      end
    end

    context 'with a timestamp larger than MAX_TIMESTAMP_VALUE' do
      let(:timestamp) { max_timestamp + 1.second }

      it 'returns MAX_TIMESTAMP_VALUE' do
        expect(subject).to eq(max_timestamp)
      end
    end
  end

  describe '.all_uncached' do
    let(:base_model) do
      Class.new do
        def self.uncached
          @uncached = true

          yield
        end

        def self.load_balancer
          lb = Struct.new(:name)
          lb.new(:main)
        end
      end
    end

    let(:model1) { Class.new(base_model) }
    let(:model2) { Class.new(base_model) }

    before do
      allow(described_class).to receive(:database_base_models_using_load_balancing)
        .and_return({ model1: model1, model2: model2 }.with_indifferent_access)
    end

    it 'wraps the given block in uncached calls for each primary connection', :aggregate_failures do
      expect(model1.instance_variable_get(:@uncached)).to be_nil
      expect(model2.instance_variable_get(:@uncached)).to be_nil

      expect(Gitlab::Database::LoadBalancing::SessionMap.current(::ApplicationRecord.load_balancer))
        .to receive(:use_primary).twice.and_yield

      expect(model2).to receive(:uncached).and_call_original
      expect(model1).to receive(:uncached).and_call_original

      yielded_to_block = false
      described_class.all_uncached do
        expect(model1.instance_variable_get(:@uncached)).to be(true)
        expect(model2.instance_variable_get(:@uncached)).to be(true)

        yielded_to_block = true
      end

      expect(yielded_to_block).to be(true)
    end
  end

  describe '.read_only?' do
    it 'returns false' do
      expect(described_class.read_only?).to eq(false)
    end
  end

  describe '.read_write' do
    it 'returns true' do
      expect(described_class.read_write?).to eq(true)
    end
  end

  describe 'ActiveRecordBaseTransactionMetrics' do
    def subscribe_events
      events = []

      begin
        subscriber = ActiveSupport::Notifications.subscribe('transaction.active_record') do |e|
          events << e
        end

        yield
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
      end

      events
    end

    context 'without a transaction block' do
      it 'does not publish a transaction event' do
        events = subscribe_events do
          User.first
        end

        expect(events).to be_empty
      end
    end

    context 'within a transaction block' do
      it 'publishes a transaction event' do
        events = subscribe_events do
          ApplicationRecord.transaction do
            User.first
          end
        end

        expect(events.length).to be(1)

        event = events.first
        expect(event).not_to be_nil
        expect(event.duration).to be > 0.0

        unless ::Gitlab.next_rails?
          expect(event.payload).to a_hash_including(
            connection: be_a(Gitlab::Database::LoadBalancing::ConnectionProxy)
          )
        end
      end
    end

    unless ::Gitlab.next_rails?
      context 'within an empty transaction block' do
        it 'publishes a transaction event' do
          events = subscribe_events do
            ApplicationRecord.transaction {}
            Ci::ApplicationRecord.transaction {}
          end

          expect(events.length).to be(2)

          event = events.first
          expect(event).not_to be_nil
          expect(event.duration).to be > 0.0
          expect(event.payload).to a_hash_including(
            connection: be_a(Gitlab::Database::LoadBalancing::ConnectionProxy)
          )
        end
      end
    end

    context 'within a nested transaction block' do
      it 'publishes multiple transaction events' do
        events = subscribe_events do
          ApplicationRecord.transaction do
            User.first

            ApplicationRecord.transaction(requires_new: true) do
              User.first

              ApplicationRecord.transaction(requires_new: true) do
                User.first
              end
            end
          end
        end

        expect(events.length).to be(3)

        events.each do |event|
          expect(event).not_to be_nil
          expect(event.duration).to be > 0.0
        end
      end
    end

    context 'within a cancelled transaction block' do
      it 'publishes multiple transaction events' do
        events = subscribe_events do
          ApplicationRecord.transaction do
            User.first
            raise ActiveRecord::Rollback
          end
        end

        expect(events.length).to be(1)

        event = events.first
        expect(event).not_to be_nil
        expect(event.duration).to be > 0.0
      end
    end
  end

  describe '.read_minimum_migration_version' do
    before do
      allow(Dir).to receive(:open).with(Rails.root.join('db/migrate')).and_return(migration_files)
    end

    context 'valid migration files exist' do
      let(:migration_files) do
        [
          '20211004170422_init_schema.rb',
          '20211005182304_add_users.rb'
        ]
      end

      let(:valid_schema) { 20211004170422 }

      it 'finds the correct ID' do
        expect(described_class.read_minimum_migration_version).to eq valid_schema
      end
    end

    context 'no valid migration files exist' do
      let(:migration_files) { ['readme.txt', 'INSTALL'] }

      it 'returns nil' do
        expect(described_class.read_minimum_migration_version).to be_nil
      end
    end
  end
end
