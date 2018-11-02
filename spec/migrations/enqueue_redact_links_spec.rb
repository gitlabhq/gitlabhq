require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20181014121030_enqueue_redact_links.rb')

describe EnqueueRedactLinks, :migration, :sidekiq do
  let(:merge_requests) { table(:merge_requests) }
  let(:issues) { table(:issues) }
  let(:notes) { table(:notes) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:snippets) { table(:snippets) }
  let(:users) { table(:users) }
  let(:user) { users.create!(email: 'test@example.com', projects_limit: 100, username: 'test') }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)

    text = 'some text /sent_notifications/00000000000000000000000000000000/unsubscribe more text'
    group = namespaces.create!(name: 'gitlab', path: 'gitlab')
    project = projects.create!(namespace_id: group.id)

    merge_requests.create!(id: 1, target_project_id: project.id, source_project_id: project.id, target_branch: 'feature', source_branch: 'master', description: text)
    issues.create!(id: 1, description: text)
    notes.create!(id: 1, note: text)
    notes.create!(id: 2, note: text)
    snippets.create!(id: 1, description: text, author_id: user.id)
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(5.minutes, "Note", "note", 1, 1)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(10.minutes, "Note", "note", 2, 2)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(5.minutes, "Issue", "description", 1, 1)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(5.minutes, "MergeRequest", "description", 1, 1)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(5.minutes, "Snippet", "description", 1, 1)
        expect(BackgroundMigrationWorker.jobs.size).to eq 5
      end
    end
  end
end
