# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Sessions do
  include_examples "redis_new_instance_shared_examples", 'sessions', Gitlab::Redis::SharedState

  describe 'redis instance used in connection pool' do
    before do
      clear_pool
    end

    context 'when redis.sessions configuration is not provided' do
      it 'uses ::Redis instance' do
        expect(described_class).to receive(:config_fallback?).and_return(true)

        described_class.pool.with do |redis_instance|
          expect(redis_instance).to be_instance_of(::Redis)
        end
      end
    end

    context 'when redis.sessions configuration is provided' do
      it 'instantiates an instance of MultiStore' do
        expect(described_class).to receive(:config_fallback?).and_return(false)

        described_class.pool.with do |redis_instance|
          expect(redis_instance).to be_instance_of(::Gitlab::Redis::MultiStore)
        end
      end
    end

    def clear_pool
      described_class.remove_instance_variable(:@pool)
    rescue NameError
      # raised if @pool was not set; ignore
    end
  end

  describe '#store' do
    subject { described_class.store(namespace: described_class::SESSION_NAMESPACE) }

    context 'when redis.sessions configuration is provided' do
      it 'instantiates ::Redis instance' do
        expect(described_class).to receive(:config_fallback?).and_return(true)
        expect(subject).to be_instance_of(::Redis::Store)
      end
    end

    context 'when redis.sessions configuration is not provided' do
      it 'instantiates an instance of MultiStore' do
        expect(described_class).to receive(:config_fallback?).and_return(false)
        expect(subject).to be_instance_of(::Gitlab::Redis::MultiStore)
      end
    end
  end
end
