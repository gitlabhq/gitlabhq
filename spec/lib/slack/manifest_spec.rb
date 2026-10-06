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

    it 'does not include the agent_view feature when duo_enabled is false' do
      expect(described_class.to_h(duo_enabled: false).dig(:features, :agent_view)).to be_nil
    end

    context 'when duo_enabled is true' do
      subject(:manifest) { described_class.to_h(duo_enabled: true) }

      it 'adds the Duo and agent app bot scopes' do
        expect(manifest.dig(:oauth_config, :scopes, :bot))
          .to eq(SlackIntegration::DUO_SCOPES + SlackIntegration::AGENT_APP_SCOPES)
      end

      it 'adds the Duo and agent app bot events' do
        expect(manifest.dig(:settings, :event_subscriptions, :bot_events))
          .to include(*described_class::DUO_BOT_EVENTS, *described_class::AGENT_APP_BOT_EVENTS)
      end

      it 'retains the base bot events' do
        expect(manifest.dig(:settings, :event_subscriptions, :bot_events)).to include(*described_class::BASE_BOT_EVENTS)
      end

      it 'does not change display_information' do
        expect(manifest[:display_information]).to eq(base_manifest[:display_information])
      end

      it 'enables the agent feature', :aggregate_failures do
        expect(manifest.dig(:features, :agent_view)).to include(
          agent_description: a_string_including('GitLab Duo')
        )
        expect(manifest.dig(:features, :app_home)).to eq(
          home_tab_enabled: true,
          messages_tab_enabled: true,
          messages_tab_read_only_enabled: false
        )
      end

      it 'does not change bot_user or slash_commands features', :aggregate_failures do
        expect(manifest.dig(:features, :bot_user)).to eq(base_manifest.dig(:features, :bot_user))
        expect(manifest.dig(:features, :slash_commands)).to eq(base_manifest.dig(:features, :slash_commands))
      end

      it 'does not change interactivity settings' do
        expect(manifest.dig(:settings, :interactivity)).to eq(base_manifest.dig(:settings, :interactivity))
      end

      context 'when the slack_duo_agent_app release flag is disabled' do
        before do
          stub_feature_flags(slack_duo_agent_app: false)
        end

        it 'adds only the Duo bot scopes' do
          expect(manifest.dig(:oauth_config, :scopes, :bot)).to eq(SlackIntegration::DUO_SCOPES)
        end

        it 'adds only the Duo bot events', :aggregate_failures do
          bot_events = manifest.dig(:settings, :event_subscriptions, :bot_events)

          expect(bot_events).to include(*described_class::DUO_BOT_EVENTS)
          expect(bot_events).not_to include(*described_class::AGENT_APP_BOT_EVENTS)
        end

        it 'does not enable the agent feature', :aggregate_failures do
          expect(manifest.dig(:features, :agent_view)).to be_nil
          expect(manifest.dig(:features, :app_home)).to eq(base_manifest.dig(:features, :app_home))
        end
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
