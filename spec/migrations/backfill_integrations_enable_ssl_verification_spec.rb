# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillIntegrationsEnableSslVerification, feature_category: :system_access do
  let!(:migration) { described_class::MIGRATION }
  let!(:integrations) { described_class::Integration }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    integrations.create!(id: 1, type_new: 'Integrations::DroneCi')
    integrations.create!(id: 2, type_new: 'Integrations::DroneCi', properties: {})
    integrations.create!(id: 3, type_new: 'Integrations::Bamboo', properties: {})
    integrations.create!(id: 4, type_new: 'Integrations::Teamcity', properties: {})
    integrations.create!(id: 5, type_new: 'Integrations::DroneCi', properties: {})
    integrations.create!(id: 6, type_new: 'Integrations::Teamcity', properties: {})
  end

  describe '#up' do
    it 'schedules background jobs for each batch of integrations', :freeze_time do
      Sidekiq::Testing.fake! do
        migrate!

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        expect(migration).to be_scheduled_delayed_migration(5.minutes, 2, 4)
        expect(migration).to be_scheduled_delayed_migration(10.minutes, 5, 6)
      end
    end
  end
end
