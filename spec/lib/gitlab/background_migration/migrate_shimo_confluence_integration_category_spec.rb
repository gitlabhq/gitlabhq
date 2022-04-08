# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateShimoConfluenceIntegrationCategory, schema: 20220326161803 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:integrations) { table(:integrations) }
  let(:perform) { described_class.new.perform(1, 5) }

  before do
    namespace = namespaces.create!(name: 'test', path: 'test')
    projects.create!(id: 1, namespace_id: namespace.id, name: 'gitlab', path: 'gitlab')
    integrations.create!(id: 1, active: true, type_new: "Integrations::SlackSlashCommands",
                         category: 'chat', project_id: 1)
    integrations.create!(id: 3, active: true, type_new: "Integrations::Confluence", category: 'common', project_id: 1)
    integrations.create!(id: 5, active: true, type_new: "Integrations::Shimo", category: 'common', project_id: 1)
  end

  describe '#up' do
    it 'updates category to third_party_wiki for Shimo and Confluence' do
      perform

      expect(integrations.where(category: 'third_party_wiki').count).to eq(2)
      expect(integrations.where(category: 'chat').count).to eq(1)
    end
  end
end
