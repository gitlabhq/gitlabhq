# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapColumnsForUpstreamPipelineIdBetweenCiBuildsAndCiPipelines, feature_category: :continuous_integration do
  it_behaves_like(
    'swap conversion columns',
    table_name: :p_ci_builds,
    from: :upstream_pipeline_id,
    to: :upstream_pipeline_id_convert_to_bigint,
    before_type: 'integer',
    after_type: 'bigint'
  )

  it_behaves_like(
    'swap conversion columns',
    table_name: :p_ci_builds,
    from: :commit_id,
    to: :commit_id_convert_to_bigint,
    before_type: 'integer',
    after_type: 'bigint'
  )

  context 'when index is different' do
    let(:migration_connection) do
      klass = Class.new(Gitlab::Database::Migration[2.2]) { milestone '16.11' }
      klass.new.tap do |migration|
        migration.extend Gitlab::Database::PartitioningMigrationHelpers
      end
    end

    before do
      migration_connection.execute(<<~SQL)
        DROP INDEX IF EXISTS p_ci_builds_commit_id_artifacts_expire_at_id_convert_to_big_idx;
        DROP INDEX IF EXISTS p_ci_builds_commit_id_artifacts_expire_at_id_idx;
      SQL

      migration_connection.add_concurrent_partitioned_index(
        :p_ci_builds,
        [:commit_id, :artifacts_expire_at, :id],
        name: :p_ci_builds_commit_id_artifacts_expire_at_id_convert_to_big_idx,
        where: "(((type)::text = 'Ci::Build'::text) AND ((retried = false) OR (retried IS NULL)) AND ((name)::text = ANY (ARRAY[('sast'::character varying)::text, ('secret_detection'::character varying)::text, ('dependency_scanning'::character varying)::text, ('container_scanning'::character varying)::text, ('dast'::character varying)::text])))"
      )
    end

    it_behaves_like(
      'swap conversion columns',
      table_name: :p_ci_builds,
      from: :upstream_pipeline_id,
      to: :upstream_pipeline_id_convert_to_bigint,
      before_type: 'integer',
      after_type: 'bigint'
    )

    it_behaves_like(
      'swap conversion columns',
      table_name: :p_ci_builds,
      from: :commit_id,
      to: :commit_id_convert_to_bigint,
      before_type: 'integer',
      after_type: 'bigint'
    )
  end
end
