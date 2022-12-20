# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe ConsumeRemainingEncryptIntegrationPropertyJobs, :migration, feature_category: :integrations do
  subject(:migration) { described_class.new }

  let(:integrations) { table(:integrations) }
  let(:bg_migration_class) { ::Gitlab::BackgroundMigration::EncryptIntegrationProperties }
  let(:bg_migration) { instance_double(bg_migration_class) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
  end

  it 'performs remaining background migrations', :aggregate_failures do
    # Already migrated
    integrations.create!(properties: some_props, encrypted_properties: 'abc')
    integrations.create!(properties: some_props, encrypted_properties: 'def')
    integrations.create!(properties: some_props, encrypted_properties: 'xyz')
    # update required
    record1 = integrations.create!(properties: some_props)
    record2 = integrations.create!(properties: some_props)
    record3 = integrations.create!(properties: some_props)
    # No update required
    integrations.create!(properties: nil)
    integrations.create!(properties: nil)

    expect(Gitlab::BackgroundMigration).to receive(:steal).with(bg_migration_class.name.demodulize)
    expect(bg_migration_class).to receive(:new).twice.and_return(bg_migration)
    expect(bg_migration).to receive(:perform).with(record1.id, record2.id)
    expect(bg_migration).to receive(:perform).with(record3.id, record3.id)

    migrate!
  end

  def some_props
    { iid: generate(:iid), url: generate(:url), username: generate(:username) }.to_json
  end
end
