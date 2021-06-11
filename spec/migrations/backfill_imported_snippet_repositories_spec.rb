# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillImportedSnippetRepositories do
  let(:users) { table(:users) }
  let(:snippets) { table(:snippets) }
  let(:user) { users.create!(id: 1, email: 'user@example.com', projects_limit: 10, username: 'test', name: 'Test', state: 'active') }

  def create_snippet(id)
    params = {
      id: id,
      type: 'PersonalSnippet',
      author_id: user.id,
      file_name: 'foo',
      content: 'bar'
    }

    snippets.create!(params)
  end

  it 'correctly schedules background migrations' do
    create_snippet(1)
    create_snippet(2)
    create_snippet(3)
    create_snippet(5)
    create_snippet(7)
    create_snippet(8)
    create_snippet(10)

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(2.minutes, 1, 3)

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(4.minutes, 5, 5)

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(6.minutes, 7, 8)

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(8.minutes, 10, 10)

        expect(BackgroundMigrationWorker.jobs.size).to eq(4)
      end
    end
  end
end
