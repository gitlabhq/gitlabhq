# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveSprintsWithoutGroup, migration: :gitlab_main, feature_category: :team_planning do
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { table(:namespaces).create!(name: "namespace", path: "namespace", organization_id: organization.id) }
  let(:iterations) { table(:sprints) }

  let!(:valid_iterations) do
    [
      iterations.create!(iid: 1, start_date: 1.day.from_now, due_date: 1.week.from_now, group_id: namespace.id),
      iterations.create!(iid: 2, start_date: 1.day.from_now, due_date: 1.week.from_now, group_id: namespace.id),
      iterations.create!(iid: 3, start_date: 1.day.from_now, due_date: 1.week.from_now, group_id: namespace.id)
    ]
  end

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)
    4.times do
      iterations.create!(iid: 1, start_date: 1.day.from_now, due_date: 1.week.from_now)
    end
  end

  describe '#up' do
    it 'deletes records in batches' do
      expect do
        migrate!
      end.to make_queries_matching(
        /DELETE FROM "sprints" WHERE "sprints"."group_id" IS NULL/,
        2
      )
    end

    it 'removes offending records' do
      expect { migrate! }.to change { iterations.count }.from(7).to(3).and(
        change { iterations.pluck(:id) }.to(match_array(valid_iterations.pluck(:id)))
      )
    end
  end
end
