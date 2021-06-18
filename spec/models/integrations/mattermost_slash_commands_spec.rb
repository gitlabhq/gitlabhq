# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::MattermostSlashCommands do
  it_behaves_like Integrations::BaseSlashCommands

  describe 'Mattermost API' do
    let(:project) { create(:project) }
    let(:integration) { project.build_mattermost_slash_commands_integration }
    let(:user) { create(:user) }

    before do
      session = ::Mattermost::Session.new(nil)
      session.base_uri = 'http://mattermost.example.com'

      allow(session).to receive(:with_session).and_yield(session)
      allow(::Mattermost::Session).to receive(:new).and_return(session)
    end

    describe '#configure' do
      subject do
        integration.configure(user,
                              team_id: 'abc',
                              trigger: 'gitlab',
                              url: 'http://trigger.url',
                              icon_url: 'http://icon.url/icon.png')
      end

      context 'when the request succeeds' do
        before do
          stub_request(:post, 'http://mattermost.example.com/api/v4/commands')
            .with(body: {
              team_id: 'abc',
              trigger: 'gitlab',
              url: 'http://trigger.url',
              icon_url: 'http://icon.url/icon.png',
              auto_complete: true,
              auto_complete_desc: "Perform common operations on: #{project.full_name}",
              auto_complete_hint: '[help]',
              description: "Perform common operations on: #{project.full_name}",
              display_name: "GitLab / #{project.full_name}",
              method: 'P',
              username: 'GitLab'
            }.to_json)
            .to_return(
              status: 200,
              headers: { 'Content-Type' => 'application/json' },
              body: { token: 'token' }.to_json
            )
        end

        it 'saves the integration' do
          expect { subject }.to change { project.integrations.count }.by(1)
        end

        it 'saves the token' do
          subject

          expect(integration.reload.token).to eq('token')
        end
      end

      context 'when an error is received' do
        before do
          stub_request(:post, 'http://mattermost.example.com/api/v4/commands')
            .to_return(
              status: 500,
              headers: { 'Content-Type' => 'application/json' },
              body: {
                id: 'api.command.duplicate_trigger.app_error',
                message: 'This trigger word is already in use. Please choose another word.',
                detailed_error: '',
                request_id: 'obc374man7bx5r3dbc1q5qhf3r',
                status_code: 500
              }.to_json
            )
        end

        it 'shows error messages' do
          succeeded, message = subject

          expect(succeeded).to be(false)
          expect(message).to eq('This trigger word is already in use. Please choose another word.')
        end
      end
    end

    describe '#list_teams' do
      subject do
        integration.list_teams(user)
      end

      context 'when the request succeeds' do
        before do
          stub_request(:get, 'http://mattermost.example.com/api/v4/users/me/teams')
            .to_return(
              status: 200,
              headers: { 'Content-Type' => 'application/json' },
              body: [{ id: 'test_team_id' }].to_json
            )
        end

        it 'returns a list of teams' do
          expect(subject).not_to be_empty
        end
      end

      context 'when an error is received' do
        before do
          stub_request(:get, 'http://mattermost.example.com/api/v4/users/me/teams')
            .to_return(
              status: 500,
              headers: { 'Content-Type' => 'application/json' },
              body: {
                message: 'Failed to get team list.'
              }.to_json
            )
        end

        it 'shows error messages' do
          expect(subject).to eq([[], "Failed to get team list."])
        end
      end
    end

    describe '#chat_responder' do
      it 'returns the responder to use for Mattermost' do
        expect(described_class.new.chat_responder)
          .to eq(Gitlab::Chat::Responder::Mattermost)
      end
    end
  end
end
