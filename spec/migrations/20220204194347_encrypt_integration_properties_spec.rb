# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe EncryptIntegrationProperties, :migration, schema: 20220204193000, feature_category: :integrations do
  subject(:migration) { described_class.new }

  let(:integrations) { table(:integrations) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
  end

  it 'correctly schedules background migrations', :aggregate_failures do
    # update required
    record1 = integrations.create!(properties: some_props)
    record2 = integrations.create!(properties: some_props)
    record3 = integrations.create!(properties: some_props)
    record4 = integrations.create!(properties: nil)
    record5 = integrations.create!(properties: nil)

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_migration(record1.id, record2.id)
        expect(described_class::MIGRATION).to be_scheduled_migration(record3.id, record4.id)
        expect(described_class::MIGRATION).to be_scheduled_migration(record5.id, record5.id)

        expect(BackgroundMigrationWorker.jobs.size).to eq(3)
      end
    end
  end

  def some_props
    { iid: generate(:iid), url: generate(:url), username: generate(:username) }.to_json
  end
end
