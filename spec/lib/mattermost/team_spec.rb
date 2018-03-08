require 'spec_helper'

describe Mattermost::Team do
  before do
    Mattermost::Session.base_uri('http://mattermost.example.com')

    allow_any_instance_of(Mattermost::Client).to receive(:with_session)
      .and_yield(Mattermost::Session.new(nil))
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

  describe '#create' do
    subject { described_class.new(nil).create(name: "devteam", display_name: "Dev Team", type: "O") }

    context 'for a new team' do
      let(:response) do
        {
          "id" => "cuojfcetjty7tb4pxe47pwpndo",
          "create_at" => 1517688728701,
          "update_at" => 1517688728701,
          "delete_at" => 0,
          "display_name" => "Dev Team",
          "name" => "devteam",
          "description" => "",
          "email" => "admin@example.com",
          "type" => "O",
          "company_name" => "",
          "allowed_domains" => "",
          "invite_id" => "7mp9d3ayaj833ymmkfnid8js6w",
          "allow_open_invite" => false
        }
      end

      before do
        stub_request(:post, "http://mattermost.example.com/api/v3/teams/create")
          .to_return(
            status: 200,
            body: response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns the new team' do
        is_expected.to eq(response)
      end
    end

    context 'for existing team' do
      before do
        stub_request(:post, 'http://mattermost.example.com/api/v3/teams/create')
          .to_return(
            status: 400,
            headers: { 'Content-Type' => 'application/json' },
            body: {
                id: "store.sql_team.save.domain_exists.app_error",
                message: "A team with that name already exists",
                detailed_error: "",
                request_id: "1hsb5bxs97r8bdggayy7n9gxaw",
                status_code: 400
            }.to_json
          )
      end

      it 'raises an error with message' do
        expect { subject }.to raise_error(Mattermost::Error, 'A team with that name already exists')
      end
    end
  end

  describe '#delete' do
    subject { described_class.new(nil).destroy(team_id: "cuojfcetjty7tb4pxe47pwpndo") }

    context 'for an existing team' do
      let(:response) do
        {
            "status" => "OK"
        }
      end

      before do
        stub_request(:delete, "http://mattermost.example.com/api/v4/teams/cuojfcetjty7tb4pxe47pwpndo")
          .to_return(
            status: 200,
            body: response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns team status' do
        is_expected.to eq(response)
      end
    end

    context 'for an unknown team' do
      before do
        stub_request(:delete, "http://mattermost.example.com/api/v4/teams/cuojfcetjty7tb4pxe47pwpndo")
          .to_return(
            status: 404,
            body: {
              id: "store.sql_team.get.find.app_error",
              message: "We couldn't find the existing team",
              detailed_error: "",
              request_id: "my114ab5nbnui8c9pes4kz8mza",
              status_code: 404
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an error with message' do
        expect { subject }.to raise_error(Mattermost::Error, "We couldn't find the existing team")
      end
    end
  end
end
