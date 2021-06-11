# frozen_string_literal: true

require 'spec_helper'
require_migration!('backfill_total_tuple_count_for_batched_migrations')

RSpec.describe BackfillTotalTupleCountForBatchedMigrations, :migration, schema: 20210406140057 do
  let_it_be(:table_name) { 'projects' }

  let_it_be(:migrations) { table(:batched_background_migrations) }

  let_it_be(:migration) do
    migrations.create!(
      created_at: Time.now,
      updated_at: Time.now,
      min_value: 1,
      max_value: 10_000,
      batch_size: 1_000,
      sub_batch_size: 100,
      interval: 120,
      status: 0,
      job_class_name: 'Foo',
      table_name: table_name,
      column_name: :id,
      total_tuple_count: nil
    )
  end

  describe '#up' do
    before do
      expect(Gitlab::Database::PgClass).to receive(:for_table).with(table_name).and_return(estimate)
    end

    let(:estimate) { double('estimate', cardinality_estimate: 42) }

    it 'updates total_tuple_count attribute' do
      migrate!

      migrations.all.each do |migration|
        expect(migration.total_tuple_count).to eq(estimate.cardinality_estimate)
      end
    end
  end
end
