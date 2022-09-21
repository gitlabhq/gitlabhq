# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIntegrationsTypeNew, :migration, schema: 20220212120735 do
  let(:migration) { described_class.new }
  let(:integrations) { table(:integrations) }

  let(:namespaced_integrations) do
    Set.new(
      %w[
        Asana Assembla Bamboo Bugzilla Buildkite Campfire Confluence CustomIssueTracker Datadog
        Discord DroneCi EmailsOnPush Ewm ExternalWiki Flowdock HangoutsChat Harbor Irker Jenkins Jira Mattermost
        MattermostSlashCommands MicrosoftTeams MockCi MockMonitoring Packagist PipelinesEmail Pivotaltracker
        Prometheus Pushover Redmine Shimo Slack SlackSlashCommands Teamcity UnifyCircuit WebexTeams Youtrack Zentao
        Github GitlabSlackApplication
      ]).freeze
  end

  before do
    integrations.connection.execute 'ALTER TABLE integrations DISABLE TRIGGER "trigger_type_new_on_insert"'

    namespaced_integrations.each_with_index do |type, i|
      integrations.create!(id: i + 1, type: "#{type}Service")
    end

    integrations.create!(id: namespaced_integrations.size + 1, type: 'LegacyService')
  ensure
    integrations.connection.execute 'ALTER TABLE integrations ENABLE TRIGGER "trigger_type_new_on_insert"'
  end

  it 'backfills `type_new` for the selected records' do
    # We don't want to mock `Kernel.sleep`, so instead we mock it on the migration
    # class before it gets forwarded.
    expect(migration).to receive(:sleep).with(0.05).exactly(5).times

    queries = ActiveRecord::QueryRecorder.new do
      migration.perform(2, 10, :integrations, :id, 2, 50)
    end

    expect(queries.count).to be(16)
    expect(queries.log.grep(/^SELECT/).size).to be(11)
    expect(queries.log.grep(/^UPDATE/).size).to be(5)
    expect(queries.log.grep(/^UPDATE/).join.scan(/WHERE .*/)).to eq(
      [
        'WHERE integrations.id BETWEEN 2 AND 3',
        'WHERE integrations.id BETWEEN 4 AND 5',
        'WHERE integrations.id BETWEEN 6 AND 7',
        'WHERE integrations.id BETWEEN 8 AND 9',
        'WHERE integrations.id BETWEEN 10 AND 10'
      ])

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
