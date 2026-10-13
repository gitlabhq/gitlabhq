# frozen_string_literal: true

require 'spec_helper'
require_migration!
require_migration!('swap_merge_request_diff_commits_table')

RSpec.describe DropMergeRequestDiffCommitsReverseSyncTriggers, feature_category: :code_review_workflow do
  let(:migration) { described_class.new }
  let(:swap_migration) { SwapMergeRequestDiffCommitsTable.new }
  let(:connection) { migration.connection }

  let(:trigger_base) { migration.send(:make_sync_trigger_name, described_class::SOURCE_TABLE) }
  let(:function_base) { migration.send(:make_sync_function_name, described_class::SOURCE_TABLE) }

  let(:replacement_partition) { 'gitlab_partitions_dynamic.merge_request_diff_commits_b5377a7a34_1' }
  let(:swapped_partition) { 'gitlab_partitions_dynamic.merge_request_diff_commits_1' }

  before do
    connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS #{replacement_partition}
      PARTITION OF #{SwapMergeRequestDiffCommitsTable::REPLACEMENT_TABLE} FOR VALUES FROM (1) TO (1000)
    SQL

    connection.execute("DELETE FROM #{described_class::SOURCE_TABLE}")
  end

  after do
    # Restore the pre-swap state even when an expectation failed mid-example,
    # so the swap doesn't leak into other spec files.
    swap_migration.down if connection.table_exists?(described_class::ARCHIVED_TABLE)

    connection.execute("DROP TABLE IF EXISTS #{replacement_partition}, #{swapped_partition}")
    connection.execute("DELETE FROM #{described_class::SOURCE_TABLE}")
  end

  context 'when the swap has not run', :aggregate_failures do
    it 'is a no-op in both directions and leaves the forward sync alone' do
      expect(connection.table_exists?(described_class::ARCHIVED_TABLE)).to be(false)

      migration.up
      migration.down

      expect(trigger_exists?("#{trigger_base}_reverse_insert")).to be(false)
      expect(trigger_exists?("#{trigger_base}_reverse_delete")).to be(false)
      expect(trigger_exists?("#{trigger_base}_insert")).to be(true)
    end
  end

  context 'when the swap has run', :aggregate_failures do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)

      swap_migration.up
    end

    it 'drops the reverse sync objects and stops mirroring writes into the archived table' do
      expect(trigger_exists?("#{trigger_base}_reverse_insert")).to be(true)

      migration.up

      expect(trigger_exists?("#{trigger_base}_reverse_insert")).to be(false)
      expect(trigger_exists?("#{trigger_base}_reverse_delete")).to be(false)
      expect(function_exists?("#{function_base}_reverse_insert")).to be(false)
      expect(function_exists?("#{function_base}_reverse_delete")).to be(false)

      # the live table keeps working, the archived table no longer follows it
      insert_row(diff_id: 1, metadata_id: 101)
      expect(rows(described_class::SOURCE_TABLE)).to eq([[1, 0]])
      expect(rows(described_class::ARCHIVED_TABLE)).to be_empty

      # re-running after a successful drop is a no-op
      migration.up
      expect(trigger_exists?("#{trigger_base}_reverse_insert")).to be(false)
    end

    it 'reinstates working reverse sync on down' do
      migration.up
      migration.down

      expect(trigger_exists?("#{trigger_base}_reverse_insert")).to be(true)
      expect(trigger_exists?("#{trigger_base}_reverse_delete")).to be(true)

      insert_row(diff_id: 2, metadata_id: 102)
      expect(rows(described_class::ARCHIVED_TABLE)).to eq([[2, 0]])

      connection.execute(
        "DELETE FROM #{described_class::SOURCE_TABLE} WHERE merge_request_diff_id = 2"
      )
      expect(rows(described_class::ARCHIVED_TABLE)).to be_empty
    end

    it 'does not recover rows written while the reverse sync was dropped' do
      migration.up
      insert_row(diff_id: 3, metadata_id: 103)
      migration.down

      expect(rows(described_class::SOURCE_TABLE)).to eq([[3, 0]])
      expect(rows(described_class::ARCHIVED_TABLE)).to be_empty
    end
  end

  private

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
