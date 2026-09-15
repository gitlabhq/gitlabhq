# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapMergeRequestDiffCommitsTable, feature_category: :code_review_workflow do
  let(:migration) { described_class.new }
  let(:connection) { migration.connection }

  let(:trigger_base) { migration.send(:make_sync_trigger_name, described_class::SOURCE_TABLE) }
  let(:function_base) { migration.send(:make_sync_function_name, described_class::SOURCE_TABLE) }

  let(:replacement_partition) { 'gitlab_partitions_dynamic.merge_request_diff_commits_b5377a7a34_1' }
  let(:swapped_partition) { 'gitlab_partitions_dynamic.merge_request_diff_commits_1' }

  before do
    connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS #{replacement_partition}
      PARTITION OF #{described_class::REPLACEMENT_TABLE} FOR VALUES FROM (1) TO (1000)
    SQL
  end

  after do
    # Restore the pre-swap state even when an expectation failed mid-example,
    # so the swap doesn't leak into other spec files.
    migration.down if connection.table_exists?(described_class::ARCHIVED_TABLE)

    connection.execute("DROP TABLE IF EXISTS #{replacement_partition}, #{swapped_partition}")
    connection.execute("DELETE FROM #{described_class::SOURCE_TABLE}")
  end

  context 'when not on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    it 'is a no-op in both directions' do
      migration.up

      expect(connection.table_exists?(described_class::ARCHIVED_TABLE)).to be(false)
      expect(table_kind(described_class::SOURCE_TABLE)).to eq('r')

      migration.down

      expect(table_kind(described_class::REPLACEMENT_TABLE)).to eq('p')
      expect(trigger_exists?("#{trigger_base}_insert")).to be(true)
    end
  end

  context 'when on GitLab.com', :aggregate_failures do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    it 'swaps the tables, keeps both sync directions working, and is reversible' do
      insert_row(diff_id: 1, metadata_id: 101)

      # sanity: the pre-existing forward sync mirrors legacy writes into the partitioned table
      expect(rows(described_class::REPLACEMENT_TABLE)).to eq([[1, 0]])

      migration.up

      # the live name is now the partitioned table, the legacy heap table is archived
      expect(table_kind(described_class::SOURCE_TABLE)).to eq('p')
      expect(table_kind(described_class::ARCHIVED_TABLE)).to eq('r')
      expect(connection.table_exists?(described_class::REPLACEMENT_TABLE)).to be(false)

      # the partition followed the parent's rename
      expect(table_kind(swapped_partition)).to eq('r')
      expect(table_kind(replacement_partition)).to be_nil

      # pre-swap rows are visible through both names
      expect(rows(described_class::SOURCE_TABLE)).to eq([[1, 0]])
      expect(rows(described_class::ARCHIVED_TABLE)).to eq([[1, 0]])

      # forward sync objects are gone, reverse sync objects are live
      expect(trigger_exists?("#{trigger_base}_insert")).to be(false)
      expect(function_exists?("#{function_base}_insert")).to be(false)
      expect(trigger_exists?("#{trigger_base}_reverse_insert")).to be(true)
      expect(trigger_exists?("#{trigger_base}_reverse_delete")).to be(true)

      # writes to the live table flow back into the archived table
      insert_row(diff_id: 2, metadata_id: 102)
      expect(rows(described_class::ARCHIVED_TABLE)).to eq([[1, 0], [2, 0]])

      connection.execute(
        "DELETE FROM #{described_class::SOURCE_TABLE} WHERE merge_request_diff_id = 1"
      )
      expect(rows(described_class::ARCHIVED_TABLE)).to eq([[2, 0]])

      # rows past the int4 ceiling are skipped by the reverse sync instead of
      # erroring (on GitLab.com the archived table's merge_request_diff_id is
      # physically int4)
      insert_row(diff_id: 2_147_483_648, metadata_id: 104)
      expect(rows(described_class::SOURCE_TABLE)).to include([2_147_483_648, 0])
      expect(rows(described_class::ARCHIVED_TABLE)).to eq([[2, 0]])

      # re-running up after a successful swap leaves the swap intact
      migration.up
      expect(table_kind(described_class::SOURCE_TABLE)).to eq('p')
      expect(trigger_exists?("#{trigger_base}_reverse_insert")).to be(true)

      migration.down

      # original names and shapes restored
      expect(table_kind(described_class::SOURCE_TABLE)).to eq('r')
      expect(table_kind(described_class::REPLACEMENT_TABLE)).to eq('p')
      expect(connection.table_exists?(described_class::ARCHIVED_TABLE)).to be(false)
      expect(table_kind(replacement_partition)).to eq('r')

      # the reinstated legacy table includes the row written while the swap was
      # live, but not the over-int4-ceiling row (rollback can't restore those)
      expect(rows(described_class::SOURCE_TABLE)).to eq([[2, 0]])

      # reverse sync objects removed, forward sync restored and functional
      expect(trigger_exists?("#{trigger_base}_reverse_insert")).to be(false)
      expect(function_exists?("#{function_base}_reverse_insert")).to be(false)

      insert_row(diff_id: 3, metadata_id: 103)
      expect(rows(described_class::REPLACEMENT_TABLE)).to eq([[2, 0], [3, 0], [2_147_483_648, 0]])
    end

    it 'finishes the reverse sync triggers when an earlier run stopped after the rename' do
      # Replay the prefix of `up` that an interrupted run could have left behind.
      connection.execute(<<~SQL)
        DROP TRIGGER IF EXISTS #{trigger_base}_insert ON #{described_class::SOURCE_TABLE};
        DROP TRIGGER IF EXISTS #{trigger_base}_delete ON #{described_class::SOURCE_TABLE};
        DROP FUNCTION IF EXISTS #{function_base}_insert;
        DROP FUNCTION IF EXISTS #{function_base}_delete;
      SQL

      migration.send(
        :replace_tables,
        replacement: described_class::REPLACEMENT_TABLE,
        replaced: described_class::ARCHIVED_TABLE
      )

      expect(trigger_exists?("#{trigger_base}_reverse_insert")).to be(false)

      migration.up

      expect(table_kind(described_class::SOURCE_TABLE)).to eq('p')
      expect(table_kind(described_class::ARCHIVED_TABLE)).to eq('r')
      expect(trigger_exists?("#{trigger_base}_reverse_insert")).to be(true)
      expect(trigger_exists?("#{trigger_base}_reverse_delete")).to be(true)

      # the reverse sync the re-run installed is functional
      insert_row(diff_id: 4, metadata_id: 104)
      expect(rows(described_class::ARCHIVED_TABLE)).to eq([[4, 0]])
    end
  end

  private

  def table_kind(name)
    schema, table = name.include?('.') ? name.split('.') : ['public', name]

    connection.select_value(<<~SQL)
      SELECT relkind FROM pg_class
      WHERE relname = #{connection.quote(table)}
        AND relnamespace = #{connection.quote(schema)}::regnamespace
    SQL
  end

  def trigger_exists?(name)
    migration.send(:trigger_exists?, described_class::SOURCE_TABLE, name)
  end

  def function_exists?(name)
    migration.send(:function_exists?, name)
  end

  def rows(table)
    connection.select_rows(
      "SELECT merge_request_diff_id, relative_order FROM #{table} ORDER BY merge_request_diff_id"
    )
  end

  def insert_row(diff_id:, metadata_id:)
    connection.execute(<<~SQL)
      INSERT INTO #{described_class::SOURCE_TABLE}
        (merge_request_diff_id, relative_order, project_id, merge_request_commits_metadata_id)
      VALUES (#{diff_id}, 0, 1, #{metadata_id})
    SQL
  end
end
