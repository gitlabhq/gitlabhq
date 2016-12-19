require 'spec_helper'

describe MattermostSlashCommandsService, models: true do
  describe "Associations" do
    it { is_expected.to respond_to :token }
  end

  describe '#valid_token?' do
    subject { described_class.new }

    context 'when the token is empty' do
      it 'is false' do
        expect(subject.valid_token?('wer')).to be_falsey
      end
    end

    context 'when there is a token' do
      before do
        subject.token = '123'
      end

      it 'accepts equal tokens' do
        expect(subject.valid_token?('123')).to be_truthy
      end
    end
  end

  describe '#trigger' do
    subject { described_class.new }

    context 'no token is passed' do
      let(:params) { Hash.new }

      it 'returns nil' do
        expect(subject.trigger(params)).to be_nil
      end
    end

    context 'with a token passed' do
      let(:project) { create(:empty_project) }
      let(:params) { { token: 'token' } }

      before do
        allow(subject).to receive(:token).and_return('token')
      end

      context 'no user can be found' do
        context 'when no url can be generated' do
          it 'responds with the authorize url' do
            response = subject.trigger(params)

            expect(response[:response_type]).to eq :ephemeral
            expect(response[:text]).to start_with ":sweat_smile: Couldn't identify you"
          end
        end

        context 'when an auth url can be generated' do
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
            project.create_mattermost_slash_commands_service(
              properties: { token: 'token' }
            )
          end

          it 'generates the url' do
            response = service.trigger(params)

            expect(response[:text]).to start_with(':wave: Hi there!')
          end
        end
      end

      context 'when the user is authenticated' do
        let!(:chat_name) { create(:chat_name, service: service) }
        let(:service) do
          project.create_mattermost_slash_commands_service(
            properties: { token: 'token' }
          )
        end
        let(:params) { { token: 'token', team_id: chat_name.team_id, user_id: chat_name.chat_id } }

        it 'triggers the command' do
          expect_any_instance_of(Gitlab::ChatCommands::Command).to receive(:execute)

          service.trigger(params)
        end
      end
    end
  end

  describe '#configure' do
    let(:project) { create(:empty_project) }
    let(:service) { project.build_mattermost_slash_commands_service }

    subject do
      service.configure('http://localhost:8065', team_id: 'abc', trigger: 'gitlab', url: 'http://trigger.url', icon_url: 'http://icon.url/icon.png')
    end

    context 'the requests succeeds' do
      before do
        allow_any_instance_of(Mattermost::Session).to receive(:with_session).
          and_return('token' => 'mynewtoken')
      end

      it 'saves the service' do
        expect_any_instance_of(Mattermost::Session).to receive(:with_session)
        expect { subject }.to change { project.services.count }.by(1)
      end

      it 'saves the token' do
        subject

        expect(service.reload.token).to eq('mynewtoken')
      end
    end

    context 'an error is received' do
      it 'shows error messages' do
        allow_any_instance_of(Mattermost::Session).to receive(:with_session).
          and_return('token' => 'mynewtoken', 'message' => "Error")

        expect(subject).to eq("Error")
      end
    end
  end
end
