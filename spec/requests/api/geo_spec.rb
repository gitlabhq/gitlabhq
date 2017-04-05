require 'spec_helper'

describe API::Geo, api: true do
  include ApiHelpers

  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let!(:primary_node) { create(:geo_node, :primary) }
  let(:geo_token_header) do
    { 'X-Gitlab-Token' => primary_node.system_hook.token }
  end

  before(:each) do
    allow(Gitlab::Geo).to receive(:current_node) { primary_node }
  end

  describe 'POST /geo/receive_events authentication' do
    it 'denies access if token is not present' do
      post api('/geo/receive_events')
      expect(response.status).to eq 401
    end

    it 'denies access if token is invalid' do
      post api('/geo/receive_events'), nil, { 'X-Gitlab-Token' => 'nothing' }
      expect(response.status).to eq 401
    end
  end

  describe 'POST /geo/refresh_wikis disabled node' do
    it 'responds with forbidden' do
      primary_node.enabled = false

      post api('/geo/refresh_wikis', admin), nil

      expect(response).to have_http_status(403)
    end
  end

  describe 'POST /geo/receive_events disabled node' do
    it 'responds with forbidden' do
      primary_node.enabled = false

      post api('/geo/receive_events'), nil, geo_token_header

      expect(response).to have_http_status(403)
    end
  end

  describe 'POST /geo/receive_events key events' do
    before(:each) { allow_any_instance_of(::Geo::ScheduleKeyChangeService).to receive(:execute) }

    let(:key_create_payload) do
      {
        'event_name' => 'key_create',
        'created_at' => '2014-08-18 18:45:16 UTC',
        'updated_at' => '2012-07-21T07:38:22Z',
        'username' => 'root',
        'key' => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC58FwqHUbebw2SdT7SP4FxZ0w+lAO/erhy2ylhlcW/tZ3GY3mBu9VeeiSGoGz8hCx80Zrz+aQv28xfFfKlC8XQFpCWwsnWnQqO2Lv9bS8V1fIHgMxOHIt5Vs+9CAWGCCvUOAurjsUDoE2ALIXLDMKnJxcxD13XjWdK54j6ZXDB4syLF0C2PnAQSVY9X7MfCYwtuFmhQhKaBussAXpaVMRHltie3UYSBUUuZaB3J4cg/7TxlmxcNd+ppPRIpSZAB0NI6aOnqoBCpimscO/VpQRJMVLr3XiSYeT6HBiDXWHnIVPfQc03OGcaFqOit6p8lYKMaP/iUQLm+pgpZqrXZ9vB john@localhost',
        'id' => 1
      }
    end

    let(:key_destroy_payload) do
      {
        'event_name' => 'key_destroy',
        'created_at' => '2014-08-18 18:45:16 UTC',
        'updated_at' => '2012-07-21T07:38:22Z',
        'username' => 'root',
        'key' => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC58FwqHUbebw2SdT7SP4FxZ0w+lAO/erhy2ylhlcW/tZ3GY3mBu9VeeiSGoGz8hCx80Zrz+aQv28xfFfKlC8XQFpCWwsnWnQqO2Lv9bS8V1fIHgMxOHIt5Vs+9CAWGCCvUOAurjsUDoE2ALIXLDMKnJxcxD13XjWdK54j6ZXDB4syLF0C2PnAQSVY9X7MfCYwtuFmhQhKaBussAXpaVMRHltie3UYSBUUuZaB3J4cg/7TxlmxcNd+ppPRIpSZAB0NI6aOnqoBCpimscO/VpQRJMVLr3XiSYeT6HBiDXWHnIVPfQc03OGcaFqOit6p8lYKMaP/iUQLm+pgpZqrXZ9vB john@localhost',
        'id' => 1
      }
    end

    it 'enqueues on disk key creation if admin and correct params' do
      post api('/geo/receive_events'), key_create_payload, geo_token_header
      expect(response.status).to eq 201
    end

    it 'enqueues on disk key removal if admin and correct params' do
      post api('/geo/receive_events'), key_destroy_payload, geo_token_header
      expect(response.status).to eq 201
    end
  end

  describe 'POST /geo/receive_events push events' do
    before(:each) { allow_any_instance_of(::Geo::ScheduleRepoUpdateService).to receive(:execute) }
    before(:each) { allow_any_instance_of(::Geo::ScheduleRepoFetchService).to receive(:execute) }

    let(:push_payload) do
      {
        'event_name' => 'push',
        'project_id' => 1,
        'project' => {
          'git_ssh_url' => 'git@example.com:mike/diaspora.git'
        }
      }
    end

    it 'starts refresh process if admin and correct params' do
      post api('/geo/receive_events'), push_payload, geo_token_header
      expect(response.status).to eq 201
    end
  end

  describe 'POST /geo/receive_events push_tag events' do
    before(:each) { allow_any_instance_of(::Geo::ScheduleWikiRepoUpdateService).to receive(:execute) }

    let(:tag_push_payload) do
      {
        'event_name' => 'tag_push',
        'project_id' => 1,
        'project' => {
          'git_ssh_url' => 'git@example.com:mike/diaspora.git'
        }
      }
    end

    it 'starts refresh process if admin and correct params' do
      post api('/geo/receive_events'), tag_push_payload, geo_token_header
      expect(response.status).to eq 201
    end
  end

  describe 'GET /geo/transfers/lfs/1' do
    let!(:secondary_node) { create(:geo_node) }
    let(:lfs_object) { create(:lfs_object, :with_file) }
    let(:req_header) do
      transfer = Gitlab::Geo::LfsTransfer.new(lfs_object)
      Gitlab::Geo::TransferRequest.new(transfer.request_data).headers
    end

    before do
      allow_any_instance_of(Gitlab::Geo::TransferRequest).to receive(:requesting_node).and_return(secondary_node)
    end

    it 'responds with 401 with invalid auth header' do
      get api("/geo/transfers/lfs/#{lfs_object.id}"), nil, Authorization: 'Test'

      expect(response.status).to eq 401
    end

    context 'LFS file exists' do
      it 'responds with 200 with X-Sendfile' do
        get api("/geo/transfers/lfs/#{lfs_object.id}"), nil, req_header

        expect(response.status).to eq 200
        expect(response.headers['Content-Type']).to eq('application/octet-stream')
        expect(response.headers['X-Sendfile']).to eq(lfs_object.file.path)
      end
    end

    context 'LFS object does not exist' do
      it 'responds with 404' do
        get api("/geo/transfers/lfs/100000"), nil, req_header

        expect(response.status).to eq 404
      end
    end
  end

  describe 'GET /geo/status' do
    let!(:secondary_node) { create(:geo_node) }
    let(:request) { Gitlab::Geo::BaseRequest.new }

    it 'responds with 401 with invalid auth header' do
      get api('/geo/status'), nil, Authorization: 'Test'

      expect(response.status).to eq 401
    end

    context 'when requesting secondary node with valid auth header' do
      before(:each) do
        allow(Gitlab::Geo).to receive(:current_node) { secondary_node }
        allow(request).to receive(:requesting_node) { primary_node }
      end

      it 'responds with 200' do
        get api('/geo/status'), nil, request.headers

        expect(response.status).to eq 200
        expect(response.headers['Content-Type']).to eq('application/json')
      end

      it 'responds with a 404 when the tracking database is disabled' do
        allow(Gitlab::Geo).to receive(:configured?).and_return(false)

        get api('/geo/status'), nil, request.headers

        expect(response).to have_http_status(404)
      end
    end

    context 'when requesting primary node with valid auth header' do
      before(:each) do
        allow(Gitlab::Geo).to receive(:current_node) { primary_node }
        allow(request).to receive(:requesting_node) { secondary_node }
      end

      it 'responds with 403' do
        get api('/geo/status'), nil, request.headers

        expect(response).to have_http_status(403)
      end
    end
  end
end
