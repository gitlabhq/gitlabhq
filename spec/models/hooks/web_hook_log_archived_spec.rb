# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHookLogArchived do
  let(:source_table) { WebHookLog }
  let(:destination_table) { described_class }

  it 'has the same columns as the source table' do
    column_names_from_source_table = column_names(source_table)
    column_names_from_destination_table = column_names(destination_table)

    expect(column_names_from_destination_table).to match_array(column_names_from_source_table)
  end

  it 'has the same null constraints as the source table' do
    constraints_from_source_table = null_constraints(source_table)
    constraints_from_destination_table = null_constraints(destination_table)

    expect(constraints_from_destination_table.to_a).to match_array(constraints_from_source_table.to_a)
  end

  it 'inserts the same record as the one in the source table', :aggregate_failures do
    expect { create(:web_hook_log) }.to change { destination_table.count }.by(1)

    event_from_source_table = source_table.connection.select_one(
      "SELECT * FROM #{source_table.table_name} ORDER BY created_at desc LIMIT 1"
    )
    event_from_destination_table = destination_table.connection.select_one(
      "SELECT * FROM #{destination_table.table_name} ORDER BY created_at desc LIMIT 1"
    )

    expect(event_from_destination_table).to eq(event_from_source_table)
  end

  def column_names(table)
    table.connection.select_all(<<~SQL)
      SELECT c.column_name
      FROM information_schema.columns c
      WHERE c.table_name = '#{table.table_name}'
    SQL
  end

  def null_constraints(table)
    table.connection.select_all(<<~SQL)
      SELECT c.column_name, c.is_nullable
      FROM information_schema.columns c
      WHERE c.table_name = '#{table.table_name}'
      AND c.column_name != 'created_at'
    SQL
  end
end
