# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SchedulePopulateProjectSnippetStatistics do
  let(:users) { table(:users) }
  let(:snippets) { table(:snippets) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:user1) { users.create!(id: 1, email: 'user1@example.com', projects_limit: 10, username: 'test1', name: 'Test1', state: 'active') }
  let(:user2) { users.create!(id: 2, email: 'user2@example.com', projects_limit: 10, username: 'test2', name: 'Test2', state: 'active') }
  let(:namespace1) { namespaces.create!(id: 1, owner_id: user1.id, name: 'user1', path: 'user1') }
  let(:namespace2) { namespaces.create!(id: 2, owner_id: user2.id, name: 'user2', path: 'user2') }
  let(:project1) { projects.create!(id: 1, namespace_id: namespace1.id) }
  let(:project2) { projects.create!(id: 2, namespace_id: namespace1.id) }
  let(:project3) { projects.create!(id: 3, namespace_id: namespace2.id) }

  def create_snippet(id, user_id, project_id, type = 'ProjectSnippet')
    params = {
      id: id,
      type: type,
      author_id: user_id,
      project_id: project_id,
      file_name: 'foo',
      content: 'bar'
    }

    snippets.create!(params)
  end

  it 'correctly schedules background migrations' do
    # Creating the snippets in different order
    create_snippet(1, user1.id, project1.id)
    create_snippet(2, user2.id, project3.id)
    create_snippet(3, user1.id, project1.id)
    create_snippet(4, user1.id, project2.id)
    create_snippet(5, user2.id, project3.id)
    create_snippet(6, user1.id, project1.id)
    # Creating a personal snippet to ensure we don't pick it
    create_snippet(7, user1.id, nil, 'PersonalSnippet')

    stub_const("#{described_class}::BATCH_SIZE", 4)

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        aggregate_failures do
          expect(described_class::MIGRATION)
            .to be_scheduled_migration([1, 3, 6, 4])

          expect(described_class::MIGRATION)
            .to be_scheduled_delayed_migration(2.minutes, [2, 5])

          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end
end
