# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillSnippetRepositories do
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

    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(3.minutes, 1, 2)

        expect(described_class::MIGRATION)
          .to be_scheduled_delayed_migration(6.minutes, 3, 3)

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
