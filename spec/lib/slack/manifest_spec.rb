# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Slack::Manifest, feature_category: :integrations do
  describe '.to_h' do
    it 'creates the correct manifest' do
      expect(described_class.to_h).to eq({
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
            bot_events: %w[
              app_home_opened
            ]
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
      })
    end
  end

  describe '.to_json' do
    subject(:to_json) { described_class.to_json }

    shared_examples 'a manifest that matches the JSON schema' do
      # JSON schema file downloaded from
      # https://raw.githubusercontent.com/slackapi/manifest-schema/v0.0.0/schemas/manifest.schema.2.0.0.json
      # via https://github.com/slackapi/manifest-schema.
      it { is_expected.to match_schema('slack/manifest') }
    end

    it_behaves_like 'a manifest that matches the JSON schema'

    context 'when the host name is very long' do
      before do
        allow(Gitlab.config.gitlab).to receive(:host).and_return('abc' * 20)
      end

      it_behaves_like 'a manifest that matches the JSON schema'
    end
  end

  describe '.share_url' do
    it 'URI encodes the manifest' do
      allow(described_class).to receive(:to_h).and_return({ foo: 'bar' })

      expect(described_class.share_url).to eq('https://api.slack.com/apps?new_app=1&manifest_json=%7B%22foo%22%3A%22bar%22%7D')
    end
  end
end
