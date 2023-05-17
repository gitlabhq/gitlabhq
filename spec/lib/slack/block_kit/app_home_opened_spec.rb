# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Slack::BlockKit::AppHomeOpened, feature_category: :integrations do
  let_it_be(:slack_installation) { create(:slack_integration) }

  let(:chat_name) { nil }

  describe '#build' do
    subject(:payload) do
      described_class.new(slack_installation.user_id, slack_installation.team_id, chat_name, slack_installation).build
    end

    it 'generates blocks of type "home"' do
      is_expected.to match({ type: 'home', blocks: kind_of(Array) })
    end

    it 'prompts the user to connect their GitLab account' do
      expect(payload[:blocks]).to include(
        hash_including(
          {
            type: 'actions',
            elements: [
              hash_including(
                {
                  type: 'button',
                  text: include({ text: 'Connect your GitLab account' }),
                  url: include(Gitlab::Routing.url_helpers.new_profile_chat_name_url)
                }
              )
            ]
          }
        )
      )
    end

    context 'when the user has linked their GitLab account' do
      let_it_be(:user) { create(:user) }
      let_it_be(:chat_name) do
        create(:chat_name,
          user: user,
          team_id: slack_installation.team_id,
          chat_id: slack_installation.user_id
        )
      end

      it 'displays the GitLab user they are linked to' do
        account = "<#{Gitlab::UrlBuilder.build(user)}|#{user.to_reference}>"

        expect(payload[:blocks]).to include(
          hash_including(
            {
              type: 'section',
              text: include({ text: "✅ Connected to GitLab account #{account}." })
            }
          )
        )
      end
    end
  end
end
