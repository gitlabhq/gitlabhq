require 'spec_helper'

describe Gitlab::RedisConfig do
  let(:redis_config) { Rails.root.join('config', 'resque.yml') }

  describe '.params' do
    subject { described_class.params }

    context 'when url contains unix socket reference' do
      let(:config_old) { Rails.root.join('spec/fixtures/config/redis_old_format_socket.yml') }
      let(:config_new) { Rails.root.join('spec/fixtures/config/redis_new_format_socket.yml') }

      context 'with old format' do
        it 'returns path key instead' do
          allow(Gitlab::RedisConfig).to receive(:config_file) { config_old }

          is_expected.to include(path: '/path/to/redis.sock')
          is_expected.not_to have_key(:url)
        end
      end

      context 'with new format' do
        it 'returns path key instead' do
          allow(Gitlab::RedisConfig).to receive(:config_file) { config_new }

          is_expected.to include(path: '/path/to/redis.sock')
          is_expected.not_to have_key(:url)
        end
      end
    end

    context 'when url is host based' do
      let(:config_old) { Rails.root.join('spec/fixtures/config/redis_old_format_host.yml') }
      let(:config_new) { Rails.root.join('spec/fixtures/config/redis_new_format_host.yml') }

      context 'with old format' do
        it 'returns hash with host, port, db, and password' do
          allow(Gitlab::RedisConfig).to receive(:config_file) { config_old }

          is_expected.to include(host: 'localhost', password: 'mypassword', port: 6379, db: 99)
          is_expected.not_to have_key(:url)
        end
      end

      context 'with new format' do
        it 'returns hash with host, port, db, and password' do
          allow(Gitlab::RedisConfig).to receive(:config_file) { config_new }

          is_expected.to include(host: 'localhost', password: 'mypassword', port: 6379, db: 99)
          is_expected.not_to have_key(:url)
        end
      end
    end
  end

  describe '.raw_params' do
    subject { described_class.send(:raw_params) }

    it 'returns default redis url when no config file is present' do
      expect(Gitlab::RedisConfig).to receive(:fetch_config) { false }

      is_expected.to eq(url: Gitlab::RedisConfig::DEFAULT_REDIS_URL)
    end

    it 'returns old-style single url config in a hash' do
      expect(Gitlab::RedisConfig).to receive(:fetch_config) { 'redis://myredis:6379' }
      is_expected.to eq(url: 'redis://myredis:6379')
    end

  end

  describe '.fetch_config' do
    subject { described_class.send(:fetch_config) }

    it 'returns false when no config file is present' do
      allow(File).to receive(:exists?).with(redis_config) { false }

      is_expected.to be_falsey
    end
  end
end
