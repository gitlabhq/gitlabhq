require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers

  let(:gl_license)  { build(:gitlab_license) }
  let(:license)     { build(:license, data: gl_license.export) }
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  describe 'GET /license' do
    it 'should retrieve the license information if admin is logged in' do
      get api('/license', admin)
      expect(response.status).to eq 200
      expect(json_response['user_limit']).to eq 0
      expect(Date.parse(json_response['starts_at'])).to eq Date.today - 1.month
      expect(Date.parse(json_response['expires_at'])).to eq Date.today + 11.months
      expect(json_response['active_users']).to eq 1
      expect(json_response['licensee']).to_not be_empty
    end

    it 'should deny access if not admin' do
      get api('/license', user)
      expect(response.status).to eq 403
    end
  end
end
