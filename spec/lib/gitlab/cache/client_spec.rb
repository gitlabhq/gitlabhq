# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cache::Client, feature_category: :source_code_management do
  subject(:client) { described_class.new(metadata, backend: backend) }

  let(:backend) { Rails.cache }
  let(:metadata) do
    Gitlab::Cache::Metadata.new(
      cache_identifier: cache_identifier,
      feature_category: feature_category,
      backing_resource: backing_resource
    )
  end

  let(:cache_identifier) { 'MyClass#cache' }
  let(:feature_category) { :source_code_management }
  let(:backing_resource) { :cpu }

  let(:metadata_mock) do
    Gitlab::Cache::Metadata.new(
      cache_identifier: cache_identifier,
      feature_category: feature_category
    )
  end

  let(:metrics_mock) { Gitlab::Cache::Metrics.new(metadata_mock) }

  describe '.build_with_metadata' do
    it 'builds a cache client with metrics support' do
      attributes = {
        cache_identifier: cache_identifier,
        feature_category: feature_category,
        backing_resource: backing_resource
      }

      instance = described_class.build_with_metadata(**attributes)

      expect(instance).to be_a(described_class)
      expect(instance.metadata).to have_attributes(**attributes)
    end
  end

  describe 'Methods', :use_clean_rails_memory_store_caching do
    let(:expected_key) { 'key' }

    before do
      allow(Gitlab::Cache::Metrics).to receive(:new).and_return(metrics_mock)
    end

    describe '#read' do
      context 'when key does not exist' do
        it 'returns nil' do
          expect(client.read('key')).to be_nil
        end

        it 'increments cache miss' do
          expect(metrics_mock).to receive(:increment_cache_miss)

          client.read('key')
        end
      end

      context 'when key exists' do
        before do
          backend.write(expected_key, 'value')
        end

        it 'returns key value' do
          expect(client.read('key')).to eq('value')
        end

        it 'increments cache hit' do
          expect(metrics_mock).to receive(:increment_cache_hit)

          client.read('key')
        end
      end
    end

    describe '#write' do
      it 'calls backend "#write" method with the expected key' do
        expect(backend).to receive(:write).with(expected_key, 'value')

        client.write('key', 'value')
      end
    end

    describe '#exist?' do
      it 'calls backend "#exist?" method with the expected key' do
        expect(backend).to receive(:exist?).with(expected_key)

        client.exist?('key')
      end
    end

    describe '#delete' do
      it 'calls backend "#delete" method with the expected key' do
        expect(backend).to receive(:delete).with(expected_key)

        client.delete('key')
      end
    end

    # rubocop:disable Style/RedundantFetchBlock
    describe '#fetch' do
      it 'creates key in the specific format' do
        client.fetch('key') { 'value' }

        expect(backend.fetch(expected_key)).to eq('value')
      end

      it 'yields the block once' do
        expect { |b| client.fetch('key', &b) }.to yield_control.once
      end

      context 'when key already exists' do
        before do
          backend.write(expected_key, 'value')
        end

        it 'does not redefine the value' do
          expect(client.fetch('key') { 'new-value' }).to eq('value')
        end

        it 'increments a cache hit' do
          expect(metrics_mock).to receive(:increment_cache_hit)

          client.fetch('key')
        end

        it 'does not measure the cache generation time' do
          expect(metrics_mock).not_to receive(:observe_cache_generation)

          client.fetch('key') { 'new-value' }
        end
      end

      context 'when key does not exist' do
        it 'caches the key' do
          expect(client.fetch('key') { 'value' }).to eq('value')

          expect(client.fetch('key')).to eq('value')
        end

        it 'increments a cache miss' do
          expect(metrics_mock).to receive(:increment_cache_miss)

          client.fetch('key')
        end

        it 'measures the cache generation time' do
          expect(metrics_mock).to receive(:observe_cache_generation)

          client.fetch('key') { 'value' }
        end
      end
    end
  end
  # rubocop:enable Style/RedundantFetchBlock
end
