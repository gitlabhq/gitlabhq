require 'spec_helper'

describe RedisCacheable do
  let(:runner) { build(:ci_runner) }

  describe '#cached_attribute' do
    subject { runner.cached_attribute(:anything) }

    it 'gets the cache attribute' do
      Gitlab::Redis::SharedState.with do |redis|
        expect(redis).to receive(:get).with(runner.send(:cache_attribute_key))
      end

      subject
    end
  end

  describe '#cache_attributes' do
    let(:values) { { name: 'new_name' } }

    subject { runner.cache_attributes(values) }

    it 'sets the cache attributes' do
      Gitlab::Redis::SharedState.with do |redis|
        values.each do |key, value|
          redis_key = runner.send(:cache_attribute_key)
          expect(redis).to receive(:set).with(redis_key, values.to_json, anything)
        end
      end

      subject
    end
  end
end
