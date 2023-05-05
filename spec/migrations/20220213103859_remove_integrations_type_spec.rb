# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RemoveIntegrationsType, :migration, feature_category: :integrations do
  subject(:migration) { described_class.new }

  let(:integrations) { table(:integrations) }
  let(:bg_migration) { instance_double(bg_migration_class) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
  end

  it 'performs remaining background migrations', :aggregate_failures do
    # Already migrated
    integrations.create!(type: 'SlackService', type_new: 'Integrations::Slack')
    # update required
    record1 = integrations.create!(type: 'SlackService')
    record2 = integrations.create!(type: 'JiraService')
    record3 = integrations.create!(type: 'SlackService')

    migrate!

    expect(record1.reload.type_new).to eq 'Integrations::Slack'
    expect(record2.reload.type_new).to eq 'Integrations::Jira'
    expect(record3.reload.type_new).to eq 'Integrations::Slack'
  end
end
