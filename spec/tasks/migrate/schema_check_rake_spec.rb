require 'spec_helper'
require 'rake'

describe 'schema_version_check rake task' do
  before :all do
    Rake.application.rake_require 'active_record/railties/databases'

    # empty task as env is already loaded
    Rake::Task.define_task :environment
  end

  before do
    # Stub out db tasks
    allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:migrate).and_return(true)
    allow(ActiveRecord::Migrator).to receive(:current_version).and_return(Gitlab::Database::MIN_SCHEMA_VERSION)
  end

  it 'raises an error when schema version is too old to migrate' do
    allow(ActiveRecord::Migrator).to receive(:current_version).and_return(25)
    expect { run_rake_task('db:migrate') }.to raise_error(RuntimeError, /current database version is too old to be migrated/)
  end

  def run_rake_task(task_name)
    Rake::Task[task_name].reenable
    Rake.application.invoke_task task_name
  end
end
