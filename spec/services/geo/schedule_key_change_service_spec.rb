require 'spec_helper'

describe Geo::ScheduleKeyChangeService, service: true do
  subject(:key_create) { Geo::ScheduleKeyChangeService.new(1, :create) }
  subject(:key_delete) { Geo::ScheduleKeyChangeService.new(1, :delete) }

  before(:each) { allow_any_instance_of(GeoKeyRefreshWorker).to receive(:perform) }

  context 'key creation' do
    it 'executes action' do
      expect(key_create.execute).to be_truthy
    end
  end

  context 'key removal' do
    it 'executes action' do
      expect(key_delete.execute).to be_truthy
    end
  end
end
