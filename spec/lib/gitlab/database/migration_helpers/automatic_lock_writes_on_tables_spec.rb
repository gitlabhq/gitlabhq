# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::AutomaticLockWritesOnTables,
  :reestablished_active_record_base, :delete, query_analyzers: false, feature_category: :cell do
  using RSpec::Parameterized::TableSyntax

  let(:schema_class) { Class.new(Gitlab::Database::Migration[2.1]) }
  let(:skip_automatic_lock_on_writes) { false }
  let(:gitlab_main_table_name) { :_test_gitlab_main_table }
  let(:gitlab_main_clusterwide_table_name) { :_test_gitlab_main_clusterwide_table }
  let(:gitlab_main_cell_table_name) { :_test_gitlab_main_cell_table }
  let(:gitlab_ci_table_name) { :_test_gitlab_ci_table }
  let(:gitlab_pm_table_name) { :_test_gitlab_pm_table }
  let(:gitlab_sec_table_name) { :_test_gitlab_sec_table }
  let(:gitlab_geo_table_name) { :_test_gitlab_geo_table }
  let(:gitlab_shared_table_name) { :_test_table }

  let(:renamed_gitlab_main_table_name) { :_test_gitlab_main_new_table }
  let(:renamed_gitlab_ci_table_name) { :_test_gitlab_ci_new_table }

  before do
    stub_feature_flags(automatic_lock_writes_on_table: true)
    reconfigure_db_connection(model: ActiveRecord::Base, config_model: config_model)
  end

  # Drop the created test tables, because we use non-transactional tests
  after do
    drop_table_if_exists(gitlab_main_table_name)
    drop_table_if_exists(gitlab_main_clusterwide_table_name)
    drop_table_if_exists(gitlab_main_cell_table_name)
    drop_table_if_exists(gitlab_ci_table_name)
    drop_table_if_exists(gitlab_geo_table_name)
    drop_table_if_exists(gitlab_pm_table_name)
    drop_table_if_exists(gitlab_sec_table_name)
    drop_table_if_exists(gitlab_shared_table_name)
    drop_table_if_exists(renamed_gitlab_main_table_name)
    drop_table_if_exists(renamed_gitlab_ci_table_name)
  end

  shared_examples 'does not lock writes on table' do |config_model|
    let(:config_model) { config_model }

    it 'allows deleting records from the table' do
      expect(Gitlab::Database::LockWritesManager).not_to receive(:new)

      run_migration

      expect do
        migration_class.connection.execute("DELETE FROM #{table_name}")
      end.not_to raise_error
    end
  end

  shared_examples 'locks writes on table' do |config_model|
    let(:config_model) { config_model }

    it 'errors on deleting' do
      expect_next_instance_of(Gitlab::Database::LockWritesManager) do |instance|
        expect(instance).to receive(:lock_writes).and_call_original
      end
      expect(Gitlab::Database::WithLockRetries).not_to receive(:new)

      run_migration

      expect do
        migration_class.connection.execute("DELETE FROM #{table_name}")
      end.to raise_error(ActiveRecord::StatementInvalid, /is write protected/)
    end
  end

  shared_examples 'locks writes on table using WithLockRetries' do |config_model|
    let(:config_model) { config_model }

    it 'locks the writes on the table using WithLockRetries' do
      expect_next_instance_of(Gitlab::Database::WithLockRetries) do |instance|
        expect(instance).to receive(:run).and_call_original
      end

      run_migration

      expect do
        migration_class.connection.execute("DELETE FROM #{table_name}")
      end.to raise_error(ActiveRecord::StatementInvalid, /is write protected/)
    end
  end

  context 'when executing create_table migrations' do
    context 'when single database' do
      let(:config_model) { Gitlab::Database.database_base_models[:main] }
      let(:create_gitlab_main_table_migration_class) { create_table_migration(gitlab_main_table_name) }
      let(:create_gitlab_main_cell_table_migration_class) { create_table_migration(gitlab_main_cell_table_name) }
      let(:create_gitlab_ci_table_migration_class) { create_table_migration(gitlab_ci_table_name) }
      let(:create_gitlab_shared_table_migration_class) { create_table_migration(gitlab_shared_table_name) }
      let(:create_gitlab_main_clusterwide_table_migration_class) do
        create_table_migration(gitlab_main_clusterwide_table_name)
      end

      before do
        skip_if_database_exists(:ci)
      end

      it 'does not lock any newly created tables' do
        expect(Gitlab::Database::LockWritesManager).not_to receive(:new)

        create_gitlab_main_table_migration_class.migrate(:up)
        create_gitlab_main_cell_table_migration_class.migrate(:up)
        create_gitlab_main_clusterwide_table_migration_class.migrate(:up)
        create_gitlab_ci_table_migration_class.migrate(:up)
        create_gitlab_shared_table_migration_class.migrate(:up)

        expect do
          create_gitlab_main_table_migration_class.connection.execute("DELETE FROM #{gitlab_main_table_name}")
          create_gitlab_main_cell_table_migration_class.connection.execute("DELETE FROM #{gitlab_main_cell_table_name}")
          create_gitlab_ci_table_migration_class.connection.execute("DELETE FROM #{gitlab_ci_table_name}")
          create_gitlab_shared_table_migration_class.connection.execute("DELETE FROM #{gitlab_shared_table_name}")
          create_gitlab_main_clusterwide_table_migration_class.connection.execute(
            "DELETE FROM #{gitlab_main_clusterwide_table_name}"
          )
        end.not_to raise_error
      end
    end

    context 'when multiple databases' do
      before do
        skip_if_shared_database(:ci)
      end

      let(:migration_class) { create_table_migration(table_name, skip_automatic_lock_on_writes) }
      let(:run_migration) do
        migration_class.connection.transaction do
          migration_class.migrate(:up)
        end
      end

      context 'for creating a gitlab_main table' do
        let(:table_name) { gitlab_main_table_name }

        it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:main]
        it_behaves_like 'locks writes on table', Gitlab::Database.database_base_models[:ci]

        context 'when table listed as a deleted table' do
          before do
            allow(Gitlab::Database::GitlabSchema).to receive(:deleted_tables_to_schema).and_return(
              { table_name.to_s => :gitlab_main }
            )
          end

          it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:ci]
        end

        context 'when the migration skips automatic locking of tables' do
          let(:skip_automatic_lock_on_writes) { true }

          it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:ci]
        end

        context 'when migration does not run within a transaction' do
          let(:run_migration) do
            migration_class.migrate(:up)
          end

          it_behaves_like 'locks writes on table using WithLockRetries', Gitlab::Database.database_base_models[:ci]
        end

        context 'when the SKIP_AUTOMATIC_LOCK_ON_WRITES feature flag is set' do
          before do
            stub_env('SKIP_AUTOMATIC_LOCK_ON_WRITES' => 'true')
          end

          it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:ci]
        end

        context 'when the automatic_lock_writes_on_table feature flag is disabled' do
          before do
            stub_feature_flags(automatic_lock_writes_on_table: false)
          end

          it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:ci]
        end
      end

      context 'for creating a gitlab_main_clusterwide table' do
        let(:table_name) { gitlab_main_clusterwide_table_name }

        it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:main]
        it_behaves_like 'locks writes on table', Gitlab::Database.database_base_models[:ci]
      end

      context 'for creating a gitlab_main_cell table' do
        let(:table_name) { gitlab_main_cell_table_name }

        it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:main]
        it_behaves_like 'locks writes on table', Gitlab::Database.database_base_models[:ci]
      end

      context 'for creating a gitlab_pm table' do
        let(:table_name) { gitlab_pm_table_name }

        it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:main]
        it_behaves_like 'locks writes on table', Gitlab::Database.database_base_models[:ci]
      end

      context 'for creating a gitlab_sec table' do
        before do
          skip_if_shared_database('sec')
        end

        let(:table_name) { gitlab_sec_table_name }

        it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:sec]
        it_behaves_like 'locks writes on table', Gitlab::Database.database_base_models[:main]
      end

      context 'for creating a gitlab_ci table' do
        let(:table_name) { gitlab_ci_table_name }

        it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:ci]
        it_behaves_like 'locks writes on table', Gitlab::Database.database_base_models[:main]

        context 'when table listed as a deleted table' do
          before do
            allow(Gitlab::Database::GitlabSchema).to receive(:deleted_tables_to_schema).and_return(
              { table_name.to_s => :gitlab_ci }
            )
          end

          it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:main]
        end

        context 'when the migration skips automatic locking of tables' do
          let(:skip_automatic_lock_on_writes) { true }

          it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:main]
        end

        context 'when the SKIP_AUTOMATIC_LOCK_ON_WRITES feature flag is set' do
          before do
            stub_env('SKIP_AUTOMATIC_LOCK_ON_WRITES' => 'true')
          end

          it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:main]
        end

        context 'when the automatic_lock_writes_on_table feature flag is disabled' do
          before do
            stub_feature_flags(automatic_lock_writes_on_table: false)
          end

          it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:main]
        end
      end

      context 'for creating gitlab_shared table' do
        let(:table_name) { gitlab_shared_table_name }

        it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:main]
        it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:ci]
      end

      context 'for creating a gitlab_geo table' do
        before do
          skip unless geo_configured?
        end

        let(:table_name) { gitlab_geo_table_name }

        it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:geo]
      end

      context 'for creating an unknown gitlab_schema table' do
        let(:table_name) { :foobar } # no gitlab_schema defined
        let(:config_model) { Gitlab::Database.database_base_models[:main] }

        it "raises an error about undefined gitlab_schema" do
          expect { run_migration }.to raise_error(
            Gitlab::Database::GitlabSchema::UnknownSchemaError,
            "Could not find gitlab schema for table foobar: " \
            "Any new or deleted tables must be added to the database dictionary " \
            "See https://docs.gitlab.com/ee/development/database/database_dictionary.html"
          )
        end
      end
    end
  end

  context 'when renaming a table' do
    before do
      skip_if_shared_database(:ci)
      create_table_migration(old_table_name).migrate(:up) # create the table first before renaming it
    end

    let(:migration_class) { rename_table_migration(old_table_name, table_name) }
    let(:run_migration) do
      migration_class.connection.transaction do
        migration_class.migrate(:up)
      end
    end

    context 'when a gitlab_main table' do
      let(:old_table_name) { gitlab_main_table_name }
      let(:table_name) { renamed_gitlab_main_table_name }
      let(:database_base_model) { Gitlab::Database.database_base_models[:main] }

      it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:main]
      it_behaves_like 'locks writes on table', Gitlab::Database.database_base_models[:ci]
    end

    context 'when a gitlab_ci table' do
      let(:old_table_name) { gitlab_ci_table_name }
      let(:table_name) { renamed_gitlab_ci_table_name }
      let(:database_base_model) { Gitlab::Database.database_base_models[:ci] }

      it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:ci]
      it_behaves_like 'locks writes on table', Gitlab::Database.database_base_models[:main]
    end
  end

  context 'when reversing drop_table migrations' do
    let(:drop_gitlab_main_table_migration_class) { drop_table_migration(gitlab_main_table_name) }
    let(:drop_gitlab_ci_table_migration_class) { drop_table_migration(gitlab_ci_table_name) }
    let(:drop_gitlab_shared_table_migration_class) { drop_table_migration(gitlab_shared_table_name) }

    context 'when single database' do
      let(:config_model) { Gitlab::Database.database_base_models[:main] }

      before do
        skip_if_database_exists(:ci)
      end

      it 'does not lock any newly created tables' do
        expect(Gitlab::Database::LockWritesManager).not_to receive(:new)

        drop_gitlab_main_table_migration_class.connection.execute("CREATE TABLE #{gitlab_main_table_name}()")
        drop_gitlab_ci_table_migration_class.connection.execute("CREATE TABLE #{gitlab_ci_table_name}()")
        drop_gitlab_shared_table_migration_class.connection.execute("CREATE TABLE #{gitlab_shared_table_name}()")

        drop_gitlab_main_table_migration_class.migrate(:up)
        drop_gitlab_ci_table_migration_class.migrate(:up)
        drop_gitlab_shared_table_migration_class.migrate(:up)

        drop_gitlab_main_table_migration_class.migrate(:down)
        drop_gitlab_ci_table_migration_class.migrate(:down)
        drop_gitlab_shared_table_migration_class.migrate(:down)

        expect do
          drop_gitlab_main_table_migration_class.connection.execute("DELETE FROM #{gitlab_main_table_name}")
          drop_gitlab_ci_table_migration_class.connection.execute("DELETE FROM #{gitlab_ci_table_name}")
          drop_gitlab_shared_table_migration_class.connection.execute("DELETE FROM #{gitlab_shared_table_name}")
        end.not_to raise_error
      end
    end

    context 'when multiple databases' do
      before do
        skip_if_shared_database(:ci)
        migration_class.connection.execute("CREATE TABLE #{table_name}()")
        migration_class.migrate(:up)
      end

      let(:migration_class) { drop_table_migration(table_name) }
      let(:run_migration) do
        migration_class.connection.transaction do
          migration_class.migrate(:down)
        end
      end

      context 'for re-creating a gitlab_main table' do
        let(:table_name) { gitlab_main_table_name }

        it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:main]
        it_behaves_like 'locks writes on table', Gitlab::Database.database_base_models[:ci]
      end

      context 'for re-creating a gitlab_ci table' do
        let(:table_name) { gitlab_ci_table_name }

        it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:ci]
        it_behaves_like 'locks writes on table', Gitlab::Database.database_base_models[:main]
      end

      context 'for re-creating a gitlab_shared table' do
        let(:table_name) { gitlab_shared_table_name }

        it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:main]
        it_behaves_like 'does not lock writes on table', Gitlab::Database.database_base_models[:ci]
      end
    end
  end

  def create_table_migration(table_name, skip_automatic_lock_on_writes = false)
    migration_class = Class.new(schema_class) do
      class << self; attr_accessor :table_name; end
      def change
        create_table self.class.table_name
      end
    end
    migration_class.skip_automatic_lock_on_writes = skip_automatic_lock_on_writes
    migration_class.tap { |klass| klass.table_name = table_name }
  end

  def rename_table_migration(old_table_name, new_table_name)
    migration_class = Class.new(schema_class) do
      class << self; attr_accessor :old_table_name, :new_table_name; end
      def change
        rename_table self.class.old_table_name, self.class.new_table_name
      end
    end

    migration_class.tap do |klass|
      klass.old_table_name = old_table_name
      klass.new_table_name = new_table_name
    end
  end

  def drop_table_migration(table_name)
    migration_class = Class.new(schema_class) do
      class << self; attr_accessor :table_name; end
      def change
        drop_table(self.class.table_name) {}
      end
    end
    migration_class.tap { |klass| klass.table_name = table_name }
  end

  def geo_configured?
    !!ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'geo')
  end

  # To drop the test tables that have been created in the test migrations
  def drop_table_if_exists(table_name)
    Gitlab::Database.database_base_models.each_value do |model|
      model.connection.execute("DROP TABLE IF EXISTS #{table_name}")
    end
  end
end
