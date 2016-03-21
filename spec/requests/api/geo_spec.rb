require 'spec_helper'

describe API::API, api: true do
  include ApiHelpers
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

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

  describe 'POST /geo/refresh_key' do
    before(:each) { allow_any_instance_of(::Geo::ScheduleKeyChangeService).to receive(:execute) }

    it 'enqueues on disk key creation if admin and correct params' do
      post api('/geo/refresh_key', admin), key_change: { id: 1, action: 'create' }
      expect(response.status).to eq 201
    end

    it 'enqueues on disk key removal if admin and correct params' do
      post api('/geo/refresh_key', admin), key_change: { id: 1, action: 'delete' }
      expect(response.status).to eq 201
    end

    it 'denies access if not admin' do
      post api('/geo/refresh_key', user)
      expect(response.status).to eq 403
    end
  end
end
