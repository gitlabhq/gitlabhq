# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db partition management tasks', feature_category: :database do
  include Database::PartitioningHelpers

  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/db/cells_partition_management'
  end

  before do
    Rake::Task['gitlab:db:export_partition_definitions'].reenable
    Rake::Task['gitlab:db:ensure_partitions'].reenable
  end

  describe 'gitlab:db:export_partition_definitions' do
    it 'outputs valid JSON to stdout' do
      expect { Rake::Task['gitlab:db:export_partition_definitions'].invoke }
        .to output(/\[.*"database".*"tables".*\]/m).to_stdout
    end

    it 'includes integer range-partitioned tables' do
      expect { Rake::Task['gitlab:db:export_partition_definitions'].invoke }
        .to output(/merge_request_commits_metadata/).to_stdout
    end

    it 'skips excluded databases like geo' do
      original_method = Gitlab::Database::EachDatabase.method(:each_connection)

      allow(Gitlab::Database::EachDatabase).to receive(:each_connection) do |**_kwargs, &block|
        block.call(ApplicationRecord.connection, 'geo')
        original_method.call(&block)
      end

      expect { Rake::Task['gitlab:db:export_partition_definitions'].invoke }
        .not_to output(/"database"\s*:\s*"geo"/).to_stdout
    end

    it 'includes time-range partitioned tables' do
      expect { Rake::Task['gitlab:db:export_partition_definitions'].invoke }
        .to output(/audit_events/).to_stdout
    end

    it 'includes list-partitioned tables' do
      expect { Rake::Task['gitlab:db:export_partition_definitions'].invoke }
        .to output(/p_sent_notifications/).to_stdout
    end

    context 'with a multi-value list partition' do
      before do
        ApplicationRecord.connection.execute(<<~SQL)
          CREATE TABLE _test_rake_multi_list_partitioned
            (id serial NOT NULL, partition_id bigint NOT NULL, PRIMARY KEY (id, partition_id))
            PARTITION BY LIST (partition_id);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_rake_multi_list_1_2
            PARTITION OF _test_rake_multi_list_partitioned
            FOR VALUES IN ('1', '2');
        SQL
      end

      after do
        ApplicationRecord.connection.execute('DROP TABLE IF EXISTS _test_rake_multi_list_partitioned CASCADE')
      end

      it 'excludes multi-value list partitions' do
        expect { Rake::Task['gitlab:db:export_partition_definitions'].invoke }
          .not_to output(/_test_rake_multi_list_1_2/).to_stdout
      end
    end
  end

  describe 'gitlab:db:ensure_partitions' do
    let(:connection) { ApplicationRecord.connection }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE _test_rake_partitioned
          (id serial NOT NULL, project_id bigint NOT NULL, PRIMARY KEY (id, project_id))
          PARTITION BY RANGE (project_id);

        CREATE TABLE _test_rake_date_partitioned
          (id serial NOT NULL, event_date date NOT NULL, PRIMARY KEY (id, event_date))
          PARTITION BY RANGE (event_date);

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_rake_date_partitioned_202601
          PARTITION OF _test_rake_date_partitioned
          FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

        CREATE TABLE _test_rake_list_partitioned
          (id serial NOT NULL, partition_id bigint NOT NULL, PRIMARY KEY (id, partition_id))
          PARTITION BY LIST (partition_id);

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_rake_list_partitioned_1
          PARTITION OF _test_rake_list_partitioned
          FOR VALUES IN ('1');
      SQL
    end

    after do
      connection.execute('DROP TABLE IF EXISTS _test_rake_partitioned CASCADE')
      connection.execute('DROP TABLE IF EXISTS _test_rake_date_partitioned CASCADE')
      connection.execute('DROP TABLE IF EXISTS _test_rake_list_partitioned CASCADE')
    end

    it 'creates partitions from a JSON file' do
      definitions = [
        {
          database: 'main',
          tables: [
            {
              table_name: '_test_rake_partitioned',
              partition_type: 'integer',
              partitions: [
                { partition_name: '_test_rake_partitioned_1', from: 1, to: 100 }
              ]
            },
            {
              table_name: '_test_rake_date_partitioned',
              partition_type: 'date',
              partitions: [
                { partition_name: '_test_rake_date_partitioned_202601', from: '2026-01-01', to: '2026-02-01' },
                { partition_name: '_test_rake_date_partitioned_202602', from: '2026-02-01', to: '2026-03-01' }
              ]
            },
            {
              table_name: '_test_rake_list_partitioned',
              partition_type: 'bigint',
              partition_strategy: 'list',
              partitions: [
                { partition_name: '_test_rake_list_partitioned_1', values: [1] },
                { partition_name: '_test_rake_list_partitioned_2', values: [2] }
              ]
            }
          ]
        }
      ]

      Tempfile.create(['partitions', '.json']) do |f|
        f.write(Gitlab::Json.dump(definitions))
        f.flush

        Rake::Task['gitlab:db:ensure_partitions'].invoke(f.path)
      end

      expect_range_partition_of('_test_rake_partitioned_1', '_test_rake_partitioned', "'1'", "'100'")
      expect_range_partition_of(
        '_test_rake_date_partitioned_202602',
        '_test_rake_date_partitioned',
        "'2026-02-01'",
        "'2026-03-01'"
      )
      expect(connection.table_exists?(
        "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_rake_list_partitioned_2"
      )).to be(true)
    end

    it 'skips excluded databases like geo during import' do
      original_method = Gitlab::Database::EachDatabase.method(:each_connection)

      allow(Gitlab::Database::EachDatabase).to receive(:each_connection) do |**_kwargs, &block|
        block.call(ApplicationRecord.connection, 'geo')
        original_method.call(&block)
      end

      definitions = [
        { database: 'geo', tables: [{ table_name: '_test_rake_partitioned', partitions: [] }] },
        {
          database: 'main',
          tables: [
            {
              table_name: '_test_rake_partitioned',
              partition_type: 'integer',
              partitions: [
                { partition_name: '_test_rake_partitioned_1', from: 1, to: 100 }
              ]
            }
          ]
        }
      ]

      Tempfile.create(['partitions', '.json']) do |f|
        f.write(Gitlab::Json.dump(definitions))
        f.flush

        Rake::Task['gitlab:db:ensure_partitions'].invoke(f.path)
      end

      expect_range_partition_of('_test_rake_partitioned_1', '_test_rake_partitioned', "'1'", "'100'")
    end

    context 'with DRY_RUN=true' do
      it 'reports what would be created without creating partitions' do
        definitions = [
          {
            database: 'main',
            tables: [
              {
                table_name: '_test_rake_partitioned',
                partition_type: 'integer',
                partitions: [
                  { partition_name: '_test_rake_partitioned_1', from: 1, to: 100 }
                ]
              }
            ]
          }
        ]

        Tempfile.create(['partitions', '.json']) do |f|
          f.write(Gitlab::Json.dump(definitions))
          f.flush

          stub_env('DRY_RUN', 'true')

          expect { Rake::Task['gitlab:db:ensure_partitions'].invoke(f.path) }
            .to output(/DRY RUN.*would_create=1/m).to_stdout

          expect(connection.table_exists?('_test_rake_partitioned_1')).to be(false)
        end
      end
    end

    it 'raises an error when no file is provided' do
      expect { Rake::Task['gitlab:db:ensure_partitions'].invoke }.to raise_error(ArgumentError, /File path is required/)
    end

    it 'raises an error when file does not exist' do
      expect do
        Rake::Task['gitlab:db:ensure_partitions'].invoke('/nonexistent/file.json')
      end.to raise_error(ArgumentError, /File not found/)
    end

    it 'raises an error for invalid JSON input' do
      Tempfile.create(['partitions', '.json']) do |f|
        f.write('{ invalid json')
        f.flush

        expect do
          Rake::Task['gitlab:db:ensure_partitions'].invoke(f.path)
        end.to raise_error(ArgumentError, /Invalid JSON/)
      end
    end
  end
end
