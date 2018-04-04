require 'spec_helper'

describe Mattermost::Command do
  let(:params) { { 'token' => 'token', team_id: 'abc' } }

  before do
    session = Mattermost::Session.new(nil)
    session.base_uri = 'http://mattermost.example.com'

    allow_any_instance_of(Mattermost::Client).to receive(:with_session)
      .and_yield(session)
  end

  describe '#create' do
    let(:params) do
      { team_id: 'abc',
        trigger: 'gitlab' }
    end

    subject { described_class.new(nil).create(params) }

    context 'for valid trigger word' do
      before do
        stub_request(:post, 'http://mattermost.example.com/api/v3/teams/abc/commands/create')
          .with(body: {
            team_id: 'abc',
            trigger: 'gitlab'
          }.to_json)
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: { token: 'token' }.to_json
          )
      end

      it 'returns a token' do
        is_expected.to eq('token')
      end
    end

    context 'for error message' do
      before do
        stub_request(:post, 'http://mattermost.example.com/api/v3/teams/abc/commands/create')
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

      it 'raises an error with message' do
        expect { subject }.to raise_error(Mattermost::Error, 'This trigger word is already in use. Please choose another word.')
      end
    end
  end
end
