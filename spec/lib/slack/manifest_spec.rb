# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Slack::Manifest, feature_category: :integrations do
  let(:base_manifest) do
    {
      display_information: {
        name: "GitLab (#{Gitlab.config.gitlab.host})",
        description: s_('SlackIntegration|Interact with GitLab without leaving your Slack workspace!'),
        background_color: '#171321',
        long_description: "Generated for #{Gitlab.config.gitlab.host} by GitLab #{Gitlab::VERSION}.\r\n\r\n" \
                          "- *Notifications:* Get notifications to your team's Slack channel about events " \
                          "happening inside your GitLab projects.\r\n\r\n- *Slash commands:* Quickly open, " \
                          'access, or close issues from Slack using the `/gitlab` command. Streamline your ' \
                          'GitLab deployments with ChatOps.'
      },
      features: {
        app_home: {
          home_tab_enabled: true,
          messages_tab_enabled: false,
          messages_tab_read_only_enabled: true
        },
        bot_user: {
          display_name: 'GitLab',
          always_online: true
        },
        slash_commands: [
          {
            command: '/gitlab',
            url: "#{Gitlab.config.gitlab.url}/api/v4/slack/trigger",
            description: 'GitLab slash commands',
            usage_hint: 'your-project-name-or-alias command',
            should_escape: false
          }
        ]
      },
      oauth_config: {
        redirect_urls: [
          Gitlab.config.gitlab.url
        ],
        scopes: {
          bot: %w[
            commands
            chat:write
            chat:write.public
          ]
        }
      },
      settings: {
        event_subscriptions: {
          request_url: "#{Gitlab.config.gitlab.url}/api/v4/integrations/slack/events",
          bot_events: described_class::BASE_BOT_EVENTS
        },
        interactivity: {
          is_enabled: true,
          request_url: "#{Gitlab.config.gitlab.url}/api/v4/integrations/slack/interactions",
          message_menu_options_url: "#{Gitlab.config.gitlab.url}/api/v4/integrations/slack/options"
        },
        org_deploy_enabled: false,
        socket_mode_enabled: false,
        token_rotation_enabled: false
      }
    }
  end

  describe '.to_h' do
    it 'creates the correct manifest with default arguments' do
      expect(described_class.to_h).to eq(base_manifest)
    end

    it 'creates the correct manifest when duo_enabled is false' do
      expect(described_class.to_h(duo_enabled: false)).to eq(base_manifest)
    end

    context 'when duo_enabled is true' do
      subject(:manifest) { described_class.to_h(duo_enabled: true) }

      it 'adds the Duo bot scopes' do
        expect(manifest.dig(:oauth_config, :scopes, :bot)).to eq(SlackIntegration::DUO_SCOPES)
      end

      it 'adds the Duo bot events' do
        expect(manifest.dig(:settings, :event_subscriptions, :bot_events)).to include(*described_class::DUO_BOT_EVENTS)
      end

      it 'retains the base bot events' do
        expect(manifest.dig(:settings, :event_subscriptions, :bot_events)).to include(*described_class::BASE_BOT_EVENTS)
      end

      it 'does not change display_information' do
        expect(manifest[:display_information]).to eq(base_manifest[:display_information])
      end

      it 'does not change features' do
        expect(manifest[:features]).to eq(base_manifest[:features])
      end

      it 'does not change interactivity settings' do
        expect(manifest.dig(:settings, :interactivity)).to eq(base_manifest.dig(:settings, :interactivity))
      end
    end
  end

  describe '.to_json' do
    shared_examples 'a manifest that matches the JSON schema' do
      # JSON schema file downloaded from
      # https://raw.githubusercontent.com/slackapi/manifest-schema/v0.0.0/schemas/manifest.schema.2.0.0.json
      # via https://github.com/slackapi/manifest-schema.
      it { is_expected.to match_schema('slack/manifest') }
    end

    context 'with default arguments' do
      subject(:to_json) { described_class.to_json }

      it_behaves_like 'a manifest that matches the JSON schema'
    end

    context 'when duo_enabled is false' do
      subject(:to_json) { described_class.to_json(duo_enabled: false) }

      it_behaves_like 'a manifest that matches the JSON schema'

      it 'is byte-identical to the default output' do
        expect(described_class.to_json(duo_enabled: false)).to eq(described_class.to_json)
      end
    end

    context 'when duo_enabled is true' do
      subject(:to_json) { described_class.to_json(duo_enabled: true) }

      it_behaves_like 'a manifest that matches the JSON schema'
    end

    context 'when the host name is very long' do
      subject(:to_json) { described_class.to_json }

      before do
        allow(Gitlab.config.gitlab).to receive(:host).and_return('abc' * 20)
      end

      it_behaves_like 'a manifest that matches the JSON schema'
    end
  end

  describe '.share_url' do
    it 'URI encodes the manifest with default arguments' do
      allow(described_class).to receive(:to_h).with(duo_enabled: false).and_return({ foo: 'bar' })

      expect(described_class.share_url).to eq('https://api.slack.com/apps?new_app=1&manifest_json=%7B%22foo%22%3A%22bar%22%7D')
    end

    it 'URI encodes the Duo manifest when duo_enabled is true' do
      allow(described_class).to receive(:to_h).with(duo_enabled: true).and_return({ foo: 'baz' })

      expect(described_class.share_url(duo_enabled: true)).to eq('https://api.slack.com/apps?new_app=1&manifest_json=%7B%22foo%22%3A%22baz%22%7D')
    end
  end
end
