# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200724130639_backfill_designs_relative_position.rb')

RSpec.describe BackfillDesignsRelativePosition do
  let(:namespace) { table(:namespaces).create!(name: 'gitlab', path: 'gitlab') }
  let(:project) { table(:projects).create!(namespace_id: namespace.id) }
  let(:issues) { table(:issues) }
  let(:designs) { table(:design_management_designs) }

  before do
    issues.create!(id: 1, project_id: project.id)
    issues.create!(id: 2, project_id: project.id)
    issues.create!(id: 3, project_id: project.id)
    issues.create!(id: 4, project_id: project.id)

    designs.create!(issue_id: 1, project_id: project.id, filename: 'design1.jpg')
    designs.create!(issue_id: 2, project_id: project.id, filename: 'design2.jpg')
    designs.create!(issue_id: 4, project_id: project.id, filename: 'design3.jpg')

    stub_const("#{described_class.name}::BATCH_SIZE", 2)
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(2.minutes, [1, 2])

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(4.minutes, [4])

        # Issue 3 should be skipped because it doesn't have any designs
        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
