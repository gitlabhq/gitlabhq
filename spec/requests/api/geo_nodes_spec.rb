require 'spec_helper'

describe API::GeoNodes, :geo, api: true do
  include ApiHelpers
  include ::EE::GeoHelpers

  set(:primary) { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }
  set(:another_secondary) { create(:geo_node) }

  set(:secondary_status) { create(:geo_node_status, :healthy, geo_node_id: secondary.id) }
  set(:another_secondary_status) { create(:geo_node_status, :healthy, geo_node_id: another_secondary.id) }

  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  describe 'GET /geo_nodes' do
    it 'retrieves the Geo nodes if admin is logged in' do
      get api("/geo_nodes", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('geo_nodes')
    end

    it 'denies access if not admin' do
      get api('/geo_nodes', user)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'GET /geo_nodes/:id' do
    it 'retrieves the Geo nodes if admin is logged in' do
      get api("/geo_nodes/#{primary.id}", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('geo_node')
    end

    it 'denies access if not admin' do
      get api('/geo_nodes', user)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'GET /geo_nodes/status' do
    it 'retrieves the Geo nodes status if admin is logged in' do
      get api("/geo_nodes/status", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('geo_node_statuses')
    end

    it 'denies access if not admin' do
      get api('/geo_nodes', user)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'GET /geo_nodes/:id/status' do
    it 'retrieves the Geo nodes status if admin is logged in' do
      stub_current_geo_node(primary)

      expect(GeoNodeStatus).not_to receive(:current_node_status)

      get api("/geo_nodes/#{secondary.id}/status", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('geo_node_status')
    end

    it 'fetches the current node status' do
      stub_current_geo_node(secondary)

      expect(GeoNode).to receive(:find).and_return(secondary)
      expect(GeoNodeStatus).to receive(:current_node_status).and_call_original

      get api("/geo_nodes/#{secondary.id}/status", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('geo_node_status')
    end

    it 'denies access if not admin' do
      get api('/geo_nodes', user)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'GET /geo_nodes/current/failures/:type' do
    it 'fetches the current node failures' do
      create(:geo_project_registry, :sync_failed)
      create(:geo_project_registry, :sync_failed)

      stub_current_geo_node(secondary)
      expect(Gitlab::Geo).to receive(:current_node).and_return(secondary)

      get api("/geo_nodes/current/failures", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('geo_project_registry')
    end

    it 'does not show any registry when there is no failure' do
      create(:geo_project_registry, :synced)

      stub_current_geo_node(secondary)
      expect(Gitlab::Geo).to receive(:current_node).and_return(secondary)

      get api("/geo_nodes/current/failures", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response.count).to be_zero
    end

    context 'wiki type' do
      it 'only shows wiki failures' do
        create(:geo_project_registry, :wiki_sync_failed)
        create(:geo_project_registry, :repository_sync_failed)

        stub_current_geo_node(secondary)
        expect(Gitlab::Geo).to receive(:current_node).and_return(secondary)

        get api("/geo_nodes/current/failures?type=wiki", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.count).to eq(1)
        expect(json_response.first['wiki_retry_count']).to be > 0
      end
    end

    context 'repository type' do
      it 'only shows repository failures' do
        create(:geo_project_registry, :wiki_sync_failed)
        create(:geo_project_registry, :repository_sync_failed)

        stub_current_geo_node(secondary)
        expect(Gitlab::Geo).to receive(:current_node).and_return(secondary)

        get api("/geo_nodes/current/failures?type=repository", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.count).to eq(1)
        expect(json_response.first['repository_retry_count']).to be > 0
      end
    end

    context 'nonexistent type' do
      it 'returns a bad request' do
        create(:geo_project_registry, :repository_sync_failed)

        get api("/geo_nodes/current/failures?type=nonexistent", admin)

        expect(response).to have_gitlab_http_status(400)
      end
    end

    it 'denies access if not admin' do
      get api("/geo_nodes/current/failures", user)

      expect(response).to have_gitlab_http_status(403)
    end
  end
end
