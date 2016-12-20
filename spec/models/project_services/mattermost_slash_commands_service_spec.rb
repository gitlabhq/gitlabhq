require 'spec_helper'

describe MattermostSlashCommandsService, :models do
  it_behaves_like "chat slash commands service"

  describe '#configure!' do
    let(:project) { create(:empty_project) }
    let(:service) { project.build_mattermost_slash_commands_service }
    let(:user) { create(:user)}

    before do
      allow_any_instance_of(Mattermost::Session).to
      receive(:with_session).and_yield
    end

    subject do
      service.configure!(user, team_id: 'abc',
                               trigger: 'gitlab', url: 'http://trigger.url',
                               icon_url: 'http://icon.url/icon.png')
    end

    context 'the requests succeeds' do
      it 'saves the service' do
        expect { subject }.to change { project.services.count }.by(1)
      end

      it 'saves the token' do
        subject

        expect(service.reload.token).to eq('mynewtoken')
      end
    end

    context 'an error is received' do
      it 'shows error messages' do
        expect(subject).to raise_error("Error")
      end
    end
  end
end
