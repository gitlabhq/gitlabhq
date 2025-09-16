# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::RakeTaskHelpers, feature_category: :database do
  describe '.execute_migration_task' do
    context 'when the given task is unknown' do
      it 'raises a runtime error' do
        expect { described_class.execute_migration_task('Unknown Task') }.to raise_error(RuntimeError)
      end
    end

    context 'when the given task is known' do
      shared_examples_for 'a task mapped to rails' do |task_name, mapped_tasks|
        let(:databases) { double }
        let(:mock_migration_task) { spy }
        let(:mock_dump_task) { spy }
        let(:expected_tasks_count) { mapped_tasks.count * 2 }

        subject(:execute_task) { described_class.execute_migration_task(task_name) }

        before do
          # Clears the memoization to prevent leaking test doubles between tests
          described_class.instance_variable_set(:@databases, nil)

          allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:setup_initial_database_yaml).and_return(databases)
          allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:for_each).with(databases).and_yield(:a).and_yield(:b)

          mapped_tasks.each do |mapped_task|
            allow(Rake::Task).to receive(:[]).with("db:migrate:#{mapped_task}:a").and_return(mock_migration_task)
            allow(Rake::Task).to receive(:[]).with("db:migrate:#{mapped_task}:b").and_return(mock_migration_task)
          end

          allow(Rake::Task).to receive(:[]).with('db:_dump').and_return(mock_dump_task)
        end

        it 'executes the regular matching tasks for all databases' do
          execute_task

          expect(Rake::Task).to have_received(:[]).exactly(expected_tasks_count + 1).times
          expect(mock_migration_task).to have_received(:invoke).exactly(expected_tasks_count).times
          expect(mock_dump_task).to have_received(:invoke).once
        end
      end

      it_behaves_like 'a task mapped to rails', :up, [:up]
      it_behaves_like 'a task mapped to rails', :down, [:down]
      it_behaves_like 'a task mapped to rails', :redo, [:up, :down]
    end
  end
end
