# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe AddTriggersToIntegrationsTypeNew, feature_category: :purchase do
  let(:migration) { described_class.new }
  let(:integrations) { table(:integrations) }

  # This matches Gitlab::Integrations::StiType at the time the trigger was added
  let(:namespaced_integrations) do
    %w[
      Asana Assembla Bamboo Bugzilla Buildkite Campfire Confluence CustomIssueTracker Datadog
      Discord DroneCi EmailsOnPush Ewm ExternalWiki Flowdock HangoutsChat Irker Jenkins Jira Mattermost
      MattermostSlashCommands MicrosoftTeams MockCi MockMonitoring Packagist PipelinesEmail Pivotaltracker
      Prometheus Pushover Redmine Slack SlackSlashCommands Teamcity UnifyCircuit WebexTeams Youtrack

      Github GitlabSlackApplication
    ]
  end

  describe '#up' do
    before do
      migrate!
    end

    describe 'INSERT trigger' do
      it 'sets `type_new` to the transformed `type` class name' do
        namespaced_integrations.each do |type|
          integration = integrations.create!(type: "#{type}Service")

          expect(integration.reload).to have_attributes(
            type: "#{type}Service",
            type_new: "Integrations::#{type}"
          )
        end
      end

      it 'ignores types that are not namespaced' do
        # We don't actually have any integrations without namespaces,
        # but we can abuse one of the integration base classes.
        integration = integrations.create!(type: 'BaseIssueTracker')

        expect(integration.reload).to have_attributes(
          type: 'BaseIssueTracker',
          type_new: nil
        )
      end

      it 'ignores types that are unknown' do
        integration = integrations.create!(type: 'FooBar')

        expect(integration.reload).to have_attributes(
          type: 'FooBar',
          type_new: nil
        )
      end
    end
  end

  describe '#down' do
    before do
      migration.up
      migration.down
    end

    it 'drops the INSERT trigger' do
      integration = integrations.create!(type: 'JiraService')

      expect(integration.reload).to have_attributes(
        type: 'JiraService',
        type_new: nil
      )
    end
  end
end
