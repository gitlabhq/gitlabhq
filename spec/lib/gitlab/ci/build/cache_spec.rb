# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Cache do
  let(:cache_config) { [] }
  let(:pipeline) { double(::Ci::Pipeline) }
  let(:cache_seed_a) { double(Gitlab::Ci::Pipeline::Seed::Build::Cache) }
  let(:cache_seed_b) { double(Gitlab::Ci::Pipeline::Seed::Build::Cache) }

  subject(:cache) { described_class.new(cache_config, pipeline) }

  describe '.initialize' do
    context 'when the cache is an array' do
      let(:cache_config) { [{ key: 'key-a' }, { key: 'key-b' }] }

      it 'instantiates an array of cache seeds' do
        allow(Gitlab::Ci::Pipeline::Seed::Build::Cache).to receive(:new).and_return(cache_seed_a, cache_seed_b)

        cache

        expect(Gitlab::Ci::Pipeline::Seed::Build::Cache).to have_received(:new).with(pipeline, { key: 'key-a' }, 0)
        expect(Gitlab::Ci::Pipeline::Seed::Build::Cache).to have_received(:new).with(pipeline, { key: 'key-b' }, 1)
        expect(cache.instance_variable_get(:@cache)).to eq([cache_seed_a, cache_seed_b])
      end
    end

    context 'when the cache is a hash' do
      let(:cache_config) { { key: 'key-a' } }

      it 'instantiates a cache seed' do
        allow(Gitlab::Ci::Pipeline::Seed::Build::Cache).to receive(:new).and_return(cache_seed_a)

        cache

        expect(Gitlab::Ci::Pipeline::Seed::Build::Cache).to have_received(:new).with(pipeline, cache_config, 0)
        expect(cache.instance_variable_get(:@cache)).to eq([cache_seed_a])
      end
    end

    context 'when the cache is an array with files inside hashes' do
      let(:cache_config) { [{ key: { files: ['file1.json'] } }, { key: { files: ['file1.json', 'file2.json'] } }] }

      it 'instantiates a cache seed' do
        allow(Gitlab::Ci::Pipeline::Seed::Build::Cache).to receive(:new).and_return(cache_seed_a, cache_seed_b)

        cache

        expect(Gitlab::Ci::Pipeline::Seed::Build::Cache).to have_received(:new)
          .with(pipeline, cache_config.first, '0_file1')
        expect(Gitlab::Ci::Pipeline::Seed::Build::Cache).to have_received(:new)
          .with(pipeline, cache_config.second, '1_file1_file2')
        expect(cache.instance_variable_get(:@cache)).to match_array([cache_seed_a, cache_seed_b])
      end
    end
  end

  describe '#cache_attributes' do
    context 'when there are no caches' do
      it 'returns an empty hash' do
        attributes = cache.cache_attributes

        expect(attributes).to eq({})
      end
    end

    context 'when there are caches' do
      it 'returns the structured attributes for the caches' do
        cache_config = [{ key: 'key-a' }, { key: 'key-b' }]
        cache = described_class.new(cache_config, pipeline)

        attributes = cache.cache_attributes

        expect(attributes).to eq({
          options: { cache: cache_config }
        })
      end
    end
  end
end
