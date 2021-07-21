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
      structure_files = %w[db/structure.sql db/ci_structure.sql]

      allow(File).to receive(:open).and_call_original

      structure_files.each do |structure_file|
        stub_file_read(structure_file, content: input)
        allow(File).to receive(:open).with(Rails.root.join(structure_file).to_s, any_args).and_yield(output)
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
        expect(connection).to receive(:execute).with("DROP SCHEMA IF EXISTS \"#{schema}\"")
      end

      subject
    end
  end

  describe 'reindex' do
    let(:reindex) { double('reindex') }
    let(:indexes) { double('indexes') }

    it 'cleans up any leftover indexes' do
      expect(Gitlab::Database::Reindexing).to receive(:cleanup_leftovers!)

      run_rake_task('gitlab:db:reindex')
    end

    context 'when no index_name is given' do
      it 'uses all candidate indexes' do
        expect(Gitlab::Database::PostgresIndex).to receive(:reindexing_support).and_return(indexes)
        expect(Gitlab::Database::Reindexing).to receive(:perform).with(indexes)

        run_rake_task('gitlab:db:reindex')
      end
    end

    context 'with index name given' do
      let(:index) { double('index') }

      before do
        allow(Gitlab::Database::PostgresIndex).to receive(:reindexing_support).and_return(indexes)
      end

      it 'calls the index rebuilder with the proper arguments' do
        allow(indexes).to receive(:where).with(identifier: 'public.foo_idx').and_return([index])
        expect(Gitlab::Database::Reindexing).to receive(:perform).with([index])

        run_rake_task('gitlab:db:reindex', '[public.foo_idx]')
      end

      it 'raises an error if the index does not exist' do
        allow(indexes).to receive(:where).with(identifier: 'public.absent_index').and_return([])

        expect { run_rake_task('gitlab:db:reindex', '[public.absent_index]') }.to raise_error(/Index not found/)
      end

      it 'raises an error if the index is not fully qualified with a schema' do
        expect { run_rake_task('gitlab:db:reindex', '[foo_idx]') }.to raise_error(/Index name is not fully qualified/)
      end
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
    subject { run_rake_task('gitlab:db:migration_testing') }

    let(:ctx) { double('ctx', migrations: all_migrations, schema_migration: double, get_all_versions: existing_versions) }
    let(:instrumentation) { instance_double(Gitlab::Database::Migrations::Instrumentation, observations: observations) }
    let(:existing_versions) { [1] }
    let(:all_migrations) { [double('migration1', version: 1), pending_migration] }
    let(:pending_migration) { double('migration2', version: 2) }
    let(:filename) { Gitlab::Database::Migrations::Instrumentation::STATS_FILENAME }
    let(:result_dir) { Dir.mktmpdir }
    let(:observations) { %w[some data] }

    before do
      allow(ActiveRecord::Base.connection).to receive(:migration_context).and_return(ctx)
      allow(Gitlab::Database::Migrations::Instrumentation).to receive(:new).and_return(instrumentation)
      allow(ActiveRecord::Migrator).to receive_message_chain('new.run').with(any_args).with(no_args)

      allow(instrumentation).to receive(:observe).and_yield

      stub_const('Gitlab::Database::Migrations::Instrumentation::RESULT_DIR', result_dir)
    end

    after do
      FileUtils.rm_rf(result_dir)
    end

    it 'creates result directory when one does not exist' do
      FileUtils.rm_rf(result_dir)

      expect { subject }.to change { Dir.exist?(result_dir) }.from(false).to(true)
    end

    it 'instruments the pending migration' do
      expect(instrumentation).to receive(:observe).with(2).and_yield

      subject
    end

    it 'executes the pending migration' do
      expect(ActiveRecord::Migrator).to receive_message_chain('new.run').with(:up, ctx.migrations, ctx.schema_migration, pending_migration.version).with(no_args)

      subject
    end

    it 'writes observations out to JSON file' do
      subject

      expect(File.read(File.join(result_dir, filename))).to eq(observations.to_json)
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
