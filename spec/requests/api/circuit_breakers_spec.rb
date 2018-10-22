require 'spec_helper'

describe API::CircuitBreakers do
  set(:user) { create(:user) }
  set(:admin) { create(:admin) }

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
      get api('/circuit_breakers/repository_storage', admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_kind_of(Array)
      expect(json_response).to be_empty
    end

    describe 'GET circuit_breakers/repository_storage/failing' do
      it 'returns an array of failing storages' do
        get api('/circuit_breakers/repository_storage/failing', admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_kind_of(Array)
        expect(json_response).to be_empty
      end
    end
  end

  describe 'DELETE circuit_breakers/repository_storage' do
    it 'clears all circuit_breakers' do
      delete api('/circuit_breakers/repository_storage', admin)

      expect(response).to have_gitlab_http_status(204)
    end
  end
end
