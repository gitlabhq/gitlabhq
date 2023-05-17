# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe FixAutomaticIterationsCadencesStartDate, feature_category: :team_planning do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:sprints) { table(:sprints) }
  let(:iterations_cadences) { table(:iterations_cadences) }

  let!(:group1) { namespaces.create!(name: 'abc', path: 'abc') }
  let!(:group2) { namespaces.create!(name: 'def', path: 'def') }

  let(:jan2022) { Date.new(2022, 1, 1) }
  let(:feb2022) { Date.new(2022, 2, 1) }
  let(:may2022) { Date.new(2022, 5, 1) }
  let(:dec2022) { Date.new(2022, 12, 1) }

  let!(:cadence1) { iterations_cadences.create!(start_date: jan2022, title: "ic 1", group_id: group1.id) }
  let!(:cadence2) { iterations_cadences.create!(start_date: may2022, group_id: group1.id, title: "ic 2") }
  let!(:cadence3) do
    iterations_cadences.create!(start_date: jan2022, automatic: false, group_id: group2.id, title: "ic 3 (invalid)")
  end

  let!(:cadence4) { iterations_cadences.create!(start_date: jan2022, group_id: group2.id, title: "ic 4 (invalid)") }

  before do
    sprints.create!(id: 2, start_date: jan2022, due_date: jan2022 + 1.week, iterations_cadence_id: cadence1.id,
      group_id: group1.id, iid: 1)
    sprints.create!(id: 1, start_date: dec2022, due_date: dec2022 + 1.week, iterations_cadence_id: cadence1.id,
      group_id: group1.id, iid: 2)

    sprints.create!(id: 4, start_date: feb2022, due_date: feb2022 + 1.week, iterations_cadence_id: cadence3.id,
      group_id: group2.id, iid: 1)
    sprints.create!(id: 3, start_date: may2022, due_date: may2022 + 1.week, iterations_cadence_id: cadence3.id,
      group_id: group2.id, iid: 2)

    sprints.create!(id: 5, start_date: may2022, due_date: may2022 + 1.week, iterations_cadence_id: cadence4.id,
      group_id: group2.id, iid: 4)
    sprints.create!(id: 6, start_date: feb2022, due_date: feb2022 + 1.week, iterations_cadence_id: cadence4.id,
      group_id: group2.id, iid: 3)
  end

  describe '#up' do
    it "updates automatic iterations_cadence records to use start dates of their earliest sprint records" do
      migrate!

      # This cadence has a valid start date. Its start date should be left as it is
      expect(cadence1.reload.start_date).to eq jan2022

      # This cadence doesn't have an iteration. Its start date should be left as it is.
      expect(cadence2.reload.start_date).to eq may2022

      # This cadence has an invalid start date but it isn't automatic. Its start date should be left as it is.
      expect(cadence3.reload.start_date).to eq jan2022

      # This cadence has an invalid start date. Its start date should be fixed.
      expect(cadence4.reload.start_date).to eq feb2022
    end
  end
end
