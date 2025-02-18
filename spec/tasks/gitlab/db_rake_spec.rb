# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db namespace rake task', :silence_stdout, feature_category: :database do
  before(:all) do
    Rake.application.rake_require 'active_record/railties/databases'
    Rake.application.rake_require 'tasks/seed_fu'
    Rake.application.rake_require 'tasks/gitlab/click_house/migration'
    Rake.application.rake_require 'tasks/gitlab/db'
    Rake.application.rake_require 'tasks/gitlab/db/lock_writes'
    Rake.application.rake_require 'tasks/gitlab/db/alter_cell_sequences_range'
  end

  before do
    # Stub out db tasks
    allow(Rake::Task['db:migrate']).to receive(:invoke).and_return(true)
    allow(Rake::Task['db:schema:load']).to receive(:invoke).and_return(true)
    allow(Rake::Task['db:seed_fu']).to receive(:invoke).and_return(true)
    allow(Rake::Task['gitlab:db:lock_writes']).to receive(:invoke).and_return(true)
    stub_feature_flags(disallow_database_ddl_feature_flags: false)
  end

  describe 'gitlab:db:sos task' do
    it 'calls Gitlab::Database::Sos.run' do
      expect(Gitlab::Database::Sos).to receive(:run).and_call_original
      expect { run_rake_task('gitlab:db:sos') }.not_to raise_error
    end
  end

  describe 'mark_migration_complete' do
    context 'with a single database' do
      let(:main_model) { ApplicationRecord }

      before do
        skip_if_database_exists(:ci)
        skip_if_database_exists(:sec)
      end

      it 'marks the migration complete on the given database' do
        expect(main_model.connection).to receive(:quote).and_call_original
        expect(main_model.connection).to receive(:execute)
          .with("INSERT INTO schema_migrations (version) VALUES ('123')")

        run_rake_task('gitlab:db:mark_migration_complete', '[123]')
      end
    end

    context 'with multiple databases' do
      let(:main_model) { double(:model, connection: double(:connection)) }
      let(:ci_model) { double(:model, connection: double(:connection)) }
      let(:sec_model) { double(:model, connection: double(:connection)) }
      let(:base_models) do
        models = { 'main' => main_model, 'ci' => ci_model }
        models['sec'] = sec_model if database_exists?('sec')
        models
      end

      before do
        skip_if_shared_database(:ci)

        allow(Gitlab::Database).to receive(:database_base_models_with_gitlab_shared).and_return(base_models)
      end

      it 'marks the migration complete on each database' do
        expect(main_model.connection).to receive(:quote).with('123').and_return("'123'")
        expect(main_model.connection).to receive(:execute)
          .with("INSERT INTO schema_migrations (version) VALUES ('123')")

        expect(ci_model.connection).to receive(:quote).with('123').and_return("'123'")
        expect(ci_model.connection).to receive(:execute)
          .with("INSERT INTO schema_migrations (version) VALUES ('123')")

        if database_exists?('sec')
          expect(sec_model.connection).to receive(:quote).with('123').and_return("'123'")
          expect(sec_model.connection).to receive(:execute)
            .with("INSERT INTO schema_migrations (version) VALUES ('123')")
        end

        run_rake_task('gitlab:db:mark_migration_complete', '[123]')
      end

      context 'when the single database task is used' do
        it 'marks the migration complete for the given database' do
          expect(main_model.connection).to receive(:quote).with('123').and_return("'123'")
          expect(main_model.connection).to receive(:execute)
            .with("INSERT INTO schema_migrations (version) VALUES ('123')")

          expect(ci_model.connection).not_to receive(:quote)
          expect(ci_model.connection).not_to receive(:execute)

          if database_exists?('sec')
            expect(sec_model.connection).not_to receive(:quote)
            expect(sec_model.connection).not_to receive(:execute)
          end

          run_rake_task('gitlab:db:mark_migration_complete:main', '[123]')
        end
      end

      context 'with geo configured' do
        before do
          skip_unless_geo_configured
        end

        it 'does not create a task for the geo database' do
          expect { run_rake_task('gitlab:db:mark_migration_complete:geo') }
            .to raise_error(/Don't know how to build task 'gitlab:db:mark_migration_complete:geo'/)
        end
      end
    end

    context 'when the migration is already marked complete' do
      let(:main_model) { double(:model, connection: double(:connection)) }
      let(:base_models) { { 'main' => main_model } }

      before do
        allow(Gitlab::Database).to receive(:database_base_models_with_gitlab_shared).and_return(base_models)
      end

      it 'prints a warning message' do
        allow(main_model.connection).to receive(:quote).with('123').and_return("'123'")

        expect(main_model.connection).to receive(:execute)
          .with("INSERT INTO schema_migrations (version) VALUES ('123')")
          .and_raise(ActiveRecord::RecordNotUnique)

        expect { run_rake_task('gitlab:db:mark_migration_complete', '[123]') }
          .to output(/Migration version '123' is already marked complete on database main/).to_stdout
      end
    end

    context 'when an invalid version is given' do
      let(:main_model) { double(:model, connection: double(:connection)) }
      let(:base_models) { { 'main' => main_model } }

      before do
        allow(Gitlab::Database).to receive(:database_base_models_with_gitlab_shared).and_return(base_models)
      end

      it 'prints an error and exits' do
        expect(main_model).not_to receive(:quote)
        expect(main_model.connection).not_to receive(:execute)

        expect { run_rake_task('gitlab:db:mark_migration_complete', '[abc]') }
          .to output(/Must give a version argument that is a non-zero integer/).to_stdout
          .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      end
    end
  end

  describe 'configure' do
    let(:topology_service_enabled) { true }
    let(:configured_cell) { true }
    let(:skip_sequence_alteration) { false }

    before do
      allow(Settings).to receive(:topology_service_enabled?).and_return(topology_service_enabled)
      allow(Settings).to receive(:skip_sequence_alteration?).and_return(skip_sequence_alteration)
    end

    context 'with a single database' do
      let(:connection) { Gitlab::Database.database_base_models[:main].connection }
      let(:main_config) { double(:config, name: 'main') }

      before do
        skip_if_database_exists(:ci)

        allow_next_instance_of(Gitlab::TopologyServiceClient::CellService) do |instance|
          allow(instance).to receive(:cell_sequence_range).and_return([0, 1000])
        end
      end

      context 'when geo is not configured' do
        before do
          allow(ActiveRecord::Base).to receive_message_chain('configurations.configs_for').and_return([main_config])
          allow(Gitlab::Database).to receive(:has_config?).with(:geo).and_return(false)
        end

        context 'when the schema is already loaded' do
          it 'migrates the database' do
            allow(connection).to receive(:tables).and_return(%w[table1 table2])

            expect(Rake::Task['db:migrate']).to receive(:invoke)
            expect(Rake::Task['db:schema:load']).not_to receive(:invoke)
            expect(Rake::Task['gitlab:db:lock_writes']).not_to receive(:invoke)
            expect(Rake::Task['db:seed_fu']).not_to receive(:invoke)
            expect(Rake::Task['gitlab:db:alter_cell_sequences_range']).not_to receive(:invoke)

            run_rake_task('gitlab:db:configure')
          end
        end

        context 'when the schema is not loaded' do
          it 'loads the schema and seeds the database' do
            allow(connection).to receive(:tables).and_return([])

            expect(Rake::Task['db:schema:load']).to receive(:invoke)
            expect(Rake::Task['gitlab:db:lock_writes']).to receive(:invoke)
            expect(Rake::Task['db:seed_fu']).to receive(:invoke)
            expect(Rake::Task['db:migrate']).not_to receive(:invoke)
            expect(Rake::Task['gitlab:db:alter_cell_sequences_range']).to receive(:invoke).with(0, 1000)

            run_rake_task('gitlab:db:configure')
          end
        end

        context 'when only a single table is present' do
          it 'loads the schema and seeds the database' do
            allow(connection).to receive(:tables).and_return(['default'])

            expect(Rake::Task['db:schema:load']).to receive(:invoke)
            expect(Rake::Task['gitlab:db:lock_writes']).to receive(:invoke)
            expect(Rake::Task['db:seed_fu']).to receive(:invoke)
            expect(Rake::Task['db:migrate']).not_to receive(:invoke)
            expect(Rake::Task['gitlab:db:alter_cell_sequences_range']).to receive(:invoke).with(0, 1000)

            run_rake_task('gitlab:db:configure')
          end
        end

        context 'when loading the schema fails' do
          it 'does not seed the database' do
            allow(connection).to receive(:tables).and_return([])

            expect(Rake::Task['db:schema:load']).to receive(:invoke).and_raise('error')
            expect(Rake::Task['gitlab:db:lock_writes']).not_to receive(:invoke)
            expect(Rake::Task['db:seed_fu']).not_to receive(:invoke)
            expect(Rake::Task['db:migrate']).not_to receive(:invoke)
            expect(Rake::Task['gitlab:db:alter_cell_sequences_range']).not_to receive(:invoke)

            expect { run_rake_task('gitlab:db:configure') }.to raise_error(RuntimeError, 'error')
          end
        end

        context 'SKIP_POST_DEPLOYMENT_MIGRATIONS environment variable set' do
          let(:rails_paths) { { 'db' => ['db'], 'db/migrate' => ['db/migrate'] } }

          before do
            stub_env('SKIP_POST_DEPLOYMENT_MIGRATIONS', true)

            # Our environment has already been loaded, so we need to pretend like post_migrations were not
            allow(Rails.application.config).to receive(:paths).and_return(rails_paths)
            allow(ActiveRecord::Migrator).to receive(:migrations_paths).and_return(rails_paths['db/migrate'].dup)
          end

          context 'when the schema is not loaded' do
            it 'adds the post deployment migration path before schema load' do
              allow(connection).to receive(:tables).and_return([])

              expect(Gitlab::Database).to receive(:add_post_migrate_path_to_rails).and_call_original
              expect(Rake::Task['db:schema:load']).to receive(:invoke)
              expect(Rake::Task['gitlab:db:lock_writes']).to receive(:invoke)
              expect(Rake::Task['db:seed_fu']).to receive(:invoke)
              expect(Rake::Task['db:migrate']).not_to receive(:invoke)
              expect(Rake::Task['gitlab:db:alter_cell_sequences_range']).to receive(:invoke).with(0, 1000)

              run_rake_task('gitlab:db:configure')

              expect(rails_paths['db/migrate'].include?(File.join(Rails.root, 'db', 'post_migrate'))).to be(true)
            end
          end

          context 'when the schema is loaded' do
            it 'ignores post deployment migrations' do
              allow(connection).to receive(:tables).and_return(%w[table1 table2])

              expect(Rake::Task['db:migrate']).to receive(:invoke)
              expect(Gitlab::Database).not_to receive(:add_post_migrate_path_to_rails)
              expect(Rake::Task['db:schema:load']).not_to receive(:invoke)
              expect(Rake::Task['gitlab:db:lock_writes']).not_to receive(:invoke)
              expect(Rake::Task['db:seed_fu']).not_to receive(:invoke)
              expect(Rake::Task['gitlab:db:alter_cell_sequences_range']).not_to receive(:invoke)

              run_rake_task('gitlab:db:configure')

              expect(rails_paths['db/migrate'].include?(File.join(Rails.root, 'db', 'post_migrate'))).to be(false)
            end
          end
        end

        context 'when has cell configuration but config skips altering cell sequences' do
          let(:skip_sequence_alteration) { true }

          it 'loads the schema, seeds the database and skip altering cell sequences range' do
            allow(connection).to receive(:tables).and_return([])

            expect(Rake::Task['db:schema:load']).to receive(:invoke)
            expect(Rake::Task['gitlab:db:lock_writes']).to receive(:invoke)
            expect(Rake::Task['db:seed_fu']).to receive(:invoke)
            expect(Rake::Task['db:migrate']).not_to receive(:invoke)
            expect(Rake::Task['gitlab:db:alter_cell_sequences_range']).not_to receive(:invoke)

            run_rake_task('gitlab:db:configure')
          end
        end
      end

      context 'when geo is configured' do
        context 'when the main database is also configured' do
          before do
            skip_unless_geo_configured
          end

          it 'only configures the main database' do
            allow(connection).to receive(:tables).and_return(%w[table1 table2])

            expect(Rake::Task['db:migrate:main']).to receive(:invoke)

            expect(Rake::Task['db:migrate:geo']).not_to receive(:invoke)
            expect(Rake::Task['db:schema:load:geo']).not_to receive(:invoke)

            expect(Rake::Task['gitlab:db:alter_cell_sequences_range']).not_to receive(:invoke)

            run_rake_task('gitlab:db:configure')
          end
        end
      end
    end

    context 'with multiple databases' do
      let(:main_model) { double(:model, connection: double(:connection)) }
      let(:ci_model) { double(:model, connection: double(:connection)) }
      let(:sec_model) { double(:model, connection: double(:connection)) }
      let(:base_models) do
        models = { 'main' => main_model, 'ci' => ci_model }.with_indifferent_access
        models['sec'] = sec_model if database_exists?('sec')
        models
      end

      let(:main_config) { double(:config, name: 'main') }
      let(:ci_config) { double(:config, name: 'ci') }

      before do
        skip_if_shared_database(:ci)

        allow(Gitlab::Database).to receive(:database_base_models_with_gitlab_shared).and_return(base_models)

        allow_next_instance_of(Gitlab::TopologyServiceClient::CellService) do |instance|
          allow(instance).to receive(:cell_sequence_range).and_return([0, 1000])
        end
      end

      context 'when geo is not configured' do
        before do
          allow(ActiveRecord::Base).to receive_message_chain('configurations.configs_for')
            .and_return([main_config, ci_config])
        end

        context 'when no database has the schema loaded' do
          before do
            allow(main_model.connection).to receive(:tables).and_return(%w[schema_migrations])
            allow(ci_model.connection).to receive(:tables).and_return([])
          end

          it 'loads the schema, seeds all the databases and alter cell sequences range' do
            expect(Rake::Task['db:schema:load:main']).to receive(:invoke)
            expect(Rake::Task['db:schema:load:ci']).to receive(:invoke)

            expect(Rake::Task['db:migrate:main']).not_to receive(:invoke)
            expect(Rake::Task['db:migrate:ci']).not_to receive(:invoke)

            expect(Rake::Task['gitlab:db:lock_writes']).to receive(:invoke)
            expect(Rake::Task['db:seed_fu']).to receive(:invoke)

            expect(Rake::Task['gitlab:db:alter_cell_sequences_range']).to receive(:invoke).with(0, 1000)

            run_rake_task('gitlab:db:configure')
          end
        end

        context 'when both databases have the schema loaded' do
          before do
            allow(main_model.connection).to receive(:tables).and_return(%w[table1 table2])
            allow(ci_model.connection).to receive(:tables).and_return(%w[table1 table2])
          end

          it 'migrates the databases without seeding them and alter cell sequences range' do
            expect(Rake::Task['db:migrate:main']).to receive(:invoke)
            expect(Rake::Task['db:migrate:ci']).to receive(:invoke)

            expect(Rake::Task['db:schema:load:main']).not_to receive(:invoke)
            expect(Rake::Task['db:schema:load:ci']).not_to receive(:invoke)

            expect(Rake::Task['gitlab:db:lock_writes']).not_to receive(:invoke)
            expect(Rake::Task['db:seed_fu']).not_to receive(:invoke)

            expect(Rake::Task['gitlab:db:alter_cell_sequences_range']).not_to receive(:invoke)

            run_rake_task('gitlab:db:configure')
          end
        end

        context 'when only one database has the schema loaded' do
          before do
            allow(main_model.connection).to receive(:tables).and_return(%w[table1 table2])
            allow(ci_model.connection).to receive(:tables).and_return([])
          end

          it 'migrates, loads the schema correctly and alter cell sequences without seeding the databases' do
            expect(Rake::Task['db:migrate:main']).to receive(:invoke)
            expect(Rake::Task['db:schema:load:main']).not_to receive(:invoke)

            expect(Rake::Task['db:schema:load:ci']).to receive(:invoke)
            expect(Rake::Task['db:migrate:ci']).not_to receive(:invoke)

            expect(Rake::Task['db:seed_fu']).not_to receive(:invoke)

            expect(Rake::Task['gitlab:db:alter_cell_sequences_range']).not_to receive(:invoke)

            run_rake_task('gitlab:db:configure')
          end
        end

        context 'when has cell configuration but has no sequence range available' do
          before do
            allow(main_model.connection).to receive(:tables).and_return(%w[schema_migrations])
            allow(ci_model.connection).to receive(:tables).and_return([])

            allow_next_instance_of(Gitlab::TopologyServiceClient::CellService) do |instance|
              allow(instance).to receive(:cell_sequence_range).and_return(nil)
            end
          end

          it 'loads the schema, seeds all the databases but does not alter cell sequences range' do
            expect(Rake::Task['db:schema:load:main']).to receive(:invoke)
            expect(Rake::Task['db:schema:load:ci']).to receive(:invoke)

            expect(Rake::Task['db:migrate:main']).not_to receive(:invoke)
            expect(Rake::Task['db:migrate:ci']).not_to receive(:invoke)

            expect(Rake::Task['gitlab:db:lock_writes']).to receive(:invoke)
            expect(Rake::Task['db:seed_fu']).to receive(:invoke)

            expect(Rake::Task['gitlab:db:alter_cell_sequences_range']).not_to receive(:invoke)

            run_rake_task('gitlab:db:configure')
          end
        end

        context 'when has cell configuration but config skips altering cell sequences' do
          let(:skip_sequence_alteration) { true }

          before do
            allow(main_model.connection).to receive(:tables).and_return(%w[schema_migrations])
            allow(ci_model.connection).to receive(:tables).and_return([])
          end

          it 'migrates the databases without seeding them and skip altering cell sequences range' do
            expect(Rake::Task['db:schema:load:main']).to receive(:invoke)
            expect(Rake::Task['db:schema:load:ci']).to receive(:invoke)

            expect(Rake::Task['db:migrate:main']).not_to receive(:invoke)
            expect(Rake::Task['db:migrate:ci']).not_to receive(:invoke)

            expect(Rake::Task['gitlab:db:lock_writes']).to receive(:invoke)
            expect(Rake::Task['db:seed_fu']).to receive(:invoke)

            expect(Rake::Task['gitlab:db:alter_cell_sequences_range']).not_to receive(:invoke)

            run_rake_task('gitlab:db:configure')
          end
        end
      end

      context 'when geo is configured' do
        let(:geo_config) { double(:config, name: 'geo') }

        before do
          skip_unless_geo_configured

          allow(main_model.connection).to receive(:tables).and_return(%w[schema_migrations])
          allow(ci_model.connection).to receive(:tables).and_return(%w[schema_migrations])
        end

        it 'does not run tasks against geo' do
          expect(Rake::Task['db:schema:load:main']).to receive(:invoke)
          expect(Rake::Task['db:schema:load:ci']).to receive(:invoke)
          expect(Rake::Task['db:seed_fu']).to receive(:invoke)

          expect(Rake::Task['db:migrate:geo']).not_to receive(:invoke)
          expect(Rake::Task['db:schema:load:geo']).not_to receive(:invoke)

          expect(Rake::Task['gitlab:db:alter_cell_sequences_range']).to receive(:invoke)

          run_rake_task('gitlab:db:configure')
        end
      end
    end

    describe 'clickhouse migrations' do
      let(:connection) { Gitlab::Database.database_base_models[:main].connection }
      let(:main_config) { double(:config, name: 'main') }

      before do
        # stub normal migrations
        allow(ActiveRecord::Base).to receive_message_chain('configurations.configs_for').and_return([main_config])
        allow(connection).to receive(:tables).and_return(%w[table1 table2])
        allow(Rake::Task['db:migrate']).to receive(:invoke)
      end

      it 'migrates clickhouse database' do
        expect(Rake::Task['gitlab:clickhouse:migrate']).to receive(:invoke).with(true)

        run_rake_task('gitlab:db:configure')
      end

      it 'does not fail if clickhouse is not configured' do
        allow(::ClickHouse::Client).to receive(:configuration).and_return(::ClickHouse::Client::Configuration.new)

        Rake::Task['gitlab:clickhouse:migrate'].reenable
        Rake::Task['gitlab:clickhouse:migrate:main'].reenable

        expect do
          run_rake_task('gitlab:db:configure')
        end.to output(/The 'main' ClickHouse database is not configured, skipping migrations/).to_stdout
      end
    end
  end

  describe 'schema inconsistencies' do
    let(:runner) { instance_double(Gitlab::Schema::Validation::Runner, execute: inconsistencies) }
    let(:inconsistency_class) { Gitlab::Schema::Validation::Inconsistency }

    let(:inconsistencies) do
      [
        instance_double(inconsistency_class, inspect: 'index_statement_1', type: 'wrong_indexes'),
        instance_double(inconsistency_class, inspect: 'index_statement_2', type: 'missing_indexes'),
        instance_double(inconsistency_class, inspect: 'table_statement_1', type: 'extra_tables',
          table_name: 'test_replication'),
        instance_double(inconsistency_class, inspect: 'trigger_statement', type: 'missing_triggers',
          object_name: 'gitlab_schema_write_trigger_for_users')
      ]
    end

    before do
      allow(Gitlab::Schema::Validation::Runner).to receive(:new).and_return(runner)
    end

    it 'prints the inconsistency message along with the log info' do
      expected_messages = [
        'index_statement_1',
        'index_statement_2',
        'This task is a diagnostic tool to be used under the guidance of GitLab Support. You should not use the task for routine checks as database inconsistencies might be expected.'
      ]

      expect { run_rake_task('gitlab:db:schema_checker:run') }
        .to output { |output|
          expected_messages.each do |message|
            expect(output).to include(message)
          end
        }.to_stdout
    end
  end

  describe 'dictionary generate' do
    let(:db_config) { instance_double(ActiveRecord::DatabaseConfigurations::HashConfig, name: 'fake_db') }

    let(:model) { ActiveRecord::Base }
    let(:connection) { model.connection }

    let(:base_models) { { 'fake_db' => model }.with_indifferent_access }

    let(:tables) { %w[table1 _test_dictionary_table_name] }
    let(:views) { %w[view1] }

    let(:table_file_path) { 'db/docs/table1.yml' }
    let(:view_file_path) { 'db/docs/views/view1.yml' }
    let(:test_table_path) { 'db/docs/_test_dictionary_table_name.yml' }

    before do
      allow(Gitlab::Database).to receive(:db_config_for_connection).and_return(db_config)
      allow(Gitlab::Database).to receive(:database_base_models).and_return(base_models)

      allow(connection).to receive(:tables).and_return(tables)
      allow(connection).to receive(:views).and_return(views)
    end

    after do
      File.delete(table_file_path)
      File.delete(view_file_path)
    end

    context 'when the dictionary files do not exist' do
      it 'generate the dictionary files' do
        run_rake_task('gitlab:db:dictionary:generate')

        expect(File).to exist(File.join(table_file_path))
        expect(File).to exist(File.join(view_file_path))
      end

      it 'do not generate the dictionary files for test tables' do
        run_rake_task('gitlab:db:dictionary:generate')

        expect(File).not_to exist(File.join(test_table_path))
      end
    end

    context 'when a new model class is added to the codebase' do
      let(:table_class) do
        Class.new(ApplicationRecord) do
          self.table_name = 'table1'
        end
      end

      let(:migration_table_class) do
        Class.new(Gitlab::Database::Migration[1.0]::MigrationRecord) do
          self.table_name = 'table1'
        end
      end

      let(:view_class) do
        Class.new(ApplicationRecord) do
          self.table_name = 'view1'
        end
      end

      let(:table_without_model) do
        Class.new(Gitlab::Database::Partitioning::TableWithoutModel) do
          self.table_name = 'table1'
        end
      end

      table_metadata = {
        'table_name' => 'table1',
        'classes' => ['TableClass'],
        'feature_categories' => [],
        'description' => nil,
        'introduced_by_url' => nil,
        'milestone' => 14.3
      }
      view_metadata = {
        'view_name' => 'view1',
        'classes' => ['ViewClass'],
        'feature_categories' => [],
        'description' => nil,
        'introduced_by_url' => nil,
        'milestone' => 14.3
      }

      before do
        stub_const('TableClass1', table_class)
        stub_const('MIgrationTableClass1', migration_table_class)
        stub_const('ViewClass1', view_class)

        File.write(table_file_path, table_metadata.to_yaml)
        File.write(view_file_path, view_metadata.to_yaml)

        allow(model).to receive(:descendants).and_return([table_class, migration_table_class, view_class, table_without_model])
      end

      it 'appends new classes to the dictionary' do
        run_rake_task('gitlab:db:dictionary:generate')

        table_metadata = YAML.safe_load(File.read(table_file_path))
        expect(table_metadata['classes']).to match_array(%w[TableClass TableClass1])

        view_metadata = YAML.safe_load(File.read(view_file_path))
        expect(view_metadata['classes']).to match_array(%w[ViewClass ViewClass1])
      end
    end

    context 'when a model class is removed from the codebase' do
      table_metadata = {
        'table_name' => 'table1',
        'classes' => ['TableClass'],
        'feature_categories' => [],
        'description' => nil,
        'introduced_by_url' => nil,
        'milestone' => 14.3
      }
      view_metadata = {
        'view_name' => 'view1',
        'classes' => ['ViewClass'],
        'feature_categories' => [],
        'description' => nil,
        'introduced_by_url' => nil,
        'milestone' => 14.3
      }

      before do
        File.write(table_file_path, table_metadata.to_yaml)
        File.write(view_file_path, view_metadata.to_yaml)

        allow(model).to receive(:descendants).and_return([])
      end

      it 'keeps the dictionary classes' do
        run_rake_task('gitlab:db:dictionary:generate')

        table_metadata = YAML.safe_load(File.read(table_file_path))
        expect(table_metadata['classes']).to match_array(%w[TableClass])

        view_metadata = YAML.safe_load(File.read(view_file_path))
        expect(view_metadata['classes']).to match_array(%w[ViewClass])
      end
    end
  end

  describe 'unattended' do
    using RSpec::Parameterized::TableSyntax

    where(:schema_migration_table_exists, :needs_migrations, :rake_output) do
      false | false | "unattended_migrations_completed"
      false | true | "unattended_migrations_completed"
      true | false | "unattended_migrations_static"
      true | true | "unattended_migrations_completed"
    end

    before do
      allow(Rake::Task['gitlab:db:configure']).to receive(:invoke).and_return(true)
    end

    with_them do
      it 'outputs changed message for automation after operations happen' do
        allow(ActiveRecord::Base.connection).to receive_message_chain(:schema_migration, :table_exists?).and_return(schema_migration_table_exists)
        allow_any_instance_of(ActiveRecord::MigrationContext).to receive(:needs_migration?).and_return(needs_migrations)
        expect { run_rake_task('gitlab:db:unattended') }.to output(/^#{rake_output}$/).to_stdout
      end
    end
  end

  describe 'clean_structure_sql' do
    let(:clean_rake_task) { 'gitlab:db:clean_structure_sql' }
    let(:test_task_name) { 'gitlab:db:_test_multiple_structure_cleans' }
    let(:input) { 'this is structure data' }

    let(:output) { StringIO.new }

    before do
      structure_files = %w[structure.sql ci_structure.sql sec_structure.sql]

      allow(File).to receive(:open).and_call_original

      structure_files.each do |structure_file_name|
        structure_file = File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, structure_file_name)
        stub_file_read(structure_file, content: input)
        allow(File).to receive(:open).with(structure_file.to_s, any_args).and_yield(output)
      end

      if Gitlab.ee?
        allow(File).to receive(:open).with(Rails.root.join('ee/db/geo/structure.sql').to_s, any_args).and_yield(output)
        allow(File).to receive(:open).with(Rails.root.join('ee/db/embedding/structure.sql').to_s, any_args).and_yield(output)
      end

      if Gitlab.jh?
        allow(File).to receive(:open).with(Rails.root.join('jh/db/structure.sql').to_s, any_args).and_yield(output)
      end
    end

    after do
      Rake::Task[test_task_name].clear if Rake::Task.task_defined?(test_task_name)
    end

    it 'can be executed multiple times within another rake task' do
      expect_multiple_executions_of_task(test_task_name, clean_rake_task, count: 2) do
        database_count = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).size

        expect_next_instances_of(Gitlab::Database::SchemaCleaner, database_count) do |cleaner|
          expect(cleaner).to receive(:clean).with(output)
        end
      end
    end
  end

  describe 'drop_tables' do
    let(:tables) { %w[one two schema_migrations] }
    let(:views) { %w[three four pg_stat_statements] }
    let(:schemas) { Gitlab::Database::EXTRA_SCHEMAS }
    let(:ignored_views) { double(ActiveRecord::Relation, pluck: ['pg_stat_statements']) }

    before do
      allow(Gitlab::Database::PgDepend).to receive(:using_connection).and_yield
      allow(Gitlab::Database::PgDepend).to receive(:from_pg_extension).with('VIEW').and_return(ignored_views)
    end

    context 'with a single database' do
      let(:connection) { ActiveRecord::Base.connection }

      before do
        skip_if_multiple_databases_are_setup

        allow(connection).to receive(:execute).and_return(nil)

        allow(connection).to receive(:tables).and_return(tables)
        allow(connection).to receive(:views).and_return(views)
      end

      it 'drops all objects for the database', :aggregate_failures do
        expect_objects_to_be_dropped(connection)

        run_rake_task('gitlab:db:drop_tables')
      end
    end

    context 'with multiple databases', :aggregate_failures do
      let(:main_model) { double(:model, connection: double(:connection, tables: tables, views: views)) }
      let(:ci_model) { double(:model, connection: double(:connection, tables: tables, views: views)) }
      let(:base_models) { { 'main' => main_model, 'ci' => ci_model } }

      before do
        skip_if_shared_database(:ci)

        allow(Gitlab::Database).to receive(:database_base_models_with_gitlab_shared).and_return(base_models)

        allow(main_model.connection).to receive(:table_exists?).with('schema_migrations').and_return(true)
        allow(ci_model.connection).to receive(:table_exists?).with('schema_migrations').and_return(true)

        (tables + views + schemas).each do |name|
          allow(main_model.connection).to receive(:quote_table_name).with(name).and_return("\"#{name}\"")
          allow(ci_model.connection).to receive(:quote_table_name).with(name).and_return("\"#{name}\"")
        end
      end

      it 'drops all objects for all databases', :aggregate_failures do
        expect_objects_to_be_dropped(main_model.connection)
        expect_objects_to_be_dropped(ci_model.connection)

        run_rake_task('gitlab:db:drop_tables')
      end

      context 'when the single database task is used' do
        it 'drops all objects for the given database', :aggregate_failures do
          expect_objects_to_be_dropped(main_model.connection)

          expect(ci_model.connection).not_to receive(:execute)

          run_rake_task('gitlab:db:drop_tables:main')
        end
      end

      context 'with geo configured' do
        before do
          skip_unless_geo_configured
        end

        it 'does not create a task for the geo database' do
          expect { run_rake_task('gitlab:db:drop_tables:geo') }
            .to raise_error(/Don't know how to build task 'gitlab:db:drop_tables:geo'/)
        end
      end
    end

    def expect_objects_to_be_dropped(connection)
      expect(connection).to receive(:execute).with('DROP TABLE IF EXISTS "one" CASCADE')
      expect(connection).to receive(:execute).with('DROP TABLE IF EXISTS "two" CASCADE')

      expect(connection).to receive(:execute).with('DROP VIEW IF EXISTS "three" CASCADE')
      expect(connection).to receive(:execute).with('DROP VIEW IF EXISTS "four" CASCADE')
      expect(Gitlab::Database::PgDepend).to receive(:from_pg_extension).with('VIEW')
      expect(connection).not_to receive(:execute).with('DROP VIEW IF EXISTS "pg_stat_statements" CASCADE')

      expect(connection).to receive(:execute).with('TRUNCATE schema_migrations')

      Gitlab::Database::EXTRA_SCHEMAS.each do |schema|
        expect(connection).to receive(:execute).with("DROP SCHEMA IF EXISTS \"#{schema}\" CASCADE")
      end
    end
  end

  describe 'create_dynamic_partitions' do
    context 'with a single database' do
      before do
        skip_if_multiple_databases_are_setup
      end

      it 'delegates syncing of partitions without limiting databases' do
        expect(Gitlab::Database::Partitioning).to receive(:sync_partitions)

        run_rake_task('gitlab:db:create_dynamic_partitions')
      end
    end

    context 'with multiple databases' do
      before do
        skip_if_shared_database(:ci)
      end

      context 'when running the multi-database variant' do
        it 'delegates syncing of partitions without limiting databases' do
          expect(Gitlab::Database::Partitioning).to receive(:sync_partitions)

          run_rake_task('gitlab:db:create_dynamic_partitions')
        end
      end

      context 'when running a single-database variant' do
        it 'delegates syncing of partitions for the chosen database' do
          expect(Gitlab::Database::Partitioning).to receive(:sync_partitions).with(only_on: 'main')

          run_rake_task('gitlab:db:create_dynamic_partitions:main')
        end
      end
    end

    context 'with geo configured' do
      before do
        skip_unless_geo_configured
      end

      it 'does not create a task for the geo database' do
        expect { run_rake_task('gitlab:db:create_dynamic_partitions:geo') }
          .to raise_error(/Don't know how to build task 'gitlab:db:create_dynamic_partitions:geo'/)
      end
    end

    context 'with jh configured' do
      before do
        skip 'Skipping because the jh database is not configured' unless
          !!ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'jh')
      end

      it 'does not create a task for the jh database' do
        expect { run_rake_task('gitlab:db:create_dynamic_partitions:jh') }
          .to raise_error(/Don't know how to build task 'gitlab:db:create_dynamic_partitions:jh'/)
      end
    end
  end

  describe 'reindex' do
    context 'with a single database' do
      before do
        skip_if_shared_database(:ci)
      end

      it 'delegates to Gitlab::Database::Reindexing' do
        expect(Gitlab::Database::Reindexing).to receive(:invoke).with(no_args)

        run_rake_task('gitlab:db:reindex')
      end

      context 'when reindexing is not enabled' do
        it 'is a no-op' do
          expect(Gitlab::Database::Reindexing).to receive(:enabled?).and_return(false)
          expect(Gitlab::Database::Reindexing).not_to receive(:invoke)

          expect { run_rake_task('gitlab:db:reindex') }.to raise_error(SystemExit)
        end
      end
    end

    context 'with multiple databases' do
      let(:base_models) { { 'main' => double(:model), 'ci' => double(:model) } }

      before do
        skip_if_multiple_databases_not_setup(:ci)

        allow(Gitlab::Database).to receive(:database_base_models_with_gitlab_shared).and_return(base_models)
      end

      it 'delegates to Gitlab::Database::Reindexing without a specific database' do
        expect(Gitlab::Database::Reindexing).to receive(:invoke).with(no_args)

        run_rake_task('gitlab:db:reindex')
      end

      context 'when the single database task is used' do
        before do
          skip_if_shared_database(:ci)
        end

        it 'delegates to Gitlab::Database::Reindexing with a specific database' do
          expect(Gitlab::Database::Reindexing).to receive(:invoke).with('ci')

          run_rake_task('gitlab:db:reindex:ci')
        end

        context 'when reindexing is not enabled' do
          it 'is a no-op' do
            expect(Gitlab::Database::Reindexing).to receive(:enabled?).and_return(false)
            expect(Gitlab::Database::Reindexing).not_to receive(:invoke)

            expect { run_rake_task('gitlab:db:reindex:ci') }.to raise_error(SystemExit)
          end
        end
      end

      context 'with geo configured' do
        before do
          skip_unless_geo_configured
        end

        it 'does not create a task for the geo database' do
          expect { run_rake_task('gitlab:db:reindex:geo') }
            .to raise_error(/Don't know how to build task 'gitlab:db:reindex:geo'/)
        end
      end
    end
  end

  describe 'enqueue_reindexing_action' do
    let(:index_name) { 'public.users_pkey' }

    it 'creates an entry in the queue' do
      expect do
        run_rake_task('gitlab:db:enqueue_reindexing_action', "[#{index_name}, main]")
      end.to change { Gitlab::Database::PostgresIndex.find(index_name).queued_reindexing_actions.size }.from(0).to(1)
    end

    it 'defaults to main database' do
      expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(ActiveRecord::Base.connection).and_call_original

      expect do
        run_rake_task('gitlab:db:enqueue_reindexing_action', "[#{index_name}]")
      end.to change { Gitlab::Database::PostgresIndex.find(index_name).queued_reindexing_actions.size }.from(0).to(1)
    end
  end

  describe 'execute_async_index_operations' do
    before do
      skip_if_shared_database(:ci)
    end

    it 'delegates ci task to Gitlab::Database::AsyncIndexes' do
      expect(Gitlab::Database::AsyncIndexes).to receive(:execute_pending_actions!).with(how_many: 2)

      run_rake_task('gitlab:db:execute_async_index_operations:ci')
    end

    it 'delegates ci task to Gitlab::Database::AsyncIndexes with specified argument' do
      expect(Gitlab::Database::AsyncIndexes).to receive(:execute_pending_actions!).with(how_many: 5)

      run_rake_task('gitlab:db:execute_async_index_operations:ci', '[5]')
    end

    it 'delegates main task to Gitlab::Database::AsyncIndexes' do
      expect(Gitlab::Database::AsyncIndexes).to receive(:execute_pending_actions!).with(how_many: 2)

      run_rake_task('gitlab:db:execute_async_index_operations:main')
    end

    it 'delegates main task to Gitlab::Database::AsyncIndexes with specified argument' do
      expect(Gitlab::Database::AsyncIndexes).to receive(:execute_pending_actions!).with(how_many: 7)

      run_rake_task('gitlab:db:execute_async_index_operations:main', '[7]')
    end

    it 'delegates all task to every database with higher default for dev' do
      expect(Rake::Task['gitlab:db:execute_async_index_operations:ci']).to receive(:invoke).with(1000)
      expect(Rake::Task['gitlab:db:execute_async_index_operations:main']).to receive(:invoke).with(1000)

      run_rake_task('gitlab:db:execute_async_index_operations:all')
    end

    it 'delegates all task to every database with lower default for prod' do
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)

      expect(Rake::Task['gitlab:db:execute_async_index_operations:ci']).to receive(:invoke).with(2)
      expect(Rake::Task['gitlab:db:execute_async_index_operations:main']).to receive(:invoke).with(2)

      run_rake_task('gitlab:db:execute_async_index_operations:all')
    end

    it 'delegates all task to every database with specified argument' do
      expect(Rake::Task['gitlab:db:execute_async_index_operations:ci']).to receive(:invoke).with('50')
      expect(Rake::Task['gitlab:db:execute_async_index_operations:main']).to receive(:invoke).with('50')

      run_rake_task('gitlab:db:execute_async_index_operations:all', '[50]')
    end

    context 'when feature is not enabled' do
      it 'is a no-op' do
        stub_feature_flags(database_async_index_operations: false)

        expect(Gitlab::Database::AsyncIndexes).not_to receive(:execute_pending_actions!)

        expect { run_rake_task('gitlab:db:execute_async_index_operations:main') }.to raise_error(SystemExit)
      end
    end

    context 'when database ddl feature flag is enabled' do
      it 'is a no-op' do
        stub_feature_flags(disallow_database_ddl_feature_flags: true)

        expect(Gitlab::Database::AsyncIndexes).not_to receive(:execute_pending_actions!)

        expect { run_rake_task('gitlab:db:execute_async_index_operations:main') }.to raise_error(SystemExit)
      end
    end

    context 'with geo configured' do
      before do
        skip_unless_geo_configured
      end

      it 'does not create a task for the geo database' do
        expect { run_rake_task('gitlab:db:execute_async_index_operations:geo') }
          .to raise_error(/Don't know how to build task 'gitlab:db:execute_async_index_operations:geo'/)
      end
    end
  end

  describe 'validate_async_constraints' do
    before do
      skip_if_shared_database(:ci)
    end

    it 'delegates ci task to Gitlab::Database::AsyncConstraints' do
      expect(Gitlab::Database::AsyncConstraints).to receive(:validate_pending_entries!).with(how_many: 2)

      run_rake_task('gitlab:db:validate_async_constraints:ci')
    end

    it 'delegates ci task to Gitlab::Database::AsyncConstraints with specified argument' do
      expect(Gitlab::Database::AsyncConstraints).to receive(:validate_pending_entries!).with(how_many: 5)

      run_rake_task('gitlab:db:validate_async_constraints:ci', '[5]')
    end

    it 'delegates main task to Gitlab::Database::AsyncConstraints' do
      expect(Gitlab::Database::AsyncConstraints).to receive(:validate_pending_entries!).with(how_many: 2)

      run_rake_task('gitlab:db:validate_async_constraints:main')
    end

    it 'delegates main task to Gitlab::Database::AsyncConstraints with specified argument' do
      expect(Gitlab::Database::AsyncConstraints).to receive(:validate_pending_entries!).with(how_many: 7)

      run_rake_task('gitlab:db:validate_async_constraints:main', '[7]')
    end

    it 'delegates all task to every database with higher default for dev' do
      expect(Rake::Task['gitlab:db:validate_async_constraints:ci']).to receive(:invoke).with(1000)
      expect(Rake::Task['gitlab:db:validate_async_constraints:main']).to receive(:invoke).with(1000)

      run_rake_task('gitlab:db:validate_async_constraints:all')
    end

    it 'delegates all task to every database with lower default for prod' do
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)

      expect(Rake::Task['gitlab:db:validate_async_constraints:ci']).to receive(:invoke).with(2)
      expect(Rake::Task['gitlab:db:validate_async_constraints:main']).to receive(:invoke).with(2)

      run_rake_task('gitlab:db:validate_async_constraints:all')
    end

    it 'delegates all task to every database with specified argument' do
      expect(Rake::Task['gitlab:db:validate_async_constraints:ci']).to receive(:invoke).with('50')
      expect(Rake::Task['gitlab:db:validate_async_constraints:main']).to receive(:invoke).with('50')

      run_rake_task('gitlab:db:validate_async_constraints:all', '[50]')
    end

    context 'when feature is not enabled' do
      it 'is a no-op' do
        stub_feature_flags(database_async_foreign_key_validation: false)

        expect(Gitlab::Database::AsyncConstraints).not_to receive(:validate_pending_entries!)

        expect { run_rake_task('gitlab:db:validate_async_constraints:main') }.to raise_error(SystemExit)
      end
    end

    context 'when database ddl feature flag is enabled' do
      it 'is a no-op' do
        stub_feature_flags(disallow_database_ddl_feature_flags: true)

        expect(Gitlab::Database::AsyncConstraints).not_to receive(:validate_pending_entries!)

        expect { run_rake_task('gitlab:db:validate_async_constraints:main') }.to raise_error(SystemExit)
      end
    end

    context 'with geo configured' do
      before do
        skip_unless_geo_configured
      end

      it 'does not create a task for the geo database' do
        expect { run_rake_task('gitlab:db:validate_async_constraints:geo') }
          .to raise_error(/Don't know how to build task 'gitlab:db:validate_async_constraints:geo'/)
      end
    end
  end

  describe 'active' do
    using RSpec::Parameterized::TableSyntax

    let(:task) { 'gitlab:db:active' }

    where(:needs_migration, :project_count, :exit_status, :exit_code) do
      true  | nil | 1 | false
      false | 1 | 0 | true
      false | 0 | 1 | false
      false | 2 | 0 | true
    end

    with_them do
      it 'exits 0 or 1 depending on user modifications to the database' do
        allow_any_instance_of(ActiveRecord::MigrationContext).to receive(:needs_migration?).and_return(needs_migration)
        allow(Project).to receive(:count).and_return(project_count)

        expect { run_rake_task(task) }.to raise_error do |error|
          expect(error).to be_a(SystemExit)
          expect(error.status).to eq(exit_status)
          expect(error.success?).to be(exit_code)
        end
      end
    end
  end

  describe '#migrate_with_instrumentation' do
    let(:runner) { instance_double(::Gitlab::Database::Migrations::Runner) }

    describe '#up (legacy mode)' do
      subject { run_rake_task('gitlab:db:migration_testing:up') }

      it 'delegates to the migration runner in legacy mode' do
        expect(::Gitlab::Database::Migrations::Runner).to receive(:up).with(database: 'main', legacy_mode: true)
                                                                      .and_return(runner)
        expect(runner).to receive(:run)

        subject
      end
    end

    describe '#sample_background_migrations' do
      it 'delegates to the migration runner with a default sample duration' do
        expect(::Gitlab::Database::Migrations::Runner).to receive_message_chain(:background_migrations, :run_jobs).with(for_duration: 30.minutes)

        run_rake_task('gitlab:db:migration_testing:sample_background_migrations')
      end

      it 'delegates to the migration runner with a configured sample duration' do
        expect(::Gitlab::Database::Migrations::Runner).to receive_message_chain(:background_migrations, :run_jobs).with(for_duration: 100.seconds)

        run_rake_task('gitlab:db:migration_testing:sample_background_migrations', '[100]')
      end
    end

    where(:db) do
      ::Gitlab::Database.db_config_names(with_schema: :gitlab_shared).map(&:to_sym)
    end

    with_them do
      describe '#up' do
        subject { run_rake_task("gitlab:db:migration_testing:up:#{db}") }

        let(:migrations_id_runner) do
          instance_double('Gitlab::Database::Migrations::BatchedMigrationLastId', store: true)
        end

        before do
          allow(::Gitlab::Database::Migrations::Runner).to(
            receive(:batched_migrations_last_id).and_return(migrations_id_runner)
          )
        end

        it 'delegates to the migration runner' do
          expect(::Gitlab::Database::Migrations::Runner).to receive(:up).with(database: db).and_return(runner)
          expect(runner).to receive(:run)

          subject
        end
      end

      describe '#down' do
        subject { run_rake_task("gitlab:db:migration_testing:down:#{db}") }

        it 'delegates to the migration runner' do
          expect(::Gitlab::Database::Migrations::Runner).to receive(:down).with(database: db).and_return(runner)
          expect(runner).to receive(:run)

          subject
        end
      end

      describe '#sample_batched_background_migrations' do
        let(:batched_runner) { instance_double(::Gitlab::Database::Migrations::TestBatchedBackgroundRunner) }

        it 'delegates to the migration runner for a specified database with a default sample duration' do
          expect(::Gitlab::Database::Migrations::Runner).to receive(:batched_background_migrations)
                                                               .with(for_database: db).and_return(batched_runner)
          expect(batched_runner).to receive(:run_jobs).with(for_duration: 30.minutes)

          run_rake_task("gitlab:db:migration_testing:sample_batched_background_migrations:#{db}")
        end

        it 'delegates to the migration runner for a specified database and sample duration' do
          expect(::Gitlab::Database::Migrations::Runner).to receive(:batched_background_migrations)
                                                              .with(for_database: db).and_return(batched_runner)
          expect(batched_runner).to receive(:run_jobs).with(for_duration: 100.seconds)

          run_rake_task("gitlab:db:migration_testing:sample_batched_background_migrations:#{db}", '[100]')
        end
      end
    end
  end

  describe '#execute_batched_migrations' do
    subject(:execute_batched_migrations) { run_rake_task('gitlab:db:execute_batched_migrations') }

    let(:connections) do
      {
        main: instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter),
        ci: instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      }
    end

    let(:runners) do
      {
        main: instance_double('Gitlab::Database::BackgroundMigration::BatchedMigrationRunner'),
        ci: instance_double('Gitlab::Database::BackgroundMigration::BatchedMigrationRunner')
      }
    end

    let(:migrations) do
      {
        main: build_list(:batched_background_migration, 1),
        ci: build_list(:batched_background_migration, 1)
      }
    end

    before do
      each_database = class_double('Gitlab::Database::EachDatabase').as_stubbed_const

      allow(each_database).to receive(:each_connection)
        .and_yield(connections[:main], 'main')
        .and_yield(connections[:ci], 'ci')

      keys = migrations.keys
      allow(Gitlab::Database::BackgroundMigration::BatchedMigration)
        .to receive_message_chain(:with_status, :queue_order) { migrations[keys.shift] }
    end

    it 'executes all migrations' do
      [:main, :ci].each do |name|
        expect(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner).to receive(:new)
          .with(connection: connections[name])
          .and_return(runners[name])

        expect(runners[name]).to receive(:run_entire_migration).with(migrations[name].first)
      end

      execute_batched_migrations
    end
  end

  context 'with multiple databases', :reestablished_active_record_base do
    before do
      skip_if_shared_database(:ci)
    end

    describe 'db:schema:dump against a single database' do
      it 'invokes gitlab:db:clean_structure_sql' do
        expect(Rake::Task['gitlab:db:clean_structure_sql']).to receive(:invoke).once.and_return(true)

        expect { run_rake_task('db:schema:dump:main') }.not_to raise_error
      end
    end

    describe 'db:migrate against a single database' do
      it 'invokes gitlab:db:create_dynamic_partitions for the same database' do
        expect(Rake::Task['gitlab:db:create_dynamic_partitions:main']).to receive(:invoke).once.and_return(true)

        expect { run_rake_task('db:migrate:main') }.not_to raise_error
      end
    end

    describe 'db:migrate:geo' do
      before do
        skip_unless_geo_configured
      end

      it 'does not invoke gitlab:db:create_dynamic_partitions' do
        expect(Rake::Task['gitlab:db:create_dynamic_partitions']).not_to receive(:invoke)

        expect { run_rake_task('db:migrate:geo') }.not_to raise_error
      end
    end
  end

  describe 'gitlab:db:reset_as_non_superuser' do
    let(:connection_pool) { instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool) }
    let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
    let(:configurations) { double(ActiveRecord::DatabaseConfigurations) }
    let(:configuration) { instance_double(ActiveRecord::DatabaseConfigurations::HashConfig, env_name: 'test', name: 'main') }
    let(:config_hash) { { username: 'foo' } }

    before do
      skip_if_shared_database(:ci)

      allow(Rake::Task['db:drop']).to receive(:invoke)
      allow(Rake::Task['db:create']).to receive(:invoke)
      allow(ActiveRecord::Base).to receive(:configurations).and_return(configurations)
      allow(configurations).to receive(:configs_for).and_return([configuration])
      allow(configuration).to receive(:configuration_hash).and_return(config_hash)
      allow(ActiveRecord::Base).to receive(:establish_connection).and_return(connection_pool)
    end

    it 'migrate as nonsuperuser check with default username' do
      expect(config_hash).to receive(:merge).with({ username: 'gitlab' }).and_call_original
      expect(Gitlab::Database).to receive(:check_for_non_superuser)
      expect(Rake::Task['db:migrate:main']).to receive(:invoke)

      run_rake_task('gitlab:db:reset_as_non_superuser')
    end

    it 'migrate as nonsuperuser check with specified username' do
      expect(config_hash).to receive(:merge).with({ username: 'foo' }).and_call_original
      expect(Gitlab::Database).to receive(:check_for_non_superuser)
      expect(Rake::Task['db:migrate:main']).to receive(:invoke)

      run_rake_task('gitlab:db:reset_as_non_superuser', '[foo]')
    end
  end

  def run_rake_task(task_name, arguments = '')
    Rake::Task[task_name].reenable
    Rake.application.invoke_task("#{task_name}#{arguments}")
  end

  def expect_multiple_executions_of_task(test_task_name, task_to_invoke, count: 2)
    Rake::Task.define_task(test_task_name => :environment) do
      count.times do
        yield

        Rake::Task[task_to_invoke].invoke
      end
    end

    run_rake_task(test_task_name)
  end

  def skip_unless_geo_configured
    skip 'Skipping because the geo database is not configured' unless geo_configured?
  end

  def geo_configured?
    !!ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'geo')
  end
end
