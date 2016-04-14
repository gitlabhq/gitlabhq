require 'spec_helper'

describe API::API, api: true do
  include ApiHelpers
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:geo_node) { build(:geo_node) }

  describe 'POST /geo/refresh_projects' do
    before(:each) { allow_any_instance_of(::Geo::ScheduleRepoUpdateService).to receive(:execute) }

    it 'starts refresh process if admin and correct params' do
      post api('/geo/refresh_projects', admin), projects: ['1', '2', '3']
      expect(response.status).to eq 201
    end

    it 'denies access if not admin' do
      post api('/geo/refresh_projects', user)
      expect(response.status).to eq 403
    end
  end

  describe 'POST /geo/receive_events' do
    before(:each) do
      allow_any_instance_of(::Geo::ScheduleKeyChangeService).to receive(:execute)
      allow(Gitlab::Geo).to receive(:current_node) { geo_node }
    end

    let(:geo_token_header) do
      { 'X-Gitlab-Token' => geo_node.system_hook.token }
    end

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

    it 'denies access if token is not present' do
      post api('/geo/receive_events')
      expect(response.status).to eq 401
    end

    it 'denies access if token is invalid' do
      post api('/geo/receive_events'), nil, { 'X-Gitlab-Token' => 'nothing' }
      expect(response.status).to eq 401
    end
  end
end
