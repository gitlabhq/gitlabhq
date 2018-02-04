require 'spec_helper'

describe AttributeCacheable do
  let(:runner) { create(:ci_runner) }

  describe '#cached_attribute' do
    let(:key) { 'test_key' }

    subject { runner.cached_attribute(key) }

    it 'gets the cache attribute' do
      Gitlab::Redis::SharedState.with do |redis|
        expect(redis).to receive(:get).with(runner.send(:cache_attribute_key, key))
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
          expect(redis).to receive(:set).with(runner.send(:cache_attribute_key, key), value, anything)
        end
      end

      subject
    end
  end
end
