require 'spec_helper'

describe API::V3::Groups, api: true  do
  include ApiHelpers
  include UploadHelpers

  let(:user2) { create(:user) }
  let!(:group2) { create(:group, :private) }
  let!(:project2) { create(:empty_project, namespace: group2) }

  before do
    group2.add_owner(user2)
  end

  describe 'GET /groups/owned' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get v3_api('/groups/owned')

        expect(response).to have_http_status(401)
      end
    end

    context 'when authenticated as group owner' do
      it 'returns an array of groups the user owns' do
        get v3_api('/groups/owned', user2)

        expect(response).to have_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq(group2.name)
      end
    end
  end
end
