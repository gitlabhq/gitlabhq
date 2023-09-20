# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::RecordSyncContext, feature_category: :value_stream_management do
  let(:records) { [Issue.new(id: 1), Issue.new(id: 2), Issue.new(id: 3), Issue.new(id: 4)] }

  subject(:sync_context) { described_class.new(last_record_id: 0, max_records_per_batch: 3) }

  it 'allows processing 3 records per batch' do
    records.take(3).each do |record|
      sync_context.last_processed_id = record.id
    end

    expect(sync_context).to be_record_limit_reached
    expect(sync_context.last_processed_id).to eq(3)

    expect { sync_context.new_batch! }.to change { sync_context.record_count_in_current_batch }.from(3).to(0)

    expect(sync_context).not_to be_record_limit_reached

    records.take(3).each do |record|
      sync_context.last_processed_id = record.id
    end

    expect(sync_context).to be_record_limit_reached
  end

  it 'sets the no more records flag' do
    expect { sync_context.no_more_records! }.to change { sync_context.no_more_records? }.from(false).to(true)
  end
end
