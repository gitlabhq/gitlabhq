# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cache::JsonCaches::RedisKeyed, feature_category: :shared do
  let_it_be(:broadcast_message) { create(:broadcast_message) }

  let(:backend) { instance_double(ActiveSupport::Cache::RedisCacheStore).as_null_object }
  let(:namespace) { 'geo' }
  let(:key) { 'foo' }
  let(:cache_key_strategy) { :revision }
  let(:expanded_key) { "#{namespace}:#{key}:#{Gitlab.revision}" }

  subject(:cache) do
    described_class.new(namespace: namespace, backend: backend, cache_key_strategy: cache_key_strategy)
  end

  describe '#read' do
    context 'when the cached value is true' do
      it 'parses the cached value' do
        allow(backend).to receive(:read).with(expanded_key).and_return(true)

        expect(Gitlab::Json).to receive(:parse).with("true").and_call_original
        expect(cache.read(key, System::BroadcastMessage)).to eq(true)
      end
    end

    context 'when the cached value is false' do
      it 'parses the cached value' do
        allow(backend).to receive(:read).with(expanded_key).and_return(false)

        expect(Gitlab::Json).to receive(:parse).with("false").and_call_original
        expect(cache.read(key, System::BroadcastMessage)).to eq(false)
      end
    end
  end

  describe '#expire' do
    context 'with cache_key concerns' do
      using RSpec::Parameterized::TableSyntax

      where(:namespace, :cache_key_strategy, :expanded_key) do
        nil       | :revision | "#{key}:#{Gitlab.revision}"
        nil       | :version  | "#{key}:#{Gitlab::VERSION}:#{Rails.version}"
        namespace | :revision | "#{namespace}:#{key}:#{Gitlab.revision}"
        namespace | :version  | "#{namespace}:#{key}:#{Gitlab::VERSION}:#{Rails.version}"
      end

      with_them do
        specify do
          expect(backend).to receive(:delete).with(expanded_key)

          cache.expire(key)
        end
      end

      context 'when cache_key_strategy is unknown' do
        let(:cache_key_strategy) { 'unknown' }

        it 'raises KeyError' do
          expect { cache.expire(key) }.to raise_error(KeyError)
        end
      end
    end
  end

  it_behaves_like 'Json Cache class'

  def json_value(value)
    value.to_json
  end

  def version_json_value(value)
    value.to_json
  end
end
