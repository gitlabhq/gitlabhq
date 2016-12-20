require 'spec_helper'

describe MattermostSlashCommandsService, :models do
  it_behaves_like "chat slash commands service"

  describe '#configure' do
    let(:project) { create(:empty_project) }
    let(:service) { project.build_mattermost_slash_commands_service }
    let(:user) { create(:user)}

    subject do
      service.configure(user, team_id: 'abc',
                               trigger: 'gitlab', url: 'http://trigger.url',
                               icon_url: 'http://icon.url/icon.png')
    end

    context 'the requests succeeds' do
      before do
        allow_any_instance_of(Mattermost::Command).
          to receive(:json_post).and_return('token' => 'token')
      end

      it 'saves the service' do
        expect { subject }.to change { project.services.count }.by(1)
      end

      it 'saves the token' do
        subject

        expect(service.reload.token).to eq('token')
      end
    end

    context 'an error is received' do
      it 'shows error messages' do
        succeeded, message = subject

        expect(succeeded).to be(false)
        expect(message).to start_with("Failed to open TCP connection to")
      end
    end
  end
end
