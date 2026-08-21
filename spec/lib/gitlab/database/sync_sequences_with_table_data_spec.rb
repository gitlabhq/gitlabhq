# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SyncSequencesWithTableData, :delete, feature_category: :geo_replication do
  let(:connection) { ApplicationRecord.connection }
  let(:logger) { instance_double(Gitlab::AppJsonLogger, info: nil, warn: nil, error: nil) }

  def sync!(only)
    expect { described_class.new(logger: logger, only_sequences: Array(only)).execute }
      .to output(/Advanced \d+ of \d+ sequences/).to_stdout
  end

  def last_value_of(sequence)
    connection.select_value("SELECT last_value FROM #{sequence}")
  end

  def next_value_of(sequence)
    connection.select_value("SELECT nextval('#{sequence}')")
  end

  after do
    connection.execute(<<~SQL)
      DROP TABLE IF EXISTS _test_seq_owner, _test_seq_consumer, _test_seq_trigger_owner,
        _test_seq_part_parent, gitlab_partitions_dynamic._test_seq_part_schema,
        _test_seq_reserved, _test_seq_empty, _test_seq_clamped, _test_seq_healthy CASCADE;
      DROP SEQUENCE IF EXISTS _test_shared_id_seq, _test_qualified_id_seq, _test_orphan_id_seq,
        _test_reserved_id_seq, _test_clamped_id_seq, _test_healthy_id_seq, _test_part_iid_seq;
    SQL
  end

  describe '#execute' do
    context 'with a sequence owned by one table but consumed by others' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_seq_owner (id bigint NOT NULL);
          CREATE TABLE _test_seq_consumer (id bigint NOT NULL);
          CREATE SEQUENCE _test_shared_id_seq OWNED BY _test_seq_owner.id;
          ALTER TABLE _test_seq_owner ALTER COLUMN id SET DEFAULT nextval('_test_shared_id_seq');
          ALTER TABLE _test_seq_consumer ALTER COLUMN id SET DEFAULT nextval('_test_shared_id_seq');
        SQL
      end

      it 'advances the sequence past the max of a non-owner consumer table', :aggregate_failures do
        connection.execute('INSERT INTO _test_seq_owner (id) VALUES (10)')
        connection.execute('INSERT INTO _test_seq_consumer (id) VALUES (500)')

        sync!('_test_shared_id_seq')

        expect(next_value_of('_test_shared_id_seq')).to eq(1501)
      end

      it 'advances the sequence past the max of the owner table when it is higher', :aggregate_failures do
        connection.execute('INSERT INTO _test_seq_owner (id) VALUES (500)')
        connection.execute('INSERT INTO _test_seq_consumer (id) VALUES (10)')

        sync!('_test_shared_id_seq')

        expect(next_value_of('_test_shared_id_seq')).to eq(1501)
      end

      it 'leaves the sequence unchanged when run a second time', :aggregate_failures do
        connection.execute('INSERT INTO _test_seq_owner (id) VALUES (500)')

        sync!('_test_shared_id_seq')
        value_after_first_run = last_value_of('_test_shared_id_seq')

        sync!('_test_shared_id_seq')

        expect(last_value_of('_test_shared_id_seq')).to eq(value_after_first_run)
      end

      it 'never moves a sequence backwards', :aggregate_failures do
        connection.execute("SELECT setval('_test_shared_id_seq', 5000)")
        connection.execute('INSERT INTO _test_seq_owner (id) VALUES (100)')

        sync!('_test_shared_id_seq')

        expect(last_value_of('_test_shared_id_seq')).to eq(5000)
      end
    end

    context 'with a sequence assigned through a trigger with no column default' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_seq_trigger_owner (id bigint NOT NULL);
          CREATE SEQUENCE _test_trigger_id_seq OWNED BY _test_seq_trigger_owner.id;
        SQL
      end

      it 'advances the sequence based on the owning table data, accepting a qualified scope', :aggregate_failures do
        connection.execute('INSERT INTO _test_seq_trigger_owner (id) VALUES (250)')

        sync!('public._test_trigger_id_seq')

        expect(next_value_of('_test_trigger_id_seq')).to eq(1251)
      end
    end

    context 'with a consumer table outside the search_path' do
      before do
        connection.execute(<<~SQL)
          CREATE SEQUENCE _test_qualified_id_seq;
          CREATE TABLE gitlab_partitions_dynamic._test_seq_part_schema (
            id bigint NOT NULL DEFAULT nextval('_test_qualified_id_seq')
          );
        SQL
      end

      it 'advances the sequence using the schema-qualified table name', :aggregate_failures do
        connection.execute('INSERT INTO gitlab_partitions_dynamic._test_seq_part_schema (id) VALUES (300)')

        sync!('_test_qualified_id_seq')

        expect(next_value_of('_test_qualified_id_seq')).to eq(1301)
      end
    end

    context 'with a partitioned table whose defaults live on the partitions' do
      before do
        connection.execute(<<~SQL)
          CREATE SEQUENCE _test_part_iid_seq;
          CREATE TABLE _test_seq_part_parent (id bigint NOT NULL, part int NOT NULL) PARTITION BY LIST (part);
          CREATE TABLE gitlab_partitions_dynamic._test_seq_part_parent_1
            PARTITION OF _test_seq_part_parent FOR VALUES IN (1);
          CREATE TABLE gitlab_partitions_dynamic._test_seq_part_parent_2
            PARTITION OF _test_seq_part_parent FOR VALUES IN (2);
          ALTER TABLE gitlab_partitions_dynamic._test_seq_part_parent_1
            ALTER COLUMN id SET DEFAULT nextval('_test_part_iid_seq');
          ALTER TABLE gitlab_partitions_dynamic._test_seq_part_parent_2
            ALTER COLUMN id SET DEFAULT nextval('_test_part_iid_seq');
        SQL
      end

      it 'advances the sequence once, past the max across all partitions', :aggregate_failures do
        connection.execute('INSERT INTO _test_seq_part_parent (id, part) VALUES (50, 1), (700, 2)')

        sync!('_test_part_iid_seq')

        expect(next_value_of('_test_part_iid_seq')).to eq(1701)
      end
    end

    context 'with a sequence whose data sits below its MINVALUE' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_seq_reserved (id bigint NOT NULL);
          CREATE SEQUENCE _test_reserved_id_seq MINVALUE 1000 OWNED BY _test_seq_reserved.id;
          ALTER TABLE _test_seq_reserved ALTER COLUMN id SET DEFAULT nextval('_test_reserved_id_seq');
        SQL
      end

      it 'leaves the sequence untouched so reserved IDs are not burned', :aggregate_failures do
        connection.execute('INSERT INTO _test_seq_reserved (id) VALUES (1)')

        sync!('_test_reserved_id_seq')

        expect(next_value_of('_test_reserved_id_seq')).to eq(1000)
      end
    end

    context 'with empty consumer tables' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_seq_empty (id bigserial NOT NULL);
        SQL
      end

      it 'leaves the sequence untouched', :aggregate_failures do
        sync!('_test_seq_empty_id_seq')

        expect(next_value_of('_test_seq_empty_id_seq')).to eq(1)
      end
    end

    context 'with a bounded sequence' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_seq_clamped (id bigint NOT NULL);
          CREATE SEQUENCE _test_clamped_id_seq MAXVALUE 1100 OWNED BY _test_seq_clamped.id;
          ALTER TABLE _test_seq_clamped ALTER COLUMN id SET DEFAULT nextval('_test_clamped_id_seq');
          CREATE TABLE _test_seq_healthy (id bigint NOT NULL);
          CREATE SEQUENCE _test_healthy_id_seq OWNED BY _test_seq_healthy.id;
          ALTER TABLE _test_seq_healthy ALTER COLUMN id SET DEFAULT nextval('_test_healthy_id_seq');
        SQL
      end

      it 'clamps the buffered target to MAXVALUE instead of failing the run', :aggregate_failures do
        connection.execute('INSERT INTO _test_seq_clamped (id) VALUES (500)')

        sync!('_test_clamped_id_seq')

        expect(last_value_of('_test_clamped_id_seq')).to eq(1100)
      end

      it 'raises a SyncError naming sequence and database when data exceeds MAXVALUE, still syncing the rest',
        :aggregate_failures do
        connection.execute('INSERT INTO _test_seq_clamped (id) VALUES (2000)')
        connection.execute('INSERT INTO _test_seq_healthy (id) VALUES (300)')

        expect do
          described_class.new(logger: logger, only_sequences: %w[_test_clamped_id_seq _test_healthy_id_seq]).execute
        end.to raise_error(described_class::SyncError, /_test_clamped_id_seq \(main\).*MAXVALUE/)
          .and output(/errors/).to_stdout

        expect(next_value_of('_test_healthy_id_seq')).to eq(1301)
      end
    end

    context 'when run unscoped against the full schema' do
      before do
        connection.execute('CREATE SEQUENCE _test_orphan_id_seq')
      end

      # This example runs the real discovery against every configured database
      # and setval is non-transactional, so it permanently advances sequences
      # in the test databases. That is harmless (IDs only move forward) and it
      # is the only coverage proving the discovery SQL works on the real schema.
      it 'completes cleanly and reports sequences that no table consumes', :aggregate_failures do
        warnings = []
        allow(logger).to receive(:warn) { |payload| warnings << payload }

        expect { described_class.new(logger: logger).execute }
          .to output(/Advanced \d+ of \d+ sequences/).to_stdout

        expect(warnings).to include(
          hash_including('message' => 'Sequences without consumer tables were not synced',
            'sequences' => include('public._test_orphan_id_seq'))
        )
      end
    end
  end
end
