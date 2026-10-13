# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::TablesSortedByForeignKeys, feature_category: :cell do
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:tables) do
    %w[_test_gitlab_main_items _test_gitlab_main_references _test_gitlab_partition_parent
      gitlab_partitions_dynamic._test_gitlab_partition_20220101
      gitlab_partitions_dynamic._test_gitlab_partition_20220102]
  end

  subject(:sorted_tables) do
    described_class.new(connection, tables).execute
  end

  before do
    statement = <<~SQL
      CREATE TABLE _test_gitlab_main_items (id serial NOT NULL PRIMARY KEY);

      CREATE TABLE _test_gitlab_main_references (
        id serial NOT NULL PRIMARY KEY,
        item_id BIGINT NOT NULL,
        CONSTRAINT fk_constrained_1 FOREIGN KEY(item_id) REFERENCES _test_gitlab_main_items(id)
      );

      CREATE TABLE _test_gitlab_partition_parent (
        id bigserial not null,
        created_at timestamptz not null,
        item_id BIGINT NOT NULL,
        primary key (id, created_at),
        CONSTRAINT fk_constrained_1 FOREIGN KEY(item_id) REFERENCES _test_gitlab_main_items(id)
      ) PARTITION BY RANGE(created_at);

      CREATE TABLE gitlab_partitions_dynamic._test_gitlab_partition_20220101
      PARTITION OF _test_gitlab_partition_parent
      FOR VALUES FROM ('20220101') TO ('20220131');

      CREATE TABLE gitlab_partitions_dynamic._test_gitlab_partition_20220102
      PARTITION OF _test_gitlab_partition_parent
      FOR VALUES FROM ('20220201') TO ('20220228');

      ALTER TABLE _test_gitlab_partition_parent DETACH PARTITION gitlab_partitions_dynamic._test_gitlab_partition_20220101;
      ALTER TABLE _test_gitlab_partition_parent DETACH PARTITION gitlab_partitions_dynamic._test_gitlab_partition_20220102;

      /* For some reason FK is now created in gitlab_partitions_dynamic */
      ALTER TABLE gitlab_partitions_dynamic._test_gitlab_partition_20220101
        DROP CONSTRAINT fk_constrained_1;
      ALTER TABLE gitlab_partitions_dynamic._test_gitlab_partition_20220101
        ADD CONSTRAINT fk_constrained_1 FOREIGN KEY(item_id) REFERENCES _test_gitlab_main_items(id);
    SQL
    connection.execute(statement)
  end

  describe '#execute' do
    it 'returns the tables sorted by the foreign keys dependency' do
      expect(sorted_tables).to eq(
        [
          ['_test_gitlab_main_references'],
          ['_test_gitlab_partition_parent'],
          ['gitlab_partitions_dynamic._test_gitlab_partition_20220101'],
          ['gitlab_partitions_dynamic._test_gitlab_partition_20220102'],
          ['_test_gitlab_main_items']
        ])
    end

    it 'returns both tables together if they are strongly connected' do
      statement = <<~SQL
        ALTER TABLE _test_gitlab_main_items ADD COLUMN reference_id BIGINT
        REFERENCES _test_gitlab_main_references(id)
      SQL
      connection.execute(statement)

      expect(sorted_tables).to eq(
        [
          ['_test_gitlab_partition_parent'],
          ['gitlab_partitions_dynamic._test_gitlab_partition_20220101'],
          ['gitlab_partitions_dynamic._test_gitlab_partition_20220102'],
          %w[_test_gitlab_main_items _test_gitlab_main_references]
        ])
    end

    context 'when a foreign key targets an attached partition' do
      let(:tables) do
        %w[_test_attached_partition_parent _test_attached_partition_part _test_attached_partition_referrer]
      end

      before do
        # Use names that sort alphabetically *before* the referrer so that, without
        # the fix, the parent ends up in an earlier SCC than the referrer - the
        # exact ordering that triggered the production TRUNCATE failure on
        # `uploads` / `vulnerability_archive_export_uploads` /
        # `vulnerability_archive_export_upload_states`.
        connection.execute(<<~SQL)
          CREATE TABLE _test_attached_partition_parent (
            id bigserial NOT NULL,
            kind text NOT NULL,
            PRIMARY KEY (id, kind)
          ) PARTITION BY LIST(kind);

          CREATE TABLE _test_attached_partition_part
            PARTITION OF _test_attached_partition_parent
            FOR VALUES IN ('foo');

          CREATE UNIQUE INDEX idx_test_attached_partition_part_id
            ON _test_attached_partition_part (id);

          CREATE TABLE _test_attached_partition_referrer (
            id serial NOT NULL PRIMARY KEY,
            ref_id BIGINT NOT NULL,
            CONSTRAINT fk_test_attached_partition FOREIGN KEY(ref_id)
              REFERENCES _test_attached_partition_part(id)
          );
        SQL
      end

      it 'sorts the referencer before the partition parent so TRUNCATE cascade is safe',
        :aggregate_failures do
        flat = sorted_tables.flatten

        expect(flat.index('_test_attached_partition_referrer'))
          .to be < flat.index('_test_attached_partition_parent')
        expect(flat.index('_test_attached_partition_referrer'))
          .to be < flat.index('_test_attached_partition_part')
      end
    end

    context 'when an attached partition holds a foreign key to a listed table' do
      # Mirrors the sec-database failure: `web_hook_logs_daily` attached
      # partitions hold an FK to `projects`, which is not on the parent.
      # `target` sorts alphabetically before the parent, so without the fix it
      # lands in an earlier SCC and its TRUNCATE cascade trips the FK check.
      let(:tables) do
        %w[_test_held_aaa_target _test_held_zzz_parent]
      end

      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_held_aaa_target (id bigserial NOT NULL PRIMARY KEY);

          CREATE TABLE _test_held_zzz_parent (
            id bigserial NOT NULL,
            kind text NOT NULL,
            target_id bigint,
            PRIMARY KEY (id, kind)
          ) PARTITION BY LIST(kind);

          CREATE TABLE _test_held_zzz_parent_part
            PARTITION OF _test_held_zzz_parent
            FOR VALUES IN ('foo');

          ALTER TABLE _test_held_zzz_parent_part
            ADD CONSTRAINT fk_test_held_partition FOREIGN KEY(target_id)
              REFERENCES _test_held_aaa_target(id);
        SQL
      end

      it 'sorts the partition parent before the referenced target so TRUNCATE cascade is safe' do
        flat = sorted_tables.flatten

        expect(flat.index('_test_held_zzz_parent'))
          .to be < flat.index('_test_held_aaa_target')
      end
    end
  end
end
