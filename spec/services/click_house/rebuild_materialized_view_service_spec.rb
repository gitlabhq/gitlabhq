# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::RebuildMaterializedViewService, :click_house, feature_category: :database do
  include ClickHouseHelpers

  let_it_be(:event1) { create(:event, :pushed) }
  let_it_be(:event2) { create(:event, :pushed) }
  let_it_be(:event3) { create(:closed_issue_event) }

  let(:connection) { ClickHouse::Connection.new(:main) }

  before do
    insert_events_into_click_house
  end

  def invoke_service
    described_class.new(connection: connection, state: {
      view_name: 'contributions_mv',
      view_table_name: 'contributions',
      tmp_view_name: 'tmp_contributions_mv',
      tmp_view_table_name: 'tmp_contributions',
      source_table_name: 'events'
    }).execute
  end

  it 're-creates the materialized view with correct data from the source table' do
    stub_const("#{described_class}::INSERT_BATCH_SIZE", 1)
    # Delete two records from the contributions MV to create so we have inconsistency
    connection.execute("DELETE FROM contributions WHERE id IN (#{event2.id}, #{event3.id})")

    # The current MV should have one record left
    ids = connection.select('SELECT id FROM contributions FINAL').pluck('id')
    expect(ids).to eq([event1.id])

    # Rebuild the MV so we get the inconsistency corrected
    invoke_service

    ids = connection.select('SELECT id FROM contributions FINAL').pluck('id')
    expect(ids).to match_array([event1.id, event2.id, event3.id])
  end

  it 'does not leave temporary tables around' do
    invoke_service

    view_query = <<~SQL
      SELECT view_definition FROM information_schema.views
      WHERE table_name = 'tmp_contributions_mv' AND
      table_schema = '#{connection.database_name}'
    SQL

    table_query = <<~SQL
      SELECT view_definition FROM information_schema.tables
      WHERE table_name = 'tmp_contributions' AND
      table_schema = '#{connection.database_name}'
    SQL

    expect(connection.select(view_query)).to be_empty
    expect(connection.select(table_query)).to be_empty
  end
end
