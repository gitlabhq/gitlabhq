# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::MattermostSlashCommands do
  describe 'Mattermost API' do
    let_it_be_with_reload(:project) { create(:project) }

    let(:integration) { project.build_mattermost_slash_commands_integration }
    let(:user) { build_stubbed(:user) }

    before do
      session = ::Mattermost::Session.new(nil)
      session.base_uri = 'http://mattermost.example.com'

      allow(session).to receive(:with_session).and_yield(session)
      allow(::Mattermost::Session).to receive(:new).and_return(session)
    end

    describe '#configure' do
      subject do
        integration.configure(
          user,
          team_id: 'abc',
          trigger: 'gitlab',
          url: 'http://trigger.url',
          icon_url: 'http://icon.url/icon.png'
        )
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

    describe '#redirect_url' do
      let(:url) { 'http://www.mattermost.com/hooks' }

      subject { integration.redirect_url('team', 'channel', url) }

      it { is_expected.to eq("http://www.mattermost.com/team/channels/channel") }

      context 'with invalid URL scheme' do
        let(:url) { 'javascript://www.mattermost.com/hooks' }

        it { is_expected.to be_nil }
      end

      context 'with unsafe URL' do
        let(:url) { "https://replaceme.com/'><script>alert(document.cookie)</script>" }

        it { is_expected.to be_nil }
      end
    end

    describe '#confirmation_url' do
      let(:params) do
        {
          team_domain: 'gitlab',
          channel_name: 'test-channel',
          response_url: 'http://mattermost.gitlab.com/hooks/commands/my123command'
        }
      end

      subject { integration.confirmation_url('command-id', params) }

      it { is_expected.to be_present }
    end
  end

  describe '#avatar_url' do
    it 'returns the avatar image path' do
      expect(subject.avatar_url).to eq(
        ActionController::Base.helpers.image_path('illustrations/third-party-logos/integrations-logos/mattermost.svg')
      )
    end
  end
end
