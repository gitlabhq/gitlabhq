# frozen_string_literal: true

require 'spec_helper'
require 'rake'

describe 'gitlab:db namespace rake task' do
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

  describe 'clean_structure_sql' do
    let_it_be(:clean_rake_task) { 'gitlab:db:clean_structure_sql' }
    let_it_be(:test_task_name) { 'gitlab:db:_test_multiple_structure_cleans' }
    let_it_be(:structure_file) { 'db/structure.sql' }
    let_it_be(:input) { 'this is structure data' }
    let(:output) { StringIO.new }

    before do
      allow(File).to receive(:read).with(structure_file).and_return(input)
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

  def run_rake_task(task_name)
    Rake::Task[task_name].reenable
    Rake.application.invoke_task task_name
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
