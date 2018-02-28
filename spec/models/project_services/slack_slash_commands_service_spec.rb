require 'spec_helper'

describe SlackSlashCommandsService do
  it_behaves_like "chat slash commands service"

  describe '#trigger' do
    context 'when an auth url is generated' do
      let(:project) { create(:project) }
      let(:params) do
        {
          team_domain: 'http://domain.tld',
          team_id: 'T3423423',
          user_id: 'U234234',
          user_name: 'mepmep',
          token: 'token'
        }
      end

      let(:service) do
        project.create_slack_slash_commands_service(
          properties: { token: 'token' },
          active: true
        )
      end

      let(:authorize_url) do
        'http://authorize.example.com/'
      end

      before do
        allow(service).to receive(:authorize_chat_name_url).and_return(authorize_url)
      end

      it 'uses slack compatible links' do
        response = service.trigger(params)

        expect(response[:text]).to include("<#{authorize_url}|connect your GitLab account>")
      end
    end
  end
end
