# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Redis::Wrapper do
  describe '.instrumentation_class' do
    it 'raises a NameError' do
      expect { described_class.instrumentation_class }.to raise_error(NameError)
    end
  end

  describe '#ssl_params' do
    let(:wrapper) { described_class.new }

    context 'when ssl_params are present in the config' do
      let(:ssl_params) do
        {
          ca_file: '/etc/gitlab/ssl/redis-bundle.crt',
          cert: '/etc/gitlab/ssl/redis-client.crt',
          key: '/etc/gitlab/ssl/redis-client.key'
        }
      end

      before do
        allow(wrapper).to receive(:raw_config_hash).and_return(
          url: 'rediss://localhost:6379',
          ssl_params: ssl_params
        )
      end

      it 'returns the ssl_params from the config' do
        expect(wrapper.ssl_params).to eq(ssl_params)
      end
    end

    context 'when ssl_params are not present in the config' do
      before do
        allow(wrapper).to receive(:raw_config_hash).and_return(
          url: 'redis://localhost:6379'
        )
      end

      it 'returns nil' do
        expect(wrapper.ssl_params).to be_nil
      end
    end
  end

  describe '.active?' do
    it 'returns true by default' do
      expect(described_class.active?).to be true
    end
  end
end
