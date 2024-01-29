# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixInvalidRecordsCiBuildTraceMetadata, migration: :gitlab_ci, feature_category: :continuous_integration do
  let(:trace_metadata) { table(:ci_build_trace_metadata) }
  let(:job_artifacts) { table(:ci_job_artifacts) }
  let(:connection) { job_artifacts.connection }

  before do
    connection.transaction do
      connection.execute(<<~SQL)
        ALTER TABLE ci_build_trace_metadata DISABLE TRIGGER ALL;
        ALTER TABLE ci_job_artifacts DISABLE TRIGGER ALL;
      SQL

      artifact = job_artifacts.create!(project_id: 1, file_type: 1, job_id: 1, partition_id: 100)
      trace_metadata.create!(trace_artifact_id: artifact.id, build_id: 1, partition_id: 100)
      trace_metadata.create!(trace_artifact_id: non_existing_record_id, build_id: 2, partition_id: 100)

      connection.execute(<<~SQL)
        ALTER TABLE ci_build_trace_metadata ENABLE TRIGGER ALL;
        ALTER TABLE ci_job_artifacts ENABLE TRIGGER ALL;
      SQL
    end
  end

  context 'when FKs exist' do
    it 'does not remove records' do
      expect { migrate! }.not_to change { trace_metadata.count }
    end
  end

  context 'with missing FKs' do
    let(:fk_view) { :postgres_foreign_keys }
    let(:fk_table) { :_test_postgres_foreign_keys_copy }

    before do
      connection.execute(<<~SQL.squish)
        CREATE TABLE #{fk_table} (LIKE #{fk_view});
        ALTER VIEW #{fk_view} RENAME TO #{fk_view}_disabled;
        ALTER TABLE #{fk_table} RENAME TO #{fk_view};
      SQL
    end

    after do
      connection.execute(<<~SQL.squish)
        DROP TABLE IF EXISTS #{fk_view};
        ALTER VIEW #{fk_view}_disabled RENAME TO #{fk_view};
      SQL
    end

    it 'removes orphan records' do
      expect { migrate! }.to change { trace_metadata.count }.from(2).to(1)
      expect(trace_metadata.where(trace_artifact_id: non_existing_record_id)).to be_empty
    end

    context 'with invalid FKs' do
      before do
        Gitlab::Database::PostgresForeignKey.create!(
          oid: 58232131,
          name: 'fk_21d25cac1a_p',
          constrained_table_identifier: 'public.ci_build_trace_metadata',
          referenced_table_identifier: 'public.ci_job_artifacts',
          constrained_table_name: 'ci_build_trace_metadata',
          referenced_table_name: 'ci_job_artifacts',
          constrained_columns: %w[partition_id trace_artifact_id],
          referenced_columns: %w[partition_id id],
          on_delete_action: 'cascade',
          on_update_action: 'cascade',
          is_inherited: false,
          is_valid: false
        )
      end

      it 'removes orphan records' do
        expect { migrate! }.to change { trace_metadata.count }.from(2).to(1)
        expect(trace_metadata.where(trace_artifact_id: non_existing_record_id)).to be_empty
      end
    end
  end
end
