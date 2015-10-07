require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }
  let(:key)   { create(:key, user: user) }
  let(:email)   { create(:email, user: user) }

  describe 'GET /keys/:uid' do
    before { admin }

    context 'when unauthenticated' do
      it 'should return authentication error' do
        get api("/keys/#{key.id}")
        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated' do
      it 'should return 404 for non-existing key' do
        get api('/keys/999999', admin)
        expect(response.status).to eq(404)
        expect(json_response['message']).to eq('404 Not found')
      end

      it 'should return single ssh key with user information' do
        user.keys << key
        user.save
        get api("/keys/#{key.id}", admin)
        expect(response.status).to eq(200)
        expect(json_response['title']).to eq(key.title)
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['username']).to eq(user.username)
      end
    end
  end
end
