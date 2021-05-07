# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Cache do
  describe '.initialize' do
    context 'when the cache is an array' do
      it 'instantiates an array of cache seeds' do
        cache_config = [{ key: 'key-a' }, { key: 'key-b' }]
        pipeline = double(::Ci::Pipeline)
        cache_seed_a = double(Gitlab::Ci::Pipeline::Seed::Build::Cache)
        cache_seed_b = double(Gitlab::Ci::Pipeline::Seed::Build::Cache)
        allow(Gitlab::Ci::Pipeline::Seed::Build::Cache).to receive(:new).and_return(cache_seed_a, cache_seed_b)

        cache = described_class.new(cache_config, pipeline)

        expect(Gitlab::Ci::Pipeline::Seed::Build::Cache).to have_received(:new).with(pipeline, { key: 'key-a' })
        expect(Gitlab::Ci::Pipeline::Seed::Build::Cache).to have_received(:new).with(pipeline, { key: 'key-b' })
        expect(cache.instance_variable_get(:@cache)).to eq([cache_seed_a, cache_seed_b])
      end
    end

    context 'when the cache is a hash' do
      it 'instantiates a cache seed' do
        cache_config = { key: 'key-a' }
        pipeline = double(::Ci::Pipeline)
        cache_seed = double(Gitlab::Ci::Pipeline::Seed::Build::Cache)
        allow(Gitlab::Ci::Pipeline::Seed::Build::Cache).to receive(:new).and_return(cache_seed)

        cache = described_class.new(cache_config, pipeline)

        expect(Gitlab::Ci::Pipeline::Seed::Build::Cache).to have_received(:new).with(pipeline, cache_config)
        expect(cache.instance_variable_get(:@cache)).to eq([cache_seed])
      end
    end
  end

  describe '#cache_attributes' do
    context 'when there are no caches' do
      it 'returns an empty hash' do
        cache_config = []
        pipeline = double(::Ci::Pipeline)
        cache = described_class.new(cache_config, pipeline)

        attributes = cache.cache_attributes

        expect(attributes).to eq({})
      end
    end

    context 'when there are caches' do
      it 'returns the structured attributes for the caches' do
        cache_config = [{ key: 'key-a' }, { key: 'key-b' }]
        pipeline = double(::Ci::Pipeline)
        cache = described_class.new(cache_config, pipeline)

        attributes = cache.cache_attributes

        expect(attributes).to eq({
          options: { cache: cache_config }
        })
      end
    end
  end
end
