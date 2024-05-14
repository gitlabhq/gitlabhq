# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SlackIntegration, feature_category: :integrations do
  let_it_be(:integration) { create(:slack_integration) }

  describe "Associations" do
    it { is_expected.to belong_to(:integration) }
  end

  describe 'authorized_scope_names' do
    subject(:slack_integration) { integration }

    it 'accepts assignment to nil' do
      slack_integration.update!(authorized_scope_names: nil)

      expect(slack_integration.authorized_scope_names).to be_empty
    end

    it 'accepts assignment to a string' do
      slack_integration.update!(authorized_scope_names: 'foo')

      expect(slack_integration.authorized_scope_names).to contain_exactly('foo')
    end

    it 'accepts assignment to an array of strings' do
      slack_integration.update!(authorized_scope_names: %w[foo bar])

      expect(slack_integration.authorized_scope_names).to contain_exactly('foo', 'bar')
    end

    it 'accepts assignment to a comma-separated string' do
      slack_integration.update!(authorized_scope_names: 'foo,bar')

      expect(slack_integration.authorized_scope_names).to contain_exactly('foo', 'bar')
    end

    it 'strips white-space' do
      slack_integration.update!(authorized_scope_names: 'foo , bar,baz')

      expect(slack_integration.authorized_scope_names).to contain_exactly('foo', 'bar', 'baz')
    end
  end

  describe 'all_features_supported?/upgrade_needed?' do
    subject(:slack_integration) { integration }

    context 'with enough scopes' do
      before do
        slack_integration.update!(authorized_scope_names: %w[chat:write.public chat:write commands])
      end

      it { is_expected.to be_all_features_supported }
      it { is_expected.not_to be_upgrade_needed }
    end

    %w[chat:write.public chat:write].each do |scope_name|
      context "without #{scope_name}" do
        before do
          scopes = %w[chat:write.public chat:write] - [scope_name]
          slack_integration.update!(authorized_scope_names: scopes)
        end

        it { is_expected.not_to be_all_features_supported }
        it { is_expected.to be_upgrade_needed }
      end
    end
  end

  describe 'feature_available?' do
    subject(:slack_integration) { integration }

    context 'without any scopes' do
      it 'is always true for :commands' do
        expect(slack_integration).to be_feature_available(:commands)
      end

      it 'is always false for others' do
        expect(slack_integration).not_to be_feature_available(:notifications)
        expect(slack_integration).not_to be_feature_available(:foo)
      end
    end

    context 'with enough scopes for notifications' do
      before do
        slack_integration.update!(authorized_scope_names: %w[chat:write.public chat:write foo])
      end

      it 'only has the correct features' do
        expect(slack_integration).to be_feature_available(:commands)
        expect(slack_integration).to be_feature_available(:notifications)
        expect(slack_integration).not_to be_feature_available(:foo)
      end
    end

    context 'with enough scopes for commands' do
      before do
        slack_integration.update!(authorized_scope_names: %w[commands foo])
      end

      it 'only has the correct features' do
        expect(slack_integration).to be_feature_available(:commands)
        expect(slack_integration).not_to be_feature_available(:notifications)
        expect(slack_integration).not_to be_feature_available(:foo)
      end
    end

    context 'with all scopes' do
      before do
        slack_integration.update!(authorized_scope_names: %w[commands chat:write chat:write.public])
      end

      it 'only has the correct features' do
        expect(slack_integration).to be_feature_available(:commands)
        expect(slack_integration).to be_feature_available(:notifications)
        expect(slack_integration).not_to be_feature_available(:foo)
      end
    end
  end

  describe '#to_database_hash' do
    subject(:slack_integration) { integration }

    it 'includes the correct attributes' do
      expect(slack_integration.to_database_hash.keys).to contain_exactly(*described_class::DATABASE_ATTRIBUTES)
    end
  end

  it 'toggles the integration to active when created' do
    integration = create(:gitlab_slack_application_integration, active: false, slack_integration: nil)

    expect { create(:slack_integration, integration: integration) }.to change { integration.reload.active }.to(true)
  end

  it 'toggles the integration to inactive when destroyed' do
    integration = create(:gitlab_slack_application_integration)

    expect { integration.slack_integration.destroy! }.to change { integration.reload.active }.to(false)
  end

  describe 'Scopes' do
    let_it_be(:slack_integration) { integration }
    let_it_be(:legacy_slack_integration) { create(:slack_integration, :legacy) }

    describe '#with_bot' do
      it 'returns records with bot data' do
        expect(described_class.with_bot).to contain_exactly(slack_integration)
      end
    end

    describe '#by_team' do
      it 'returns records with shared team_id' do
        team_id = slack_integration.team_id
        team_slack_integration = create(:slack_integration, team_id: team_id)

        expect(described_class.by_team(team_id)).to contain_exactly(slack_integration, team_slack_integration)
      end
    end

    describe '#by_integration' do
      it 'returns records by the integration' do
        integration = legacy_slack_integration.integration

        expect(described_class.by_integration(integration)).to contain_exactly(legacy_slack_integration)
      end
    end
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:team_id) }
    it { is_expected.to validate_presence_of(:team_name) }
    it { is_expected.to validate_presence_of(:alias) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:integration) }
  end
end
