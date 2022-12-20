# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RemoveNotNullContraintOnTitleFromSprints, :migration, feature_category: :team_planning do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:sprints) { table(:sprints) }
  let(:iterations_cadences) { table(:iterations_cadences) }

  let!(:group) { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:cadence) { iterations_cadences.create!(group_id: group.id, title: "cadence 1") }
  let!(:iteration1) { sprints.create!(id: 1, title: 'a', group_id: group.id, iterations_cadence_id: cadence.id, start_date: Date.new(2021, 11, 1), due_date: Date.new(2021, 11, 5), iid: 1) }

  describe '#down' do
    it "removes null titles by setting them with ids" do
      migration.up

      iteration2 = sprints.create!(id: 2, title: nil, group_id: group.id, iterations_cadence_id: cadence.id, start_date: Date.new(2021, 12, 1), due_date: Date.new(2021, 12, 5), iid: 2)

      migration.down

      expect(iteration1.reload.title).to eq 'a'
      expect(iteration2.reload.title).to eq '2'
    end
  end
end
