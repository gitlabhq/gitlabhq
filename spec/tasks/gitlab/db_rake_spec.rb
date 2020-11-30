# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.describe 'gitlab:db namespace rake task' do
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
    let_it_be(:structure_file) { 'db/structure.sql' }
    let_it_be(:input) { 'this is structure data' }
    let(:output) { StringIO.new }

    before do
      stub_file_read(structure_file, content: input)
      allow(File).to receive(:open).with(structure_file, any_args).and_yield(output)
    end

    after do
      Rake::Task[test_task_name].clear if Rake::Task.task_defined?(test_task_name)
    end

    it 'can be executed multiple times within another rake task' do
      expect_multiple_executions_of_task(test_task_name, clean_rake_task) do
        expect_next_instance_of(Gitlab::Database::SchemaCleaner) do |cleaner|
          expect(cleaner).to receive(:clean).with(output)
        end
      end
    end
  end

  describe 'load_custom_structure' do
    let_it_be(:db_config) { Rails.application.config_for(:database) }
    let_it_be(:custom_load_task) { 'gitlab:db:load_custom_structure' }
    let_it_be(:custom_filepath) { Pathname.new('db/directory') }

    it 'uses the psql command to load the custom structure file' do
      expect(Gitlab::Database::CustomStructure).to receive(:custom_dump_filepath).and_return(custom_filepath)

      expect(Kernel).to receive(:system)
        .with('psql', any_args, custom_filepath.to_path, db_config['database']).and_return(true)

      run_rake_task(custom_load_task)
    end

    it 'raises an error when the call to the psql command fails' do
      expect(Gitlab::Database::CustomStructure).to receive(:custom_dump_filepath).and_return(custom_filepath)

      expect(Kernel).to receive(:system)
        .with('psql', any_args, custom_filepath.to_path, db_config['database']).and_return(nil)

      expect { run_rake_task(custom_load_task) }.to raise_error(/failed to execute:\s*psql/)
    end
  end

  describe 'dump_custom_structure' do
    let_it_be(:test_task_name) { 'gitlab:db:_test_multiple_task_executions' }
    let_it_be(:custom_dump_task) { 'gitlab:db:dump_custom_structure' }

    after do
      Rake::Task[test_task_name].clear if Rake::Task.task_defined?(test_task_name)
    end

    it 'can be executed multiple times within another rake task' do
      expect_multiple_executions_of_task(test_task_name, custom_dump_task) do
        expect_next_instance_of(Gitlab::Database::CustomStructure) do |custom_structure|
          expect(custom_structure).to receive(:dump)
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

    context 'when no index_name is given' do
      it 'rebuilds a random number of large indexes' do
        expect(Gitlab::Database::Reindexing).to receive_message_chain('candidate_indexes.random_few').and_return(indexes)
        expect(Gitlab::Database::Reindexing).to receive(:perform).with(indexes)

        run_rake_task('gitlab:db:reindex')
      end
    end

    context 'with index name given' do
      let(:index) { double('index') }

      it 'calls the index rebuilder with the proper arguments' do
        expect(Gitlab::Database::PostgresIndex).to receive(:by_identifier).with('public.foo_idx').and_return(index)
        expect(Gitlab::Database::Reindexing).to receive(:perform).with([index])

        run_rake_task('gitlab:db:reindex', '[public.foo_idx]')
      end

      it 'raises an error if the index does not exist' do
        expect(Gitlab::Database::PostgresIndex).to receive(:by_identifier).with('public.absent_index').and_raise(ActiveRecord::RecordNotFound)

        expect { run_rake_task('gitlab:db:reindex', '[public.absent_index]') }.to raise_error(ActiveRecord::RecordNotFound)
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
