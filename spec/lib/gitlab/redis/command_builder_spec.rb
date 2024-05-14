# frozen_string_literal: true

require 'spec_helper'

# references specs in https://github.com/redis-rb/redis-client/blob/master/test/redis_client/command_builder_test.rb
# we add `handles nil arguments` to test our own added logic
RSpec.describe Gitlab::Redis::CommandBuilder, feature_category: :redis do
  describe '.generate' do
    def call(*args, **kwargs)
      described_class.generate(args, kwargs)
    end

    context 'when nil arguments are found' do
      context 'when in production' do
        before do
          stub_rails_env('production')
        end

        it 'handles nil arguments' do
          expect(call("a", nil)).to eq(["a", ""])
        end
      end

      context 'when in test' do
        before do
          stub_rails_env('test')
        end

        it 'raises exception when nil argument is passed' do
          expect { call("a", nil) }.to raise_error(described_class::RedisCommandNilArgumentError)
        end
      end

      context 'when in development' do
        before do
          stub_rails_env('development')
        end

        it 'raises exception when nil argument is passed' do
          expect { call("a", nil) }.to raise_error(described_class::RedisCommandNilArgumentError)
        end
      end
    end

    it 'handles positional arguments' do
      expect(call("a", "b", "c")).to eq(%w[a b c])
    end

    it 'handles arrays' do
      expect(call("a", %w[b c])).to eq(%w[a b c])
    end

    it 'handles hashes' do
      expect(call("a", { "b" => "c" })).to eq(%w[a b c])
    end

    it 'handles symbols' do
      expect(call(:a, { b: :c }, :d)).to eq(%w[a b c d])
    end

    it 'handles numerics' do
      expect(call(1, 2.3)).to eq(["1", "2.3"])
    end

    it 'handles kwargs booleans' do
      expect(call(ttl: nil, ex: false, withscores: true)).to eq(["withscores"])
    end

    it 'handles kwargs values' do
      expect(call(ttl: 42)).to eq(%w[ttl 42])
    end

    it 'raises error on unsupported types' do
      expect { call(hash: {}) }.to raise_error(TypeError)
    end

    it 'raises error on empty commands' do
      expect { call }.to raise_error(ArgumentError)
    end
  end
end
