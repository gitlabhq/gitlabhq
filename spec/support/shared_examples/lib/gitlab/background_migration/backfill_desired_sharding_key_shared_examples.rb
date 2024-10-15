# frozen_string_literal: true

RSpec.shared_examples 'desired sharding key backfill job' do
  let(:batch_column) { :id }
  let!(:connection) { table(batch_table).connection }
  let!(:starting_id) { table(batch_table).pluck(batch_column).min }
  let!(:end_id) { table(batch_table).pluck(batch_column).max }
  let(:job_arguments) do
    args = [
      backfill_column,
      backfill_via_table,
      backfill_via_column,
      backfill_via_foreign_key
    ]
    args << partition_column if defined?(partition_column)
    args
  end

  let!(:migration) do
    described_class.new(
      start_id: starting_id,
      end_id: end_id,
      batch_table: batch_table,
      batch_column: batch_column,
      sub_batch_size: 10,
      pause_ms: 2,
      connection: connection,
      job_arguments: job_arguments
    )
  end

  it 'performs without error' do
    expect { migration.perform }.not_to raise_error
  end

  it 'constructs a valid query' do
    query = migration.construct_query(sub_batch: table(batch_table).all)

    if defined?(partition_column)
      expect(query).to include("AND #{backfill_via_table}.#{partition_column} = #{batch_table}.#{partition_column}")
    end

    expect { connection.execute(query) }.not_to raise_error
  end
end
