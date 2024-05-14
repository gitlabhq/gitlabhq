# frozen_string_literal: true

RSpec.shared_examples 'desired sharding key backfill job' do
  let!(:connection) { table(batch_table).connection }
  let!(:starting_id) { table(batch_table).pluck(:id).min }
  let!(:end_id) { table(batch_table).pluck(:id).max }

  let!(:migration) do
    described_class.new(
      start_id: starting_id,
      end_id: end_id,
      batch_table: batch_table,
      batch_column: :id,
      sub_batch_size: 10,
      pause_ms: 2,
      connection: connection,
      job_arguments: [
        backfill_column,
        backfill_via_table,
        backfill_via_column,
        backfill_via_foreign_key
      ]
    )
  end

  it 'performs without error' do
    expect { migration.perform }.not_to raise_error
  end

  it 'constructs a valid query' do
    query = migration.construct_query(sub_batch: table(batch_table).all)

    expect { connection.execute(query) }.not_to raise_error
  end
end
