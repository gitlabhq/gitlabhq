# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe UpdateLastRunDateForIterationsCadences, :migration, feature_category: :team_planning do
  let(:current_date) { Date.parse(ApplicationRecord.connection.execute("SELECT CURRENT_DATE").first["current_date"]) }
  let(:namespaces) { table(:namespaces) }
  let(:iterations_cadences) { table(:iterations_cadences) }

  let!(:group) { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:cadence_1) do
    iterations_cadences.create!(group_id: group.id, title: "cadence 1", last_run_date: Date.today - 5.days)
  end

  let!(:cadence_2) { iterations_cadences.create!(group_id: group.id, title: "cadence 2", last_run_date: nil) }
  let!(:cadence_3) do
    iterations_cadences.create!(group_id: group.id, title: "cadence 2", last_run_date: nil, automatic: false)
  end

  it 'sets last_run_date to CURRENT_DATE for iterations cadences with automatic=true', :aggregate_failures do
    migrate!

    expect(cadence_1.reload.last_run_date).to eq(current_date)
    expect(cadence_2.reload.last_run_date).to eq(current_date)
    expect(cadence_3.reload.last_run_date).to eq(nil)
  end
end
