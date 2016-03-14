require 'spec_helper'

describe API::API, api: true do
  include ApiHelpers
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  describe 'POST /geo/refresh_projects' do
    before(:each) { allow_any_instance_of(::Geo::ScheduleRepoUpdateService).to receive(:execute) }
    
    it 'should retrieve the license information if admin is logged in' do
      post api('/geo/refresh_projects', admin), projects: ['1', '2', '3']
      expect(response.status).to eq 201
    end

    it 'should deny access if not admin' do
      post api('/geo/refresh_projects', user)
      expect(response.status).to eq 403
    end
  end
end
