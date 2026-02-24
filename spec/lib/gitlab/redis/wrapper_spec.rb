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

  describe '#params' do
    let(:wrapper) { described_class.new }

    context 'when Sentinel authentication is configured' do
      before do
        allow(wrapper).to receive(:redis_store_options).and_return(
          sentinels: [
            { host: '10.0.0.1', port: 26380 },
            { host: '10.0.0.2', port: 26380 }
          ],
          host: 'gitlab-redis',
          port: 6380,
          password: 'redis-password',
          sentinel_password: 'sentinel-password',
          sentinel_username: 'sentinel-user'
        )
      end

      it 'includes sentinel_password' do
        params = wrapper.params
        expect(params).to include(sentinel_password: 'sentinel-password')
      end

      it 'includes sentinel_username' do
        params = wrapper.params
        expect(params).to include(sentinel_username: 'sentinel-user')
      end

      it 'includes the name from host' do
        params = wrapper.params
        expect(params).to include(name: 'gitlab-redis')
      end

      it 'includes sentinels configuration' do
        params = wrapper.params
        expect(params[:sentinels]).to eq([
          { host: '10.0.0.1', port: 26380 },
          { host: '10.0.0.2', port: 26380 }
        ])
      end

      it 'excludes scheme, instrumentation_class, host, and port' do
        params = wrapper.params
        expect(params).not_to include(:scheme, :instrumentation_class, :host, :port)
      end
    end

    context 'when Sentinel authentication is not configured' do
      before do
        allow(wrapper).to receive(:redis_store_options).and_return(
          sentinels: [
            { host: '10.0.0.1', port: 26380 },
            { host: '10.0.0.2', port: 26380 }
          ],
          host: 'gitlab-redis',
          port: 6380,
          password: 'redis-password'
        )
      end

      it 'does not include sentinel_password' do
        params = wrapper.params
        expect(params).not_to include(:sentinel_password)
      end

      it 'does not include sentinel_username' do
        params = wrapper.params
        expect(params).not_to include(:sentinel_username)
      end

      it 'preserves sentinels configuration' do
        params = wrapper.params
        expect(params[:sentinels]).to eq([
          { host: '10.0.0.1', port: 26380 },
          { host: '10.0.0.2', port: 26380 }
        ])
      end
    end
  end
end
