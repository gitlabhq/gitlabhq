# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe UpdateHistoricalDataRecordedAt do
  let(:historical_data_table) { table(:historical_data) }

  it 'reversibly populates recorded_at from created_at or date' do
    row1 = historical_data_table.create!(
      date: Date.current - 1.day,
      created_at: Time.current - 1.day
    )

    row2 = historical_data_table.create!(date: Date.current - 2.days)
    row2.update!(created_at: nil)

    reversible_migration do |migration|
      migration.before -> {
        expect(row1.reload.recorded_at).to eq(nil)
        expect(row2.reload.recorded_at).to eq(nil)
      }

      migration.after -> {
        expect(row1.reload.recorded_at).to eq(row1.created_at)
        expect(row2.reload.recorded_at).to eq(row2.date.in_time_zone(Time.zone).change(hour: 12))
      }
    end
  end
end
