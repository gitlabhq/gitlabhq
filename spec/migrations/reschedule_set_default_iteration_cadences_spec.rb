# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RescheduleSetDefaultIterationCadences do
  let(:namespaces) { table(:namespaces) }
  let(:iterations) { table(:sprints) }

  let(:group_1) { namespaces.create!(name: 'test_1', path: 'test_1') }
  let!(:group_2) { namespaces.create!(name: 'test_2', path: 'test_2') }
  let(:group_3) { namespaces.create!(name: 'test_3', path: 'test_3') }
  let(:group_4) { namespaces.create!(name: 'test_4', path: 'test_4') }
  let(:group_5) { namespaces.create!(name: 'test_5', path: 'test_5') }
  let(:group_6) { namespaces.create!(name: 'test_6', path: 'test_6') }
  let(:group_7) { namespaces.create!(name: 'test_7', path: 'test_7') }
  let(:group_8) { namespaces.create!(name: 'test_8', path: 'test_8') }

  let!(:iteration_1) { iterations.create!(iid: 1, title: 'iteration 1', group_id: group_1.id, start_date: 2.days.from_now, due_date: 3.days.from_now) }
  let!(:iteration_2) { iterations.create!(iid: 1, title: 'iteration 2', group_id: group_3.id, start_date: 2.days.from_now, due_date: 3.days.from_now) }
  let!(:iteration_3) { iterations.create!(iid: 1, title: 'iteration 2', group_id: group_4.id, start_date: 2.days.from_now, due_date: 3.days.from_now) }
  let!(:iteration_4) { iterations.create!(iid: 1, title: 'iteration 2', group_id: group_5.id, start_date: 2.days.from_now, due_date: 3.days.from_now) }
  let!(:iteration_5) { iterations.create!(iid: 1, title: 'iteration 2', group_id: group_6.id, start_date: 2.days.from_now, due_date: 3.days.from_now) }
  let!(:iteration_6) { iterations.create!(iid: 1, title: 'iteration 2', group_id: group_7.id, start_date: 2.days.from_now, due_date: 3.days.from_now) }
  let!(:iteration_7) { iterations.create!(iid: 1, title: 'iteration 2', group_id: group_8.id, start_date: 2.days.from_now, due_date: 3.days.from_now) }

  around do |example|
    freeze_time { Sidekiq::Testing.fake! { example.run } }
  end

  it 'schedules the background jobs', :aggregate_failures do
    stub_const("#{described_class.name}::BATCH_SIZE", 3)

    migrate!

    expect(BackgroundMigrationWorker.jobs.size).to be(3)
    expect(described_class::MIGRATION_CLASS).to be_scheduled_delayed_migration(2.minutes, group_1.id, group_3.id, group_4.id)
    expect(described_class::MIGRATION_CLASS).to be_scheduled_delayed_migration(4.minutes, group_5.id, group_6.id, group_7.id)
    expect(described_class::MIGRATION_CLASS).to be_scheduled_delayed_migration(6.minutes, group_8.id)
  end
end
