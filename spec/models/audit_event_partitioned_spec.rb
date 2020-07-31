# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEventPartitioned do
  let(:source_table) { AuditEvent }
  let(:partitioned_table) { described_class }

  it 'has the same columns as the source table' do
    expect(partitioned_table.column_names).to match_array(source_table.column_names)
  end

  it 'inserts the same record as the one in the source table', :aggregate_failures do
    expect { create(:audit_event) }.to change { partitioned_table.count }.by(1)

    event_from_source_table = source_table.connection.select_one(
      "SELECT * FROM #{source_table.table_name} ORDER BY created_at desc LIMIT 1"
    )
    event_from_partitioned_table = partitioned_table.connection.select_one(
      "SELECT * FROM #{partitioned_table.table_name} ORDER BY created_at desc LIMIT 1"
    )

    expect(event_from_partitioned_table).to eq(event_from_source_table)
  end
end
