# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::RebuildMaterializedViewService, :click_house, feature_category: :database do
  include ClickHouseHelpers

  let_it_be(:event1) { create(:event, :pushed) }
  let_it_be(:event2) { create(:event, :pushed) }
  let_it_be(:event3) { create(:closed_issue_event) }

  let(:connection) { ClickHouse::Connection.new(:main) }
  let(:runtime_limiter) { Gitlab::Metrics::RuntimeLimiter.new }

  let(:state) do
    {
      view_name: 'contributions_mv',
      view_table_name: 'contributions',
      tmp_view_name: 'tmp_contributions_mv',
      tmp_view_table_name: 'tmp_contributions',
      source_table_name: 'events'
    }
  end

  subject(:service_response) { run_service }

  def run_service(new_state = state)
    described_class.new(
      connection: connection,
      runtime_limiter: runtime_limiter,
      state: new_state
    ).execute
  end

  before do
    insert_events_into_click_house
  end

  it 're-creates the materialized view with correct data from the source table' do
    stub_const("#{described_class}::INSERT_BATCH_SIZE", 1)
    # Delete two records from the contributions MV to create so we have inconsistency
    connection.execute("DELETE FROM contributions WHERE id IN (#{event2.id}, #{event3.id})")

    # The current MV should have one record left
    ids = connection.select('SELECT id FROM contributions FINAL').pluck('id')
    expect(ids).to eq([event1.id])

    # Rebuild the MV so we get the inconsistency corrected
    expect(service_response).to be_success
    payload = service_response.payload
    expect(payload[:status]).to eq(:finished)

    ids = connection.select('SELECT id FROM contributions FINAL').pluck('id')
    expect(ids).to match_array([event1.id, event2.id, event3.id])
  end

  it 'does not leave temporary tables around' do
    expect(service_response).to be_success

    view_query = <<~SQL
      SELECT view_definition FROM information_schema.views
      WHERE table_name = 'tmp_contributions_mv' AND
      table_schema = '#{connection.database_name}'
    SQL

    table_query = <<~SQL
      SELECT table_name FROM information_schema.tables
      WHERE table_name = 'tmp_contributions' AND
      table_schema = '#{connection.database_name}'
    SQL

    expect(connection.select(view_query)).to be_empty
    expect(connection.select(table_query)).to be_empty
  end

  context 'when the rebuild_mv_drop_old_tables FF is off' do
    it 'preserves the old tables' do
      stub_feature_flags(rebuild_mv_drop_old_tables: false)
      expect(service_response).to be_success

      view_query = <<~SQL
        SELECT view_definition FROM information_schema.views
        WHERE table_name = 'tmp_contributions_mv' AND
        table_schema = '#{connection.database_name}'
      SQL

      table_query = <<~SQL
        SELECT table_name FROM information_schema.tables
        WHERE table_name = 'tmp_contributions' AND
        table_schema = '#{connection.database_name}'
      SQL

      expect(connection.select(view_query)).not_to be_empty
      expect(connection.select(table_query)).not_to be_empty
    end
  end

  context 'when the processing is stopped due to over time' do
    before do
      stub_const("#{described_class}::INSERT_BATCH_SIZE", 1)
    end

    it 'returns time_limit status and the cursor' do
      allow(runtime_limiter).to receive(:over_time?).and_return(true)
      expect(service_response).to be_success

      payload = service_response.payload
      expect(payload[:status]).to eq(:over_time)
      expect(payload[:next_value]).to eq(event1.id + 1)
    end

    context 'when the service is invoked three times' do
      it 'finishes the processing' do
        allow(runtime_limiter).to receive(:over_time?).and_return(true)

        service_response = run_service
        expect(service_response.payload[:status]).to eq(:over_time)

        service_response = run_service(state.merge(next_value: service_response.payload[:next_value]))
        expect(service_response.payload[:status]).to eq(:over_time)

        service_response = run_service(state.merge(next_value: service_response.payload[:next_value]))
        expect(service_response.payload[:status]).to eq(:over_time)

        service_response = run_service(state.merge(next_value: service_response.payload[:next_value]))
        expect(service_response.payload[:status]).to eq(:finished)
      end
    end
  end
end
