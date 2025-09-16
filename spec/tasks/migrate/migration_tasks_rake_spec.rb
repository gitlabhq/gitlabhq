# frozen_string_literal: true

require 'spec_helper'

Rake.application.rake_require 'active_record/railties/databases'
Rake.application.rake_require 'tasks/migrate/migration_tasks'

RSpec.describe 'migration rake tasks', feature_category: :shared do
  shared_examples_for 'migration task delegates to RakeTaskHelpers' do |task_name|
    subject(:execute_task) { Rake::Task["db:migrate:#{task_name}_all"].invoke }

    before do
      allow(Gitlab::Database::RakeTaskHelpers).to receive(:execute_migration_task)
    end

    it 'delegates the execution to `RakeTaskHelpers`' do
      execute_task

      expect(Gitlab::Database::RakeTaskHelpers).to have_received(:execute_migration_task).with(task_name)
    end
  end

  it_behaves_like 'migration task delegates to RakeTaskHelpers', :redo
  it_behaves_like 'migration task delegates to RakeTaskHelpers', :up
  it_behaves_like 'migration task delegates to RakeTaskHelpers', :down
end
