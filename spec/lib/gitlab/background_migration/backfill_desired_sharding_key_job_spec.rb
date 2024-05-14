# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDesiredShardingKeyJob,
  feature_category: :cell,
  schema: 20231114034017 do
  let(:example_job_class) do
    Class.new(described_class) do
      operation_name :backfill_merge_request_diffs_project_id
      feature_category :cell
    end
  end

  let!(:start_id) { table(:merge_request_diffs).minimum(:id) }
  let!(:end_id) { table(:merge_request_diffs).maximum(:id) }
  let!(:migration) do
    example_job_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :merge_request_diffs,
      batch_column: :id,
      sub_batch_size: 10,
      pause_ms: 2,
      connection: ::ApplicationRecord.connection,
      job_arguments: [
        :project_id,
        :merge_requests,
        :target_project_id,
        :merge_request_id
      ]
    )
  end

  describe '#perform' do
    let!(:diffs_without_project_id) do
      13.times do
        namespace = table(:namespaces).create!(name: 'my namespace', path: 'my-namespace')
        project = table(:projects).create!(name: 'my project', path: 'my-project', namespace_id: namespace.id,
          project_namespace_id: namespace.id)
        merge_request = table(:merge_requests).create!(target_project_id: project.id, target_branch: 'main',
          source_branch: 'not-main')
        table(:merge_request_diffs).create!(merge_request_id: merge_request.id, project_id: nil)
      end
    end

    it 'backfills the missing project_id for the batch' do
      backfilled_diffs = table(:merge_request_diffs)
        .joins('INNER JOIN merge_requests ON merge_request_diffs.merge_request_id = merge_requests.id')
        .where('merge_request_diffs.project_id = merge_requests.target_project_id')

      expect do
        migration.perform
      end.to change { backfilled_diffs.count }.from(0).to(13)
    end
  end

  describe '#constuct_query' do
    it 'constructs a query using the supplied job arguments' do
      sub_batch = table(:merge_request_diffs).all

      expect(migration.construct_query(sub_batch: sub_batch)).to eq(<<~SQL)
        UPDATE merge_request_diffs
        SET project_id = merge_requests.target_project_id
        FROM merge_requests
        WHERE merge_requests.id = merge_request_diffs.merge_request_id
        AND merge_request_diffs.id IN (#{sub_batch.select(:id).to_sql})
      SQL
    end
  end
end
