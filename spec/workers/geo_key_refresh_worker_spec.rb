require 'spec_helper'

describe GeoKeyRefreshWorker do
  subject(:key_create) { described_class.new.perform(key.id, key.key, 'key_create') }
  subject(:key_delete) { described_class.new.perform(key.id, key.key, 'key_destroy') }
  let(:key) { FactoryGirl.create(:key) }

  context 'key creation' do
    it 'adds key to shell' do
      expect(Key).to receive(:find).with(key.id) { key }
      expect(key).to receive(:add_to_shell)
      expect { key_create }.not_to raise_error
    end
  end

  context 'key removal' do
    it 'removes key from the shell' do
      expect(Key).to receive(:new).with(id: key.id, key: key.key) { key }
      expect(key).to receive(:remove_from_shell)
      expect { key_delete }.not_to raise_error
    end
  end
end
