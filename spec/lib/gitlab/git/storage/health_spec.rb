require 'spec_helper'

describe Gitlab::Git::Storage::Health, broken_storage: true do
  let(:host1_key) { 'storage_accessible:broken:web01' }
  let(:host2_key) { 'storage_accessible:default:kiq01' }

  def set_in_redis(cache_key, value)
    Gitlab::Git::Storage.redis.with do |redis|
      redis.zadd(Gitlab::Git::Storage::REDIS_KNOWN_KEYS, 0, cache_key)
      redis.hmset(cache_key, :failure_count, value)
    end.first
  end

  describe '.for_failing_storages' do
    it 'only includes health status for failures' do
      set_in_redis(host1_key, 10)
      set_in_redis(host2_key, 0)

      expect(described_class.for_failing_storages.map(&:storage_name))
        .to contain_exactly('broken')
    end
  end

  describe '.for_all_storages' do
    it 'loads health status for all configured storages' do
      healths = described_class.for_all_storages

      expect(healths.map(&:storage_name)).to contain_exactly('default', 'broken')
    end
  end

  describe '#failing_info' do
    it 'only contains storages that have failures' do
      health = described_class.new('broken', [{ name: host1_key, failure_count: 0 },
                                              { name: host2_key, failure_count: 3 }])

      expect(health.failing_info).to contain_exactly({ name: host2_key, failure_count: 3 })
    end
  end

  describe '#total_failures' do
    it 'sums up all the failures' do
      health = described_class.new('broken', [{ name: host1_key, failure_count: 2 },
                                              { name: host2_key, failure_count: 3 }])

      expect(health.total_failures).to eq(5)
    end
  end

  describe '#failing_on_hosts' do
    it 'collects only the failing hostnames' do
      health = described_class.new('broken', [{ name: host1_key, failure_count: 2 },
                                              { name: host2_key, failure_count: 0 }])

      expect(health.failing_on_hosts).to contain_exactly('web01')
    end
  end
end
