require 'spec_helper'

describe CacheMethod, caching: true do
  class TestClassForCacheMethod
    include CacheMethod

    def id
      73
    end

    def time
      Time.now
    end

    cache_method :time
  end

  subject { TestClassForCacheMethod.new }

  let!(:time) { subject.time }

  describe 'cache_method' do
    it 'returns cached value' do
      expect(subject.time).to eq(time)
    end

    it 'sets instance variable' do
      expect(subject.send(:instance_variable_get, '@time')).to eq(time)
    end

    it 'sets value in the cache store' do
      another_instance = TestClassForCacheMethod.new

      expect(another_instance.time).to eq(time)
    end
  end

  describe 'expire_method_caches' do
    it 'expires cache and returns new value' do
      subject.expire_method_caches(%w(time))

      expect(subject.time).not_to eq(time)
    end
  end
end
