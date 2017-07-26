require 'spec_helper'

describe Geo::ScheduleKeyChangeService do
  subject(:key_create) { described_class.new('id' => 1, 'key' => key.key, 'action' => :create) }
  subject(:key_delete) { described_class.new('id' => 1, 'key' => key.key, 'action' => :delete) }
  let(:key) { FactoryGirl.build(:key) }

  before do
    allow_any_instance_of(GeoKeyRefreshWorker).to receive(:perform)
  end

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
