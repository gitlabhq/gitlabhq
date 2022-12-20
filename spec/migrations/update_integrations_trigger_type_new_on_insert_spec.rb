# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe UpdateIntegrationsTriggerTypeNewOnInsert, feature_category: :integrations do
  let(:migration) { described_class.new }
  let(:integrations) { table(:integrations) }

  shared_examples 'transforms known types' do
    # This matches Gitlab::Integrations::StiType at the time the original trigger
    # was added in db/migrate/20210721135638_add_triggers_to_integrations_type_new.rb
    let(:namespaced_integrations) do
      %w[
        Asana Assembla Bamboo Bugzilla Buildkite Campfire Confluence CustomIssueTracker Datadog
        Discord DroneCi EmailsOnPush Ewm ExternalWiki Flowdock HangoutsChat Irker Jenkins Jira Mattermost
        MattermostSlashCommands MicrosoftTeams MockCi MockMonitoring Packagist PipelinesEmail Pivotaltracker
        Prometheus Pushover Redmine Slack SlackSlashCommands Teamcity UnifyCircuit WebexTeams Youtrack

        Github GitlabSlackApplication
      ]
    end

    it 'sets `type_new` to the transformed `type` class name' do
      namespaced_integrations.each do |type|
        integration = integrations.create!(type: "#{type}Service")

        expect(integration.reload).to have_attributes(
          type: "#{type}Service",
          type_new: "Integrations::#{type}"
        )
      end
    end
  end

  describe '#up' do
    before do
      migrate!
    end

    describe 'INSERT trigger with dynamic mapping' do
      it_behaves_like 'transforms known types'

      it 'transforms unknown types if it ends in "Service"' do
        integration = integrations.create!(type: 'AcmeService')

        expect(integration.reload).to have_attributes(
          type: 'AcmeService',
          type_new: 'Integrations::Acme'
        )
      end

      it 'ignores "Service" occurring elsewhere in the type' do
        integration = integrations.create!(type: 'ServiceAcmeService')

        expect(integration.reload).to have_attributes(
          type: 'ServiceAcmeService',
          type_new: 'Integrations::ServiceAcme'
        )
      end

      it 'copies unknown types if it does not end with "Service"' do
        integration = integrations.create!(type: 'Integrations::Acme')

        expect(integration.reload).to have_attributes(
          type: 'Integrations::Acme',
          type_new: 'Integrations::Acme'
        )
      end
    end
  end

  describe '#down' do
    before do
      migration.up
      migration.down
    end

    describe 'INSERT trigger with static mapping' do
      it_behaves_like 'transforms known types'

      it 'ignores types that are already namespaced' do
        integration = integrations.create!(type: 'Integrations::Asana')

        expect(integration.reload).to have_attributes(
          type: 'Integrations::Asana',
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
end
