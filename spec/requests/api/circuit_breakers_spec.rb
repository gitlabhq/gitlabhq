require 'spec_helper'

describe API::CircuitBreakers do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  describe 'GET circuit_breakers/repository_storage' do
    it 'returns a 401 for anonymous users' do
      get api('/circuit_breakers/repository_storage')

      expect(response).to have_gitlab_http_status(401)
    end

    it 'returns a 403 for users' do
      get api('/circuit_breakers/repository_storage', user)

      expect(response).to have_gitlab_http_status(403)
    end

    it 'returns an Array of storages' do
      expect(Gitlab::Git::Storage::Health).to receive(:for_all_storages) do
        [Gitlab::Git::Storage::Health.new('broken', [{ name: 'prefix:broken:web01', failure_count: 4 }])]
      end

      get api('/circuit_breakers/repository_storage', admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_kind_of(Array)
      expect(json_response.first['storage_name']).to eq('broken')
      expect(json_response.first['failing_on_hosts']).to eq(['web01'])
      expect(json_response.first['total_failures']).to eq(4)
    end

    describe 'GET circuit_breakers/repository_storage/failing' do
      it 'returns an array of failing storages' do
        expect(Gitlab::Git::Storage::Health).to receive(:for_failing_storages) do
          [Gitlab::Git::Storage::Health.new('broken', [{ name: 'prefix:broken:web01', failure_count: 4 }])]
        end

        get api('/circuit_breakers/repository_storage/failing', admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_kind_of(Array)
      end
    end
  end

  describe 'DELETE circuit_breakers/repository_storage' do
    it 'clears all circuit_breakers' do
      expect(Gitlab::Git::Storage::FailureInfo).to receive(:reset_all!)

      delete api('/circuit_breakers/repository_storage', admin)

      expect(response).to have_gitlab_http_status(204)
    end
  end
end
