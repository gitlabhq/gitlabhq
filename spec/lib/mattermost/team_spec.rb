require 'spec_helper'

describe Mattermost::Team do
  before do
    session = Mattermost::Session.new(nil)
    session.base_uri = 'http://mattermost.example.com'

    allow_any_instance_of(Mattermost::Client).to receive(:with_session)
      .and_yield(session)
  end

  describe '#all' do
    subject { described_class.new(nil).all }

    context 'for valid request' do
      let(:response) do
        { "xiyro8huptfhdndadpz8r3wnbo" => {
          "id" => "xiyro8huptfhdndadpz8r3wnbo",
          "create_at" => 1482174222155,
          "update_at" => 1482174222155,
          "delete_at" => 0,
          "display_name" => "chatops",
          "name" => "chatops",
          "email" => "admin@example.com",
          "type" => "O",
          "company_name" => "",
          "allowed_domains" => "",
          "invite_id" => "o4utakb9jtb7imctdfzbf9r5ro",
          "allow_open_invite" => false
        } }
      end

      before do
        stub_request(:get, 'http://mattermost.example.com/api/v3/teams/all')
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: response.to_json
          )
      end

      it 'returns a token' do
        is_expected.to eq(response.values)
      end
    end

    context 'for error message' do
      before do
        stub_request(:get, 'http://mattermost.example.com/api/v3/teams/all')
          .to_return(
            status: 500,
            headers: { 'Content-Type' => 'application/json' },
            body: {
              id: 'api.team.list.app_error',
              message: 'Cannot list teams.',
              detailed_error: '',
              request_id: 'obc374man7bx5r3dbc1q5qhf3r',
              status_code: 500
            }.to_json
          )
      end

      it 'raises an error with message' do
        expect { subject }.to raise_error(Mattermost::Error, 'Cannot list teams.')
      end
    end
  end
end
