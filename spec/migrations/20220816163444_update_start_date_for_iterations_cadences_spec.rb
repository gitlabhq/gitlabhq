# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe UpdateStartDateForIterationsCadences, :freeze_time, feature_category: :team_planning do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:sprints) { table(:sprints) }
  let(:iterations_cadences) { table(:iterations_cadences) }

  let!(:group1) { namespaces.create!(name: 'abc', path: 'abc') }
  let!(:group2) { namespaces.create!(name: 'def', path: 'def') }

  let(:first_upcoming_start_date) { Date.current + 2.weeks }
  let(:original_cadence_start_date) { Date.current - 1.week }

  # rubocop: disable Layout/LineLength
  let!(:auto_cadence1) { iterations_cadences.create!(start_date: original_cadence_start_date, group_id: group1.id, title: "ic") }
  let!(:auto_cadence2) { iterations_cadences.create!(start_date: original_cadence_start_date, group_id: group1.id, title: "ic") }
  let!(:auto_cadence3) { iterations_cadences.create!(start_date: nil, group_id: group2.id, title: "ic") }
  let!(:manual_cadence1) { iterations_cadences.create!(start_date: Date.current, group_id: group1.id, automatic: false, title: "ic") }
  let!(:manual_cadence2) { iterations_cadences.create!(start_date: Date.current, group_id: group2.id, automatic: false, title: "ic") }
  # rubocop: enable Layout/LineLength

  def cadence_params(cadence)
    { iterations_cadence_id: cadence.id, group_id: cadence.group_id }
  end

  before do
    # Past iteratioin
    sprints.create!(id: 1, iid: 1, **cadence_params(auto_cadence1),
      start_date: Date.current - 1.week, due_date: Date.current - 1.day)
    # Current iteraition
    sprints.create!(id: 3, iid: 5, **cadence_params(auto_cadence1),
      start_date: Date.current, due_date: Date.current + 1.week)
    # First upcoming iteration
    sprints.create!(id: 4, iid: 8, **cadence_params(auto_cadence1),
      start_date: first_upcoming_start_date, due_date: first_upcoming_start_date + 1.week)
    # Second upcoming iteration
    sprints.create!(id: 5, iid: 9, **cadence_params(auto_cadence1),
      start_date: first_upcoming_start_date + 2.weeks, due_date: first_upcoming_start_date + 3.weeks)

    sprints.create!(id: 6, iid: 1, **cadence_params(manual_cadence2),
      start_date: Date.current, due_date: Date.current + 1.week)
    sprints.create!(id: 7, iid: 5, **cadence_params(manual_cadence2),
      start_date: Date.current + 2.weeks, due_date: Date.current + 3.weeks)
  end

  describe '#up' do
    it "updates the start date of an automatic cadence to the start date of its first upcoming sprint record." do
      expect { migration.up }
        .to change { auto_cadence1.reload.start_date }.to(first_upcoming_start_date)
        .and not_change { auto_cadence2.reload.start_date } # the cadence doesn't have any upcoming iteration.
        .and not_change { auto_cadence3.reload.start_date } # the cadence is empty; it has no iterations.
        .and not_change { manual_cadence1.reload.start_date } # manual cadence don't need to be touched.
        .and not_change { manual_cadence2.reload.start_date } # manual cadence don't need to be touched.
    end
  end

  describe '#down' do
    it "updates the start date of an automatic cadence to the start date of its earliest sprint record." do
      migration.up

      expect { migration.down }
        .to change { auto_cadence1.reload.start_date }.to(original_cadence_start_date)
        .and not_change { auto_cadence2.reload.start_date } # the cadence is empty; it has no iterations.
        .and not_change { manual_cadence1.reload.start_date } # manual cadence don't need to be touched.
        .and not_change { manual_cadence2.reload.start_date } # manual cadence don't need to be touched.
    end
  end
end
