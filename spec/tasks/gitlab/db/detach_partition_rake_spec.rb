# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db:detach_partition', :silence_stdout, feature_category: :database do
  let(:connection) { ApplicationRecord.connection }
  let(:still_attached) do
    result = connection.exec_query(<<~SQL)
      SELECT (inh.inhrelid IS NOT NULL) AS is_attached
      FROM pg_class child
      LEFT JOIN pg_inherits inh ON child.oid = inh.inhrelid
      WHERE child.relname = 'test_foo_table_100'
    SQL
    result.first['is_attached']
  end

  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/db/detach_partition'
  end

  before do
    allow(Gitlab::Database::GitlabSchema).to receive(:table_schema!).and_return(:gitlab_main)
    allow(Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection).to receive(:analyze).and_return(nil)
    allow(ApplicationRecord.connection).to receive(:transaction_open?).and_return(nil)
    # mock_dictionary = instance_double(Gitlab::Database::Dictionary)
    mock_entries = instance_double(Gitlab::Database::Dictionary)
    allow(Gitlab::Database::Dictionary).to receive(:entries).and_return(mock_entries)

    allow(mock_entries).to receive(:find_detach_allowed_partitions).and_return({
      test_foo_table_100: {
        bounds_clause: "FOR VALUES IN ('100')",
        required_constraint: "(partition_id = 100)",
        parent_table: "p_test_foo_table",
        parent_schema: "public"
      }
    })
  end

  # Clean up rake tasks between tests
  after do
    Rake::Task['gitlab:db:detach_partition'].reenable
    Rake::Task['gitlab:db:reattach_partition'].reenable
  end

  describe "detach_partition", :delete do
    after do
      connection.execute <<~SQL
        DROP TABLE IF EXISTS test_foo_table_100;
        DROP TABLE IF EXISTS p_test_foo_table CASCADE;
      SQL
    end

    context 'when the partition is not allowed to be detached' do
      it 'throws a "partition not allowed" message' do
        expect do
          Rake::Task['gitlab:db:detach_partition'].invoke('some_other_table_100')
        end.to output(/some_other_table_100 is not listed as one of the allowed partitions/).to_stdout
      end
    end

    context 'when the partition does have a check constraint for partition key values' do
      before do
        connection.execute <<~SQL
          -- Create a partitioned parent table
          CREATE TABLE p_test_foo_table (
            id bigint NOT NULL,
            partition_id bigint NOT NULL,
            data text
          ) PARTITION BY LIST (partition_id);

          -- Create the partition
          CREATE TABLE test_foo_table_100 (
            id bigint NOT NULL,
            partition_id bigint NOT NULL,
            data text
          );

          -- Attach the partition to the parent table
          ALTER TABLE p_test_foo_table#{' '}
          ATTACH PARTITION test_foo_table_100#{' '}
          FOR VALUES IN ('100');

          -- Create the required constraint
          ALTER TABLE test_foo_table_100#{' '}
          ADD CONSTRAINT check_partition_id#{' '}
          CHECK (partition_id = 100);
        SQL
      end

      it 'successfully detaches the partition' do
        expect do
          Rake::Task['gitlab:db:detach_partition'].invoke('test_foo_table_100')
        end.to output(/Successfully detached partition test_foo_table_100/).to_stdout

        # Verify partition is detached
        expect(still_attached).to be false
      end

      it 'can reattach the partition after detaching' do
        # First detach
        Rake::Task['gitlab:db:detach_partition'].invoke('test_foo_table_100')

        # Clear the task to allow re-invocation
        Rake::Task['gitlab:db:reattach_partition'].reenable

        # Then reattach
        expect do
          Rake::Task['gitlab:db:reattach_partition'].invoke('test_foo_table_100')
        end.to output(/Successfully reattached partition test_foo_table_100/).to_stdout

        # Verify partition is attached again
        expect(still_attached).to be true
      end
    end

    context 'when the bounds clause mismatches' do
      before do
        connection.execute <<~SQL
          -- Create a partitioned parent table
          CREATE TABLE p_test_foo_table (
            id bigint NOT NULL,
            partition_id bigint NOT NULL,
            data text
          ) PARTITION BY LIST (partition_id);

          -- Create the partition
          CREATE TABLE test_foo_table_100 (
            id bigint NOT NULL,
            partition_id bigint NOT NULL,
            data text
          );

          -- Attach the partition to the parent table
          ALTER TABLE p_test_foo_table#{' '}
          ATTACH PARTITION test_foo_table_100#{' '}
          FOR VALUES IN ('101');

          -- Create the required constraint
          ALTER TABLE test_foo_table_100#{' '}
          ADD CONSTRAINT check_partition_id#{' '}
          CHECK (partition_id = 101);
        SQL
      end

      it 'throws a "Bounds clause mismatch" error' do
        expect do
          Rake::Task['gitlab:db:detach_partition'].invoke('test_foo_table_100')
        end.to output(/Bounds clause mismatch/).to_stdout

        # Verify partition is attached again
        expect(still_attached).to be true
      end
    end

    context 'when trying to detach an already detached partition' do
      before do
        # Create constraint and detach first
        connection.execute <<~SQL
          -- Create a partitioned parent table
          CREATE TABLE p_test_foo_table (
            id bigint NOT NULL,
            partition_id bigint NOT NULL,
            data text
          ) PARTITION BY LIST (partition_id);

          -- Create the partition
          CREATE TABLE test_foo_table_100 (
            id bigint NOT NULL,
            partition_id bigint NOT NULL,
            data text
          );
          -- Create the constraint
          ALTER TABLE test_foo_table_100#{' '}
          ADD CONSTRAINT check_partition_id#{' '}
          CHECK ((partition_id = 100));
        SQL

        Rake::Task['gitlab:db:detach_partition'].invoke('test_foo_table_100')
        Rake::Task['gitlab:db:detach_partition'].reenable
      end

      it 'outputs message about partition not being attached' do
        expect do
          Rake::Task['gitlab:db:detach_partition'].invoke('test_foo_table_100')
        end.to output(/Partition test_foo_table_100 is not attached/).to_stdout
      end
    end

    context 'when trying to reattach an already attached partition' do
      before do
        connection.execute <<~SQL
          -- Create a partitioned parent table
          CREATE TABLE p_test_foo_table (
            id bigint NOT NULL,
            partition_id bigint NOT NULL,
            data text
          ) PARTITION BY LIST (partition_id);

          -- Create the partition
          CREATE TABLE test_foo_table_100 (
            id bigint NOT NULL,
            partition_id bigint NOT NULL,
            data text
          );

          -- Attach the partition to the parent table
          ALTER TABLE p_test_foo_table#{' '}
          ATTACH PARTITION test_foo_table_100#{' '}
          FOR VALUES IN ('100');

          -- Create the required constraint
          ALTER TABLE test_foo_table_100#{' '}
          ADD CONSTRAINT check_partition_id#{' '}
          CHECK (partition_id = 100);
        SQL
      end

      it 'outputs message about partition already being attached' do
        expect do
          Rake::Task['gitlab:db:reattach_partition'].invoke('test_foo_table_100')
        end.to output(/Partition test_foo_table_100 is already attached/).to_stdout
      end
    end
  end

  describe 'gitlab:db:detach_partition and reattach_partition database-specific tasks' do
    let(:partition_name) { 'test_partition_100' }
    let(:databases) { { 'main' => {}, 'ci' => {} } }

    before do
      skip_if_shared_database(:ci)

      allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:setup_initial_database_yaml).and_return(databases)
      allow(Gitlab::Database::Dictionary).to receive_message_chain(:entries,
        :find_detach_allowed_partitions).and_return({})
      allow(Gitlab::Database::EachDatabase).to receive(:each_connection)
    end

    describe 'task registration' do
      it 'creates detach and reattach tasks for each database' do
        %w[main ci].each do |database_name|
          expect(Rake::Task.task_defined?("gitlab:db:detach_partition:#{database_name}")).to be true
          expect(Rake::Task.task_defined?("gitlab:db:reattach_partition:#{database_name}")).to be true
        end
      end
    end

    describe 'detach_partition tasks' do
      it 'calls the task for each database' do
        %w[main ci].each do |database_name|
          expect(Rake::Task["gitlab:db:detach_partition:#{database_name}"]).to receive(:invoke).with(partition_name)
          Rake::Task["gitlab:db:detach_partition:#{database_name}"].invoke(partition_name)
          Rake::Task["gitlab:db:detach_partition:#{database_name}"].reenable
        end
      end
    end

    describe 'reattach_partition tasks' do
      it 'calls the task for each database' do
        %w[main ci].each do |database_name|
          expect(Rake::Task["gitlab:db:reattach_partition:#{database_name}"]).to receive(:invoke).with(partition_name)
          Rake::Task["gitlab:db:reattach_partition:#{database_name}"].invoke(partition_name)
          Rake::Task["gitlab:db:reattach_partition:#{database_name}"].reenable
        end
      end
    end
  end
end
