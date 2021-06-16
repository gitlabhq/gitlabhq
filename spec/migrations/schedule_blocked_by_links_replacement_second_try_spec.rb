# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleBlockedByLinksReplacementSecondTry do
  let(:namespace) { table(:namespaces).create!(name: 'gitlab', path: 'gitlab-org') }
  let(:project) { table(:projects).create!(namespace_id: namespace.id, name: 'gitlab') }
  let(:issue1) { table(:issues).create!(project_id: project.id, title: 'a') }
  let(:issue2) { table(:issues).create!(project_id: project.id, title: 'b') }
  let(:issue3) { table(:issues).create!(project_id: project.id, title: 'c') }
  let!(:issue_links) do
    [
      table(:issue_links).create!(source_id: issue1.id, target_id: issue2.id, link_type: 1),
      table(:issue_links).create!(source_id: issue2.id, target_id: issue1.id, link_type: 2),
      table(:issue_links).create!(source_id: issue1.id, target_id: issue3.id, link_type: 2)
    ]
  end

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)
  end

  it 'schedules jobs for blocked_by links' do
    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(
          2.minutes, issue_links[1].id, issue_links[1].id)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(
          4.minutes, issue_links[2].id, issue_links[2].id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
