# frozen_string_literal: true

require 'spec_helper'
require_migration!('remove_duplicate_services2')

RSpec.describe RemoveDuplicateServices2 do
  let_it_be(:namespaces) { table(:namespaces) }
  let_it_be(:projects) { table(:projects) }
  let_it_be(:services) { table(:services) }

  describe '#up' do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 2)

      namespaces.create!(id: 1, name: 'group', path: 'group')

      projects.create!(id: 1, namespace_id: 1) # duplicate services
      projects.create!(id: 2, namespace_id: 1) # normal services
      projects.create!(id: 3, namespace_id: 1) # no services
      projects.create!(id: 4, namespace_id: 1) # duplicate services
      projects.create!(id: 5, namespace_id: 1) # duplicate services

      services.create!(id: 1, project_id: 1, type: 'JiraService')
      services.create!(id: 2, project_id: 1, type: 'JiraService')
      services.create!(id: 3, project_id: 2, type: 'JiraService')
      services.create!(id: 4, project_id: 4, type: 'AsanaService')
      services.create!(id: 5, project_id: 4, type: 'AsanaService')
      services.create!(id: 6, project_id: 4, type: 'JiraService')
      services.create!(id: 7, project_id: 4, type: 'JiraService')
      services.create!(id: 8, project_id: 4, type: 'SlackService')
      services.create!(id: 9, project_id: 4, type: 'SlackService')
      services.create!(id: 10, project_id: 5, type: 'JiraService')
      services.create!(id: 11, project_id: 5, type: 'JiraService')

      # Services without a project_id should be ignored
      services.create!(id: 12, type: 'JiraService')
      services.create!(id: 13, type: 'JiraService')
    end

    it 'schedules background jobs for all projects with duplicate services' do
      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, 1, 4)
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, 5)
        end
      end
    end
  end
end
