# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapColumnsForPCiBuildsRunnerId, feature_category: :continuous_integration do
  it_behaves_like(
    'swap conversion columns',
    table_name: :p_ci_builds,
    from: :runner_id,
    to: :runner_id_convert_to_bigint,
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
        DROP INDEX IF EXISTS p_ci_builds_runner_id_id_convert_to_bigint_idx;
        DROP INDEX IF EXISTS p_ci_builds_runner_id_id_idx;
      SQL

      migration_connection.add_concurrent_partitioned_index(
        :p_ci_builds,
        [:runner_id, :id],
        name: :p_ci_builds_runner_id_id_convert_to_bigint_idx
      )
    end

    it_behaves_like(
      'swap conversion columns',
      table_name: :p_ci_builds,
      from: :runner_id,
      to: :runner_id_convert_to_bigint,
      before_type: 'integer',
      after_type: 'bigint'
    )
  end
end
