# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeduplicatePipelineIids, feature_category: :continuous_integration do
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:organizations_table) { table(:organizations, database: :main) }
  let(:namespaces_table) { table(:namespaces, database: :main) }
  let(:projects_table) { table(:projects, database: :main) }
  let(:internal_ids_table) { table(:internal_ids, database: :main) }
  let(:pipelines_table) { ci_partitioned_table(:p_ci_pipelines) }
  let(:pipeline_iids_table) { table(:p_ci_pipeline_iids, database: :ci) }

  let(:usage_value) { described_class::CI_PIPELINES_USAGE }
  let(:organization) { organizations_table.create!(name: 'organization', path: 'organization') }
  let(:namespace1) { namespaces_table.create!(organization_id: organization.id, name: 'name1', path: 'namespace1') }
  let(:namespace2) { namespaces_table.create!(organization_id: organization.id, name: 'name2', path: 'namespace2') }

  # Project that has duplicate iids
  let(:project1) do
    projects_table.create!(
      organization_id: organization.id,
      namespace_id: namespace1.id,
      project_namespace_id: namespace1.id
    )
  end

  # Control project with no duplicates
  let(:project2) do
    projects_table.create!(
      organization_id: organization.id,
      namespace_id: namespace2.id,
      project_namespace_id: namespace2.id
    )
  end

  # Ids of the partition that the current BBM instance is batching through
  let(:partition_ids) { [203] }

  let(:migration) do
    described_class.new(
      start_id: pipelines_table.where(partition_id: partition_ids).minimum(:id),
      end_id: pipelines_table.where(partition_id: partition_ids).maximum(:id),
      batch_table: "gitlab_partitions_dynamic.ci_pipelines_#{partition_ids.min}",
      batch_column: :id,
      job_arguments: [partition_ids],
      sub_batch_size: 2,
      pause_ms: 0,
      connection: connection
    )
  end

  before do
    # The testing env might initialize the first partition as `ci_pipelines FOR VALUES IN ('100', '101', '102')`
    # instead of ci_pipelines_100, so we start from partition_id 200 to safely avoid a partition overlap error.
    connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_pipelines_200"
        PARTITION OF "p_ci_pipelines" FOR VALUES IN (200, 201, 202);
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_pipelines_203"
        PARTITION OF "p_ci_pipelines" FOR VALUES IN (203);
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_pipelines_204"
        PARTITION OF "p_ci_pipelines" FOR VALUES IN (204);
    SQL
  end

  describe '#perform' do
    subject(:perform) { migration.perform }

    before do
      # Disable the pipeline iid triggers on p_ci_pipelines so that we can set up duplicate iids for testing
      connection.transaction do
        connection.execute(<<~SQL)
          ALTER TABLE p_ci_pipelines DISABLE TRIGGER trigger_ensure_pipeline_iid_uniqueness_before_insert;
          ALTER TABLE p_ci_pipelines DISABLE TRIGGER trigger_ensure_pipeline_iid_uniqueness_before_update_iid;
          ALTER TABLE p_ci_pipelines DISABLE TRIGGER trigger_cleanup_pipeline_iid_after_delete;
        SQL

        # Duplicates for project1:
        # iid=2 exists in partition_ids 200, 201, 202
        # iid=3 exists in partition_ids 200, 203, 204
        # iid=4 exists in partition_ids 202, 203
        # iid=5 exists in partition_ids 203, 204

        # Data on partition 200 (partition ids 200, 201, 202)
        pipelines_table.create!(project_id: project1.id, partition_id: 200, iid: 1) # Non-dup
        pipelines_table.create!(project_id: project1.id, partition_id: 200, iid: 2)
        pipelines_table.create!(project_id: project1.id, partition_id: 200, iid: 3)
        pipelines_table.create!(project_id: project1.id, partition_id: 201, iid: 2)
        pipelines_table.create!(project_id: project1.id, partition_id: 202, iid: 2)
        pipelines_table.create!(project_id: project1.id, partition_id: 202, iid: 4)
        pipelines_table.create!(project_id: project1.id, partition_id: 200, iid: nil)

        # Data on partition 203
        pipelines_table.create!(project_id: project1.id, partition_id: 203, iid: 3)
        pipelines_table.create!(project_id: project1.id, partition_id: 203, iid: 4)
        pipelines_table.create!(project_id: project1.id, partition_id: 203, iid: 5)
        pipelines_table.create!(project_id: project1.id, partition_id: 203, iid: nil)

        # Data on partition 204
        pipelines_table.create!(project_id: project1.id, partition_id: 204, iid: 3)
        pipelines_table.create!(project_id: project1.id, partition_id: 204, iid: 5)
        pipelines_table.create!(project_id: project1.id, partition_id: 204, iid: 6) # Non-dup

        # Pipeline iid records that should already exist (from the earlier backfill)
        (1..6).each { |iid| pipeline_iids_table.create!(project_id: project1.id, iid: iid) }

        # Re-enable triggers
        connection.execute(<<~SQL)
          ALTER TABLE p_ci_pipelines ENABLE TRIGGER trigger_ensure_pipeline_iid_uniqueness_before_insert;
          ALTER TABLE p_ci_pipelines ENABLE TRIGGER trigger_ensure_pipeline_iid_uniqueness_before_update_iid;
          ALTER TABLE p_ci_pipelines ENABLE TRIGGER trigger_cleanup_pipeline_iid_after_delete;
        SQL
      end

      # Control data for project2; no duplicates
      pipelines_table.create!(project_id: project2.id, partition_id: 200, iid: 1)
      pipelines_table.create!(project_id: project2.id, partition_id: 201, iid: 2)
      pipelines_table.create!(project_id: project2.id, partition_id: 202, iid: 3)
      pipelines_table.create!(project_id: project2.id, partition_id: 203, iid: 4)
      pipelines_table.create!(project_id: project2.id, partition_id: 204, iid: 5)

      # Internal ID records that align with the current max iid for each project
      internal_ids_table.create!(project_id: project1.id, usage: usage_value, last_value: 6)
      internal_ids_table.create!(project_id: project2.id, usage: usage_value, last_value: 5)
    end

    shared_examples 'deduplicates pipeline iids' do
      it 'assigns a fresh iid to every copy of a duplicate found in a previous partition' do
        ids_to_deduplicate = pipelines_table.where(project_id: project1.id, iid: [3, 4]).pluck(:id)
        to_deduplicate = pipelines_table.where(id: ids_to_deduplicate)
        others = pipelines_table.where.not(id: ids_to_deduplicate)

        expect { perform }
          .to change { to_deduplicate.pluck(:iid).sort }.from([3, 3, 3, 4, 4]).to([7, 8, 9, 10, 11])
          .and not_change { others.order(:id).map(&:attributes) }
      end
    end

    it_behaves_like 'deduplicates pipeline iids'

    it 'reserves the iids and updates internal_ids record' do
      expect { perform }
        .to change { project1_internal_id.last_value }.from(6).to(11)
        .and not_change { project2_internal_id.last_value }
    end

    it 'keeps p_ci_pipeline_iids consistent for the reassigned iids' do
      perform

      # The old duplicated iids (3, 4) are removed and the freshly assigned ones are tracked
      iids = pipeline_iids_table.where(project_id: project1.id).pluck(:iid)
      expect(iids).to include(7, 8, 9, 10, 11)
      expect(iids).not_to include(3, 4)
    end

    it 'increments lock_version on the reassigned rows' do
      ids_to_deduplicate = pipelines_table.where(project_id: project1.id, iid: [3, 4]).pluck(:id)

      expect { perform }
        .to change { pipelines_table.where(id: ids_to_deduplicate).pluck(:lock_version).uniq }.from([0]).to([1])
    end

    it 'is idempotent' do
      perform

      expect { migration.perform }
        .to not_change { pipelines_table.where(project_id: project1.id).order(:id).pluck(:id, :iid) }
        .and not_change { project1_internal_id.last_value }
    end

    context 'when the existing internal_ids record is ahead of the max iid' do
      before do
        project1_internal_id.update!(last_value: 20)
      end

      it 'reserves from last_value, trusting it like InternalId.generate' do
        ids_to_deduplicate = pipelines_table.where(project_id: project1.id, iid: [3, 4]).pluck(:id)
        to_deduplicate = pipelines_table.where(id: ids_to_deduplicate)

        expect { perform }
          .to change { to_deduplicate.pluck(:iid).sort }.from([3, 3, 3, 4, 4]).to([21, 22, 23, 24, 25])
          .and change { project1_internal_id.last_value }.from(20).to(25)
      end
    end

    context 'when last_value is stale and a reserved iid would collide' do
      before do
        # last_value behind the real max iid (6), so the first reservation hands back iids that
        # already exist and the uniqueness trigger raises.
        project1_internal_id.update!(last_value: 2)
      end

      it 'flushes the internal_ids record and retries, re-seeding from the current max iid' do
        expect { perform }.not_to raise_error
        expect(project1_internal_id.last_value).to eq(11)
      end

      it_behaves_like 'deduplicates pipeline iids'

      context 'when retries are exhausted' do
        before do
          stub_const("#{described_class}::MAX_RETRIES", 0)
        end

        it 'raises the error' do
          expect { perform }.to raise_error(ActiveRecord::RecordNotUnique)
        end
      end
    end

    context 'when the project has no internal_ids record yet' do
      before do
        internal_ids_table.where(project_id: project1.id, usage: usage_value).delete_all
      end

      it 'creates the record seeded above the current maximum' do
        perform

        expect(project1_internal_id.last_value).to eq(11)
      end

      it_behaves_like 'deduplicates pipeline iids'
    end

    context 'when batching through a partition that spans multiple partition_ids' do
      let(:partition_ids) { [200, 201, 202] }

      it 'deduplicates iids that repeat within the spanned partition_ids' do
        ids_to_deduplicate = pipelines_table.where(project_id: project1.id, iid: 2).pluck(:id)
        to_deduplicate = pipelines_table.where(id: ids_to_deduplicate)
        others = pipelines_table.where.not(id: ids_to_deduplicate)

        expect { perform }
          .to change { to_deduplicate.pluck(:iid).sort }.from([2, 2, 2]).to([7, 8, 9])
          .and not_change { others.order(:id).map(&:attributes) }
      end
    end

    context 'when multiple projects have duplicates in the batch' do
      before do
        # Give project2 a duplicate too: iid=3 in partition 203 collides with its iid=3 in 202.
        connection.transaction do
          connection.execute(<<~SQL)
            ALTER TABLE p_ci_pipelines DISABLE TRIGGER trigger_ensure_pipeline_iid_uniqueness_before_insert;
            ALTER TABLE p_ci_pipelines DISABLE TRIGGER trigger_ensure_pipeline_iid_uniqueness_before_update_iid;
            ALTER TABLE p_ci_pipelines DISABLE TRIGGER trigger_cleanup_pipeline_iid_after_delete;
          SQL

          pipelines_table.create!(project_id: project2.id, partition_id: 203, iid: 3)

          connection.execute(<<~SQL)
            ALTER TABLE p_ci_pipelines ENABLE TRIGGER trigger_ensure_pipeline_iid_uniqueness_before_insert;
            ALTER TABLE p_ci_pipelines ENABLE TRIGGER trigger_ensure_pipeline_iid_uniqueness_before_update_iid;
            ALTER TABLE p_ci_pipelines ENABLE TRIGGER trigger_cleanup_pipeline_iid_after_delete;
          SQL
        end
      end

      it 'deduplicates each project independently using its own internal_ids record' do
        project2_dup_ids = pipelines_table.where(project_id: project2.id, iid: 3).pluck(:id)
        project2_dupes = pipelines_table.where(id: project2_dup_ids)

        expect { perform }
          .to change { project1_internal_id.last_value }.from(6).to(11)
          .and change { project2_internal_id.last_value }.from(5).to(7)
          .and change { project2_dupes.pluck(:iid).sort }.from([3, 3]).to([6, 7])
      end
    end

    private

    def project1_internal_id
      internal_ids_table.where(project_id: project1.id, usage: usage_value).first
    end

    def project2_internal_id
      internal_ids_table.where(project_id: project2.id, usage: usage_value).first
    end
  end
end
