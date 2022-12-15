# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateRoutingTableForBuildsMetadataV2, :migration, feature_category: :continuous_integration do
  let!(:migration) { described_class.new }

  describe '#up' do
    context 'when the table is already partitioned' do
      before do
        # `convert_table_to_first_list_partition` checks if it's being executed
        # inside a transaction, but we're using transactional fixtures here so we
        # need to tell it that it's not inside a transaction.
        # We toggle the behavior depending on how many transactions we have open
        # instead of just returning `false` because the migration could have the
        # DDL transaction enabled.
        #
        open_transactions = ActiveRecord::Base.connection.open_transactions
        allow(migration).to receive(:transaction_open?) do
          ActiveRecord::Base.connection.open_transactions > open_transactions
        end

        migration.convert_table_to_first_list_partition(
          table_name: :ci_builds_metadata,
          partitioning_column: :partition_id,
          parent_table_name: :p_ci_builds_metadata,
          initial_partitioning_value: 100)
      end

      it 'skips the migration' do
        expect { migrate! }.not_to raise_error
      end
    end
  end
end
