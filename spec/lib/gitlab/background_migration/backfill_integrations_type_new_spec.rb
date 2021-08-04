# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIntegrationsTypeNew do
  let(:integrations) { table(:integrations) }
  let(:namespaced_integrations) { Gitlab::Integrations::StiType.namespaced_integrations }

  before do
    integrations.connection.execute 'ALTER TABLE integrations DISABLE TRIGGER "trigger_type_new_on_insert"'

    namespaced_integrations.each_with_index do |type, i|
      integrations.create!(id: i + 1, type: "#{type}Service")
    end
  ensure
    integrations.connection.execute 'ALTER TABLE integrations ENABLE TRIGGER "trigger_type_new_on_insert"'
  end

  it 'backfills `type_new` for the selected records' do
    described_class.new.perform(2, 10)

    expect(integrations.where(id: 2..10).pluck(:type, :type_new)).to contain_exactly(
      ['AssemblaService',           'Integrations::Assembla'],
      ['BambooService',             'Integrations::Bamboo'],
      ['BugzillaService',           'Integrations::Bugzilla'],
      ['BuildkiteService',          'Integrations::Buildkite'],
      ['CampfireService',           'Integrations::Campfire'],
      ['ConfluenceService',         'Integrations::Confluence'],
      ['CustomIssueTrackerService', 'Integrations::CustomIssueTracker'],
      ['DatadogService',            'Integrations::Datadog'],
      ['DiscordService',            'Integrations::Discord']
    )

    expect(integrations.where.not(id: 2..10)).to all(have_attributes(type_new: nil))
  end
end
