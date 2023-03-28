# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateShimoConfluenceServiceCategory, :migration, feature_category: :integrations do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:integrations) { table(:integrations) }

  before do
    namespace = namespaces.create!(name: 'test', path: 'test')
    projects.create!(id: 1, namespace_id: namespace.id, name: 'gitlab', path: 'gitlab')
    integrations.create!(
      id: 1, active: true, type_new: "Integrations::SlackSlashCommands", category: 'chat', project_id: 1
    )
    integrations.create!(id: 3, active: true, type_new: "Integrations::Confluence", category: 'common', project_id: 1)
    integrations.create!(id: 5, active: true, type_new: "Integrations::Shimo", category: 'common', project_id: 1)
  end

  describe '#up' do
    it 'correctly schedules background migrations', :aggregate_failures do
      stub_const("#{described_class.name}::BATCH_SIZE", 2)

      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(described_class::MIGRATION).to be_scheduled_migration(3, 5)
          expect(BackgroundMigrationWorker.jobs.size).to eq(1)
        end
      end
    end
  end
end
