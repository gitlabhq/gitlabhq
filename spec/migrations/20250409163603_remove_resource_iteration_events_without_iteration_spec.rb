# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveResourceIterationEventsWithoutIteration, migration: :gitlab_main, feature_category: :team_planning do
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { table(:namespaces).create!(name: "namespace", path: "namespace", organization_id: organization.id) }
  let(:resource_iteration_events) { table(:resource_iteration_events) }
  let(:user) { table(:users).create!(username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 2) }
  let(:iteration) do
    table(:sprints).create!(iid: 1, start_date: 1.day.from_now, due_date: 1.week.from_now, group_id: namespace.id)
  end

  let!(:valid_resource_events) do
    [
      resource_iteration_events.create!(iteration_id: iteration.id, user_id: user.id, action: 0, namespace_id: 0),
      resource_iteration_events.create!(iteration_id: iteration.id, user_id: user.id, action: 0, namespace_id: 0),
      resource_iteration_events.create!(iteration_id: iteration.id, user_id: user.id, action: 0, namespace_id: 0)
    ]
  end

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)
    4.times do
      resource_iteration_events.create!(user_id: user.id, action: 0, namespace_id: 0)
    end
  end

  describe '#up' do
    it 'deletes records in batches' do
      expect do
        migrate!
      end.to make_queries_matching(
        /DELETE FROM "resource_iteration_events" WHERE "resource_iteration_events"."iteration_id" IS NULL/,
        2
      )
    end

    it 'removes offending records' do
      expect { migrate! }.to change { resource_iteration_events.count }.from(7).to(3).and(
        change { resource_iteration_events.pluck(:id) }.to(match_array(valid_resource_events.pluck(:id)))
      )
    end
  end
end
