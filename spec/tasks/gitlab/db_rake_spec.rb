# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.describe 'gitlab:db namespace rake task', :silence_stdout do
  before :all do
    Rake.application.rake_require 'active_record/railties/databases'
    Rake.application.rake_require 'tasks/seed_fu'
    Rake.application.rake_require 'tasks/gitlab/db'

    # empty task as env is already loaded
    Rake::Task.define_task :environment
  end

  before do
    # Stub out db tasks
    allow(Rake::Task['db:migrate']).to receive(:invoke).and_return(true)
    allow(Rake::Task['db:structure:load']).to receive(:invoke).and_return(true)
    allow(Rake::Task['db:seed_fu']).to receive(:invoke).and_return(true)
  end

  describe 'mark_migration_complete' do
    context 'with a single database' do
      let(:main_model) { ActiveRecord::Base }

      before do
        skip_if_multiple_databases_are_setup
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
      let(:base_models) { { 'main' => main_model, 'ci' => ci_model } }

      before do
        skip_if_multiple_databases_not_setup

        allow(Gitlab::Database).to receive(:database_base_models).and_return(base_models)
      end

      it 'marks the migration complete on each database' do
        expect(main_model.connection).to receive(:quote).with('123').and_return("'123'")
        expect(main_model.connection).to receive(:execute)
          .with("INSERT INTO schema_migrations (version) VALUES ('123')")

        expect(ci_model.connection).to receive(:quote).with('123').and_return("'123'")
        expect(ci_model.connection).to receive(:execute)
          .with("INSERT INTO schema_migrations (version) VALUES ('123')")

        run_rake_task('gitlab:db:mark_migration_complete', '[123]')
      end

      context 'when the single database task is used' do
        it 'marks the migration complete for the given database' do
          expect(main_model.connection).to receive(:quote).with('123').and_return("'123'")
          expect(main_model.connection).to receive(:execute)
            .with("INSERT INTO schema_migrations (version) VALUES ('123')")

          expect(ci_model.connection).not_to receive(:quote)
          expect(ci_model.connection).not_to receive(:execute)

          run_rake_task('gitlab:db:mark_migration_complete:main', '[123]')
        end
      end
    end

    context 'when the migration is already marked complete' do
      let(:main_model) { double(:model, connection: double(:connection)) }
      let(:base_models) { { 'main' => main_model } }

      before do
        allow(Gitlab::Database).to receive(:database_base_models).and_return(base_models)
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
        allow(Gitlab::Database).to receive(:database_base_models).and_return(base_models)
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
    it 'invokes db:migrate when schema has already been loaded' do
      allow(ActiveRecord::Base.connection).to receive(:tables).and_return(%w[table1 table2])
      expect(Rake::Task['db:migrate']).to receive(:invoke)
      expect(Rake::Task['db:structure:load']).not_to receive(:invoke)
      expect(Rake::Task['db:seed_fu']).not_to receive(:invoke)
      expect { run_rake_task('gitlab:db:configure') }.not_to raise_error
    end

    it 'invokes db:shema:load and db:seed_fu when schema is not loaded' do
      allow(ActiveRecord::Base.connection).to receive(:tables).and_return([])
      expect(Rake::Task['db:structure:load']).to receive(:invoke)
      expect(Rake::Task['db:seed_fu']).to receive(:invoke)
      expect(Rake::Task['db:migrate']).not_to receive(:invoke)
      expect { run_rake_task('gitlab:db:configure') }.not_to raise_error
    end

    it 'invokes db:shema:load and db:seed_fu when there is only a single table present' do
      allow(ActiveRecord::Base.connection).to receive(:tables).and_return(['default'])
      expect(Rake::Task['db:structure:load']).to receive(:invoke)
      expect(Rake::Task['db:seed_fu']).to receive(:invoke)
      expect(Rake::Task['db:migrate']).not_to receive(:invoke)
      expect { run_rake_task('gitlab:db:configure') }.not_to raise_error
    end

    it 'does not invoke any other rake tasks during an error' do
      allow(ActiveRecord::Base).to receive(:connection).and_raise(RuntimeError, 'error')
      expect(Rake::Task['db:migrate']).not_to receive(:invoke)
      expect(Rake::Task['db:structure:load']).not_to receive(:invoke)
      expect(Rake::Task['db:seed_fu']).not_to receive(:invoke)
      expect { run_rake_task('gitlab:db:configure') }.to raise_error(RuntimeError, 'error')
      # unstub connection so that the database cleaner still works
      allow(ActiveRecord::Base).to receive(:connection).and_call_original
    end

    it 'does not invoke seed after a failed schema_load' do
      allow(ActiveRecord::Base.connection).to receive(:tables).and_return([])
      allow(Rake::Task['db:structure:load']).to receive(:invoke).and_raise(RuntimeError, 'error')
      expect(Rake::Task['db:structure:load']).to receive(:invoke)
      expect(Rake::Task['db:seed_fu']).not_to receive(:invoke)
      expect(Rake::Task['db:migrate']).not_to receive(:invoke)
      expect { run_rake_task('gitlab:db:configure') }.to raise_error(RuntimeError, 'error')
    end

    context 'SKIP_POST_DEPLOYMENT_MIGRATIONS environment variable set' do
      let(:rails_paths) { { 'db' => ['db'], 'db/migrate' => ['db/migrate'] } }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('SKIP_POST_DEPLOYMENT_MIGRATIONS').and_return true

        # Our environment has already been loaded, so we need to pretend like post_migrations were not
        allow(Rails.application.config).to receive(:paths).and_return(rails_paths)
        allow(ActiveRecord::Migrator).to receive(:migrations_paths).and_return(rails_paths['db/migrate'].dup)
      end

      it 'adds post deployment migrations before schema load if the schema is not already loaded' do
        allow(ActiveRecord::Base.connection).to receive(:tables).and_return([])
        expect(Gitlab::Database).to receive(:add_post_migrate_path_to_rails).and_call_original
        expect(Rake::Task['db:structure:load']).to receive(:invoke)
        expect(Rake::Task['db:seed_fu']).to receive(:invoke)
        expect(Rake::Task['db:migrate']).not_to receive(:invoke)
        expect { run_rake_task('gitlab:db:configure') }.not_to raise_error
        expect(rails_paths['db/migrate'].include?(File.join(Rails.root, 'db', 'post_migrate'))).to be(true)
      end

      it 'ignores post deployment migrations  when schema has already been loaded' do
        allow(ActiveRecord::Base.connection).to receive(:tables).and_return(%w[table1 table2])
        expect(Rake::Task['db:migrate']).to receive(:invoke)
        expect(Gitlab::Database).not_to receive(:add_post_migrate_path_to_rails)
        expect(Rake::Task['db:structure:load']).not_to receive(:invoke)
        expect(Rake::Task['db:seed_fu']).not_to receive(:invoke)
        expect { run_rake_task('gitlab:db:configure') }.not_to raise_error
        expect(rails_paths['db/migrate'].include?(File.join(Rails.root, 'db', 'post_migrate'))).to be(false)
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
        allow(ActiveRecord::Base.connection.schema_migration).to receive(:table_exists?).and_return(schema_migration_table_exists)
        allow_any_instance_of(ActiveRecord::MigrationContext).to receive(:needs_migration?).and_return(needs_migrations)
        expect { run_rake_task('gitlab:db:unattended') }. to output(/^#{rake_output}$/).to_stdout
      end
    end
  end

  describe 'clean_structure_sql' do
    let_it_be(:clean_rake_task) { 'gitlab:db:clean_structure_sql' }
    let_it_be(:test_task_name) { 'gitlab:db:_test_multiple_structure_cleans' }
    let_it_be(:input) { 'this is structure data' }

    let(:output) { StringIO.new }

    before do
      structure_files = %w[structure.sql ci_structure.sql]

      allow(File).to receive(:open).and_call_original

      structure_files.each do |structure_file_name|
        structure_file = File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, structure_file_name)
        stub_file_read(structure_file, content: input)
        allow(File).to receive(:open).with(structure_file.to_s, any_args).and_yield(output)
      end

      if Gitlab.ee?
        allow(File).to receive(:open).with(Rails.root.join(Gitlab::Database::GEO_DATABASE_DIR, 'structure.sql').to_s, any_args).and_yield(output)
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
    subject { run_rake_task('gitlab:db:drop_tables') }

    let(:tables) { %w(one two) }
    let(:views) { %w(three four) }
    let(:connection) { ActiveRecord::Base.connection }

    before do
      allow(connection).to receive(:execute).and_return(nil)

      allow(connection).to receive(:tables).and_return(tables)
      allow(connection).to receive(:views).and_return(views)
    end

    it 'drops all tables, except schema_migrations' do
      expect(connection).to receive(:execute).with('DROP TABLE IF EXISTS "one" CASCADE')
      expect(connection).to receive(:execute).with('DROP TABLE IF EXISTS "two" CASCADE')

      subject
    end

    it 'drops all views' do
      expect(connection).to receive(:execute).with('DROP VIEW IF EXISTS "three" CASCADE')
      expect(connection).to receive(:execute).with('DROP VIEW IF EXISTS "four" CASCADE')

      subject
    end

    it 'truncates schema_migrations table' do
      expect(connection).to receive(:execute).with('TRUNCATE schema_migrations')

      subject
    end

    it 'drops extra schemas' do
      Gitlab::Database::EXTRA_SCHEMAS.each do |schema|
        expect(connection).to receive(:execute).with("DROP SCHEMA IF EXISTS \"#{schema}\" CASCADE")
      end

      subject
    end
  end

  describe 'reindex' do
    it 'delegates to Gitlab::Database::Reindexing' do
      expect(Gitlab::Database::Reindexing).to receive(:invoke)

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

  databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml
  ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |database_name|
    describe "reindex:#{database_name}" do
      it 'delegates to Gitlab::Database::Reindexing' do
        expect(Gitlab::Database::Reindexing).to receive(:invoke).with(database_name)

        run_rake_task("gitlab:db:reindex:#{database_name}")
      end

      context 'when reindexing is not enabled' do
        it 'is a no-op' do
          expect(Gitlab::Database::Reindexing).to receive(:enabled?).and_return(false)
          expect(Gitlab::Database::Reindexing).not_to receive(:invoke).with(database_name)

          expect { run_rake_task("gitlab:db:reindex:#{database_name}") }.to raise_error(SystemExit)
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

  describe 'active' do
    using RSpec::Parameterized::TableSyntax

    let(:task) { 'gitlab:db:active' }
    let(:self_monitoring) { double('self_monitoring') }

    where(:needs_migration, :self_monitoring_project, :project_count, :exit_status, :exit_code) do
      true | nil | nil | 1 | false
      false | :self_monitoring | 1 | 1 | false
      false | nil | 0 | 1 | false
      false | :self_monitoring | 2 | 0 | true
    end

    with_them do
      it 'exits 0 or 1 depending on user modifications to the database' do
        allow_any_instance_of(ActiveRecord::MigrationContext).to receive(:needs_migration?).and_return(needs_migration)
        allow_any_instance_of(ApplicationSetting).to receive(:self_monitoring_project).and_return(self_monitoring_project)
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
    describe '#up' do
      subject { run_rake_task('gitlab:db:migration_testing:up') }

      it 'delegates to the migration runner' do
        expect(::Gitlab::Database::Migrations::Runner).to receive_message_chain(:up, :run)

        subject
      end
    end

    describe '#down' do
      subject { run_rake_task('gitlab:db:migration_testing:down') }

      it 'delegates to the migration runner' do
        expect(::Gitlab::Database::Migrations::Runner).to receive_message_chain(:down, :run)

        subject
      end
    end
  end

  describe '#execute_batched_migrations' do
    subject { run_rake_task('gitlab:db:execute_batched_migrations') }

    let(:migrations) { create_list(:batched_background_migration, 2) }
    let(:runner) { instance_double('Gitlab::Database::BackgroundMigration::BatchedMigrationRunner') }

    before do
      allow(Gitlab::Database::BackgroundMigration::BatchedMigration).to receive_message_chain(:active, :queue_order).and_return(migrations)
      allow(Gitlab::Database::BackgroundMigration::BatchedMigrationRunner).to receive(:new).and_return(runner)
    end

    it 'executes all migrations' do
      migrations.each do |migration|
        expect(runner).to receive(:run_entire_migration).with(migration)
      end

      subject
    end
  end

  context 'with multiple databases', :reestablished_active_record_base do
    before do
      allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:setup_initial_database_yaml).and_return([:main, :geo])
    end

    describe 'db:structure:dump' do
      it 'invokes gitlab:db:clean_structure_sql' do
        skip unless Gitlab.ee?

        expect(Rake::Task['gitlab:db:clean_structure_sql']).to receive(:invoke).twice.and_return(true)

        expect { run_rake_task('db:structure:dump:main') }.not_to raise_error
      end
    end

    describe 'db:schema:dump' do
      it 'invokes gitlab:db:clean_structure_sql' do
        skip unless Gitlab.ee?

        expect(Rake::Task['gitlab:db:clean_structure_sql']).to receive(:invoke).once.and_return(true)

        expect { run_rake_task('db:schema:dump:main') }.not_to raise_error
      end
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
end
