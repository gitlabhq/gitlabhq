# frozen_string_literal: true

RSpec.shared_examples 'shardable scopes' do
  let_it_be(:secondary_shard) { create(:shard, name: 'test_second_storage') }

  before do
    record_2.update!(shard: secondary_shard)
  end

  describe '.for_repository_storage' do
    it 'returns the objects for a given repository storage' do
      expect(described_class.for_repository_storage('default')).to eq([record_1])
    end
  end

  describe '.excluding_repository_storage' do
    it 'returns the objects excluding the given repository storage' do
      expect(described_class.excluding_repository_storage('default')).to eq([record_2])
    end
  end

  describe '.for_shard' do
    it 'returns the objects for a given shard' do
      expect(described_class.for_shard(record_1.shard)).to eq([record_1])
    end
  end
end
