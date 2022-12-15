# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillSequenceColumnForSprintsTable, :migration, schema: 20211126042235, feature_category: :team_planning do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:sprints) { table(:sprints) }
  let(:iterations_cadences) { table(:iterations_cadences) }

  let!(:group) { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:cadence_1) { iterations_cadences.create!(group_id: group.id, title: "cadence 1") }
  let!(:cadence_2) { iterations_cadences.create!(group_id: group.id, title: "cadence 2") }
  let!(:iteration_1) { sprints.create!(id: 1, group_id: group.id, iterations_cadence_id: cadence_1.id, start_date: Date.new(2021, 11, 1), due_date: Date.new(2021, 11, 5), iid: 1, title: 'a' ) }
  let!(:iteration_2) { sprints.create!(id: 2, group_id: group.id, iterations_cadence_id: cadence_1.id, start_date: Date.new(2021, 12, 1), due_date: Date.new(2021, 12, 5), iid: 2, title: 'b') }
  let!(:iteration_3) { sprints.create!(id: 3, group_id: group.id, iterations_cadence_id: cadence_2.id, start_date: Date.new(2021, 12, 1), due_date: Date.new(2021, 12, 5), iid: 4, title: 'd') }
  let!(:iteration_4) { sprints.create!(id: 4, group_id: group.id, iterations_cadence_id: nil, start_date: Date.new(2021, 11, 15), due_date: Date.new(2021, 11, 20), iid: 3, title: 'c') }

  describe '#up' do
    it "correctly sets the sequence attribute with idempotency" do
      migration.up

      expect(iteration_1.reload.sequence).to be 1
      expect(iteration_2.reload.sequence).to be 2
      expect(iteration_3.reload.sequence).to be 1
      expect(iteration_4.reload.sequence).to be nil

      iteration_5 = sprints.create!(id: 5, group_id: group.id, iterations_cadence_id: cadence_1.id, start_date: Date.new(2022, 1, 1), due_date: Date.new(2022, 1, 5), iid: 1, title: 'e' )

      migration.down
      migration.up

      expect(iteration_1.reload.sequence).to be 1
      expect(iteration_2.reload.sequence).to be 2
      expect(iteration_5.reload.sequence).to be 3
      expect(iteration_3.reload.sequence).to be 1
      expect(iteration_4.reload.sequence).to be nil
    end
  end
end
