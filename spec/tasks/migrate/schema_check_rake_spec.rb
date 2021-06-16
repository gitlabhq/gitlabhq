# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.describe 'schema_version_check rake task', :silence_stdout do
  include StubENV

  before :all do
    Rake.application.rake_require 'active_record/railties/databases'
    Rake.application.rake_require 'tasks/migrate/schema_check'

    # empty task as env is already loaded
    Rake::Task.define_task :environment
  end

  before do
    allow(ActiveRecord::Migrator).to receive(:current_version).and_return(Gitlab::Database::MIN_SCHEMA_VERSION)

    # Ensure our check can re-run each time
    Rake::Task[:schema_version_check].reenable
  end

  it 'allows migrations on databases meeting the min schema version requirement' do
    expect { run_rake_task('schema_version_check') }.not_to raise_error
  end

  it 'raises an error when schema version is too old to migrate' do
    allow(ActiveRecord::Migrator).to receive(:current_version).and_return(25)
    expect { run_rake_task('schema_version_check') }.to raise_error(RuntimeError, /current database version is too old to be migrated/)
  end

  it 'skips running validation when passed the skip env variable' do
    stub_env('SKIP_SCHEMA_VERSION_CHECK', 'true')
    allow(ActiveRecord::Migrator).to receive(:current_version).and_return(25)
    expect { run_rake_task('schema_version_check') }.not_to raise_error
  end

  it 'allows migrations on fresh databases' do
    allow(ActiveRecord::Migrator).to receive(:current_version).and_return(0)
    expect { run_rake_task('schema_version_check') }.not_to raise_error
  end

  def run_rake_task(task_name)
    Rake::Task[task_name].reenable
    Rake.application.invoke_task task_name
  end
end
